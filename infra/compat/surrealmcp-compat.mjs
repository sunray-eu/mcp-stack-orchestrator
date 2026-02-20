import http from "node:http";
import { URL } from "node:url";

const UPSTREAM_HOST = process.env.SURREALMCP_UPSTREAM_HOST || "surrealmcp";
const UPSTREAM_PORT = Number(process.env.SURREALMCP_UPSTREAM_PORT || "8080");
const PORT = Number(process.env.PORT || "8080");

const AUTH_SERVER_METADATA = JSON.stringify({
  issuer: "https://auth.surrealdb.com",
  token_endpoint: "https://auth.surrealdb.com/oauth/token",
  jwks_uri: "https://auth.surrealdb.com/.well-known/jwks.json",
});

const AUTH_SERVER_PATHS = new Set([
  "/.well-known/oauth-authorization-server",
  "/.well-known/oauth-authorization-server/mcp",
  "/mcp/.well-known/oauth-authorization-server",
]);

// Maps client-side session ids to upstream session ids so stale local session ids
// can be transparently recovered after MCP server restarts.
const SESSION_MAP = new Map();

function inferContentType(req, statusCode, body) {
  if (req.url?.startsWith("/mcp") && req.method === "GET") {
    return "text/event-stream";
  }
  if (req.url?.startsWith("/mcp") && req.method === "POST" && statusCode === 202) {
    return "application/json";
  }
  if (body?.length) {
    const preview = body.toString("utf8", 0, Math.min(body.length, 256)).trimStart();
    if (preview.startsWith("data:")) {
      return "text/event-stream";
    }
    if (preview.startsWith("{") || preview.startsWith("[")) {
      return "application/json";
    }
    return "text/plain; charset=utf-8";
  }
  return "application/json";
}

function writeJson(res, code, body) {
  res.writeHead(code, {
    "content-type": "application/json",
    "cache-control": "no-store",
  });
  res.end(body);
}

function readRequestBody(req) {
  return new Promise((resolve, reject) => {
    const chunks = [];
    req.on("data", (chunk) => chunks.push(chunk));
    req.on("end", () => resolve(Buffer.concat(chunks)));
    req.on("error", reject);
  });
}

function ensureAcceptHeader(value) {
  const input = Array.isArray(value) ? value.join(", ") : typeof value === "string" ? value : "";
  const normalized = input.toLowerCase();
  if (normalized.includes("application/json") && normalized.includes("text/event-stream")) {
    return input;
  }
  return "application/json, text/event-stream";
}

function buildUpstreamHeaders(req, mappedUpstreamSession, forceNoSession) {
  const headers = {
    ...req.headers,
    host: `${UPSTREAM_HOST}:${UPSTREAM_PORT}`,
    accept: ensureAcceptHeader(req.headers.accept),
  };

  const clientSessionId = req.headers["mcp-session-id"];
  const hasClientSession = typeof clientSessionId === "string" && clientSessionId.length > 0;

  if (forceNoSession) {
    delete headers["mcp-session-id"];
  } else if (hasClientSession) {
    if (mappedUpstreamSession) {
      headers["mcp-session-id"] = mappedUpstreamSession;
    } else {
      delete headers["mcp-session-id"];
    }
  }

  return headers;
}

function sendUpstream(req, path, headers, body) {
  return new Promise((resolve, reject) => {
    const upstreamReq = http.request(
      {
        hostname: UPSTREAM_HOST,
        port: UPSTREAM_PORT,
        method: req.method,
        path,
        headers,
      },
      (upstreamRes) => {
        const chunks = [];
        upstreamRes.on("data", (chunk) => chunks.push(chunk));
        upstreamRes.on("end", () => {
          resolve({
            statusCode: upstreamRes.statusCode ?? 500,
            headers: { ...upstreamRes.headers },
            body: Buffer.concat(chunks),
          });
        });
      },
    );

    upstreamReq.on("error", reject);

    if (body?.length) {
      upstreamReq.write(body);
    }
    upstreamReq.end();
  });
}

function parseJsonBody(buffer) {
  if (!buffer?.length) {
    return null;
  }
  try {
    return JSON.parse(buffer.toString("utf8"));
  } catch {
    return null;
  }
}

function parseEventStreamJson(buffer) {
  if (!buffer?.length) {
    return null;
  }
  const text = buffer.toString("utf8");
  const dataLine = text
    .split("\n")
    .map((line) => line.trim())
    .find((line) => line.startsWith("data:"));
  if (!dataLine) {
    return null;
  }
  const json = dataLine.slice(5).trim();
  try {
    return JSON.parse(json);
  } catch {
    return null;
  }
}

function responseNeedsBootstrap(response) {
  if (!response?.body) {
    return false;
  }
  const bodyText = response.body.toString("utf8").toLowerCase();
  if (response.statusCode === 422 && bodyText.includes("expect initialize request")) {
    return true;
  }
  if (response.statusCode === 401 && bodyText.includes("session not found")) {
    return true;
  }
  return false;
}

