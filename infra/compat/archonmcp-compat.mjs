import http from "node:http";

const UPSTREAM_HOST = process.env.ARCHON_MCP_UPSTREAM_HOST || "archon-mcp";
const UPSTREAM_PORT = Number(process.env.ARCHON_MCP_UPSTREAM_PORT || "18052");
const PORT = Number(process.env.PORT || "8080");

function ensureAcceptHeader(value) {
  const input = Array.isArray(value) ? value.join(", ") : typeof value === "string" ? value : "";
  const normalized = input.toLowerCase();
  if (normalized.includes("application/json") && normalized.includes("text/event-stream")) {
    return input;
  }
  return "application/json, text/event-stream";
}

function inferContentType(body) {
  if (!body?.length) {
    return "application/json";
  }
  const preview = body.toString("utf8", 0, Math.min(body.length, 128)).trimStart();
  if (preview.startsWith("{") || preview.startsWith("[")) {
    return "application/json";
  }
  if (preview.startsWith("data:")) {
    return "text/event-stream";
  }
  return "text/plain; charset=utf-8";
}

function readRequestBody(req) {
  return new Promise((resolve, reject) => {
    const chunks = [];
    req.on("data", (chunk) => chunks.push(chunk));
    req.on("end", () => resolve(Buffer.concat(chunks)));
    req.on("error", reject);
  });
}

function parseJsonBody(body) {
  if (!body?.length) {
    return null;
  }
  try {
    return JSON.parse(body.toString("utf8"));
  } catch {
    return null;
  }
}

function sendUpstream(req, headers, body) {
  return new Promise((resolve, reject) => {
    const upstreamReq = http.request(
      {
        hostname: UPSTREAM_HOST,
        port: UPSTREAM_PORT,
        method: req.method,
        path: req.url ?? "/",
        headers,
      },
      (upstreamRes) => {
        const chunks = [];
        upstreamRes.on("data", (chunk) => chunks.push(chunk));
        upstreamRes.on("end", () =>
          resolve({
            statusCode: upstreamRes.statusCode ?? 500,
            headers: { ...upstreamRes.headers },
            body: Buffer.concat(chunks),
          }),
        );
      },
    );
    upstreamReq.on("error", reject);
    if (body.length > 0) {
      upstreamReq.write(body);
    }
    upstreamReq.end();
  });
}

async function bootstrapSession(req, headers) {
  const initPayload = Buffer.from(
    JSON.stringify({
      jsonrpc: "2.0",
      id: "archon-compat-bootstrap",
      method: "initialize",
      params: {
        protocolVersion: "2025-06-18",
        capabilities: {},
        clientInfo: {
          name: "archonmcp-compat",
          version: "1.0.0",
        },
      },
    }),
    "utf8",
  );
  const initHeaders = {
    ...headers,
    "content-type": "application/json",
    accept: "application/json, text/event-stream",
    "content-length": String(initPayload.length),
  };
  delete initHeaders["mcp-session-id"];

  const initRes = await sendUpstream(req, initHeaders, initPayload);
  const sessionId = initRes.headers["mcp-session-id"];
  if (typeof sessionId !== "string" || !sessionId) {
    return null;
  }

  const initializedPayload = Buffer.from(
    JSON.stringify({
      jsonrpc: "2.0",
      method: "notifications/initialized",
    }),
    "utf8",
  );
  const initializedHeaders = {
    ...headers,
    "content-type": "application/json",
    accept: "application/json, text/event-stream",
    "content-length": String(initializedPayload.length),
    "mcp-session-id": sessionId,
  };
  await sendUpstream(req, initializedHeaders, initializedPayload);
  return sessionId;
}

function buildHeaders(req, body) {
  const headers = {
    ...req.headers,
    host: `${UPSTREAM_HOST}:${UPSTREAM_PORT}`,
  };
  const path = req.url ?? "/";
  if (path.startsWith("/mcp")) {
    headers.accept = ensureAcceptHeader(req.headers.accept);
    if (req.method === "POST") {
      const contentType = req.headers["content-type"];
      if (!contentType || String(contentType).trim().length === 0) {
        headers["content-type"] = "application/json";
      }
    }
  }
  headers["content-length"] = String(body.length);
  return headers;
}