async function bootstrapSession(req, path, originalRequestBody) {
  const bodyJson = parseJsonBody(originalRequestBody);
  const protocolVersion = bodyJson?.params?.protocolVersion ?? "2025-03-26";

  const initializeBody = Buffer.from(
    JSON.stringify({
      jsonrpc: "2.0",
      id: "compat-bootstrap-init",
      method: "initialize",
      params: {
        protocolVersion,
        capabilities: {},
        clientInfo: {
          name: "surrealmcp-compat",
          version: "1.0.0",
        },
      },
    }),
    "utf8",
  );

  const initHeaders = {
    ...buildUpstreamHeaders(req, undefined, true),
    "content-type": "application/json",
    "content-length": String(initializeBody.length),
  };

  const initResponse = await sendUpstream(req, path, initHeaders, initializeBody);
  const initPayload = parseEventStreamJson(initResponse.body);
  const initError = initPayload?.error;
  const upstreamSessionId = initResponse.headers["mcp-session-id"];
  if (
    initResponse.statusCode >= 400 ||
    initError ||
    typeof upstreamSessionId !== "string" ||
    upstreamSessionId.length === 0
  ) {
    return { ok: false, reason: "initialize_failed", initResponse };
  }

  const initializedBody = Buffer.from(
    JSON.stringify({
      jsonrpc: "2.0",
      method: "notifications/initialized",
    }),
    "utf8",
  );

  const initializedHeaders = {
    ...buildUpstreamHeaders(req, upstreamSessionId, false),
    "content-type": "application/json",
    "content-length": String(initializedBody.length),
  };

  const initializedResponse = await sendUpstream(req, path, initializedHeaders, initializedBody);
  if (initializedResponse.statusCode >= 400) {
    return { ok: false, reason: "notifications_initialized_failed", initializedResponse };
  }

  return { ok: true, upstreamSessionId };
}

function sendResponse(res, req, response, clientSessionId, hasClientSession) {
  const headers = { ...response.headers };
  const upstreamSessionId = headers["mcp-session-id"];
  if (typeof upstreamSessionId === "string" && upstreamSessionId.length > 0) {
    if (hasClientSession) {
      SESSION_MAP.set(clientSessionId, upstreamSessionId);
      headers["mcp-session-id"] = clientSessionId;
    } else {
      SESSION_MAP.set(upstreamSessionId, upstreamSessionId);
    }
  }

  const hasContentType =
    typeof headers["content-type"] === "string" && headers["content-type"].length > 0;
  if (!hasContentType) {
    headers["content-type"] = inferContentType(req, response.statusCode, response.body);
  }

  headers["content-length"] = String(response.body.length);
  delete headers["transfer-encoding"];

  res.writeHead(response.statusCode, headers);
  res.end(response.body);
}

async function handleRequest(req, res) {
  const url = new URL(req.url ?? "/", "http://compat.local");
  if (AUTH_SERVER_PATHS.has(url.pathname)) {
    writeJson(res, 200, AUTH_SERVER_METADATA);
    return;
  }

  if (req.method === "GET") {
    // Keep SSE streaming behavior for streamable GET requests.
    const upstreamReq = http.request(
      {
        hostname: UPSTREAM_HOST,
        port: UPSTREAM_PORT,
        method: req.method,
        path: `${url.pathname}${url.search}`,
        headers: buildUpstreamHeaders(req, undefined, false),
      },
      (upstreamRes) => {
        const headers = { ...upstreamRes.headers };
        const hasContentType =
          typeof headers["content-type"] === "string" && headers["content-type"].length > 0;
        if (!hasContentType) {
          headers["content-type"] = inferContentType(req, upstreamRes.statusCode ?? 500);
        }
        res.writeHead(upstreamRes.statusCode ?? 500, headers);
        upstreamRes.pipe(res);
      },
    );

    upstreamReq.on("error", (err) => {
      writeJson(res, 502, JSON.stringify({ error: "bad_gateway", message: err.message }));
    });

    req.pipe(upstreamReq);
    return;
  }

  const requestBody = await readRequestBody(req);
  const clientSessionId = req.headers["mcp-session-id"];
  const hasClientSession = typeof clientSessionId === "string" && clientSessionId.length > 0;
  const mappedUpstreamSession = hasClientSession ? SESSION_MAP.get(clientSessionId) : undefined;
  const requestTag = `${req.method ?? "?"} ${url.pathname}`;

  console.error(
    `[compat] in ${requestTag} client_sid=${hasClientSession ? clientSessionId : "-"} mapped_sid=${mappedUpstreamSession ?? "-"}`,
  );

  const path = `${url.pathname}${url.search}`;
  let response = await sendUpstream(
    req,
    path,
    buildUpstreamHeaders(req, mappedUpstreamSession, false),
    requestBody,
  );

  if (hasClientSession && !mappedUpstreamSession && responseNeedsBootstrap(response)) {
    console.error(`[compat] bootstrap ${requestTag} client_sid=${clientSessionId}`);
    const bootstrap = await bootstrapSession(req, path, requestBody);
    if (bootstrap.ok) {
      SESSION_MAP.set(clientSessionId, bootstrap.upstreamSessionId);
      response = await sendUpstream(
        req,
        path,
        buildUpstreamHeaders(req, bootstrap.upstreamSessionId, false),
        requestBody,
      );
    } else {
      console.error(`[compat] bootstrap_failed ${requestTag} reason=${bootstrap.reason}`);
    }
  }

  const responseSessionId = response.headers["mcp-session-id"];
  console.error(
    `[compat] out ${requestTag} status=${response.statusCode} upstream_sid=${typeof responseSessionId === "string" ? responseSessionId : "-"} response_sid=${hasClientSession ? clientSessionId : typeof responseSessionId === "string" ? responseSessionId : "-"}`,
  );
  sendResponse(res, req, response, clientSessionId, hasClientSession);

  if (req.method === "DELETE" && hasClientSession) {
    SESSION_MAP.delete(clientSessionId);
  }
}

const server = http.createServer((req, res) => {
  handleRequest(req, res).catch((err) => {
    writeJson(res, 500, JSON.stringify({ error: "internal_error", message: err.message }));
  });
});

server.listen(PORT, "0.0.0.0", () => {
  console.log(`surrealmcp-compat listening on :${PORT}, upstream=${UPSTREAM_HOST}:${UPSTREAM_PORT}`);
});