async function handleRequest(req, res) {
  try {
    const body = await readRequestBody(req);
    const headers = buildHeaders(req, body);
    const parsedBody = parseJsonBody(body);
    const bodyPreview = body.toString("utf8", 0, Math.min(body.length, 240)).replace(/\s+/g, " ");
    console.log(
      `[archon-compat] in ${req.method} ${req.url ?? "/"} sid=${String(req.headers["mcp-session-id"] || "-")} content-type=${String(headers["content-type"] || "-")} accept=${String(headers.accept || "-")} body=${body.length} preview=${bodyPreview}`,
    );
    const noSessionHeader =
      typeof req.headers["mcp-session-id"] !== "string" || req.headers["mcp-session-id"].length === 0;
    const isMcpPost = (req.url ?? "/").startsWith("/mcp") && req.method === "POST";
    if (isMcpPost && noSessionHeader && parsedBody?.method && parsedBody.method !== "initialize") {
      const sessionId = await bootstrapSession(req, headers);
      if (sessionId) {
        headers["mcp-session-id"] = sessionId;
        console.log(`[archon-compat] bootstrap session=${sessionId}`);
      }
    }

    let upstream = await sendUpstream(req, headers, body);
    const shouldBootstrapRetry =
      isMcpPost && upstream.statusCode >= 400 && parsedBody?.method !== "initialize";
    if (shouldBootstrapRetry) {
      const sessionId = await bootstrapSession(req, headers);
      if (sessionId) {
        const retryHeaders = {
          ...headers,
          "mcp-session-id": sessionId,
          "content-length": String(body.length),
        };
        upstream = await sendUpstream(req, retryHeaders, body);
        console.log(
          `[archon-compat] retry ${req.method} ${req.url ?? "/"} session=${sessionId} status=${upstream.statusCode}`,
        );
      }
    }

    const outHeaders = { ...upstream.headers };
    const upstreamContentType = String(outHeaders["content-type"] || "");
    const shouldRewriteMcpError =
      (req.url ?? "/").startsWith("/mcp") &&
      upstream.statusCode >= 400 &&
      !upstreamContentType.includes("application/json") &&
      !upstreamContentType.includes("text/event-stream");
    if (shouldRewriteMcpError) {
      const message = upstream.body.toString("utf8").trim() || "Upstream MCP error";
      const wrapped = Buffer.from(
        JSON.stringify({
          jsonrpc: "2.0",
          id: "archonmcp-compat",
          error: {
            code: -32600,
            message,
          },
        }),
        "utf8",
      );
      outHeaders["content-type"] = "application/json";
      outHeaders["content-length"] = String(wrapped.length);
      delete outHeaders["transfer-encoding"];
      res.writeHead(upstream.statusCode, outHeaders);
      res.end(wrapped);
      console.log(
        `[archon-compat] out ${req.method} ${req.url ?? "/"} status=${upstream.statusCode} rewritten=true`,
      );
      return;
    }

    if (!outHeaders["content-type"]) {
      outHeaders["content-type"] = inferContentType(upstream.body);
    }
    outHeaders["content-length"] = String(upstream.body.length);
    delete outHeaders["transfer-encoding"];

    res.writeHead(upstream.statusCode, outHeaders);
    res.end(upstream.body);
    console.log(
      `[archon-compat] out ${req.method} ${req.url ?? "/"} status=${upstream.statusCode} content-type=${String(outHeaders["content-type"] || "-")}`,
    );
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    const body = JSON.stringify({ error: "archon_compat_upstream_error", message });
    res.writeHead(502, {
      "content-type": "application/json",
      "content-length": String(Buffer.byteLength(body)),
    });
    res.end(body);
  }
}

http.createServer(handleRequest).listen(PORT, "0.0.0.0", () => {
  console.log(
    `archonmcp-compat listening on :${PORT}, upstream=${UPSTREAM_HOST}:${UPSTREAM_PORT}`,
  );
});
