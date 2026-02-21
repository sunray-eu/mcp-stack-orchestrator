#!/usr/bin/env python3
"""
Bridge framed MCP stdio <-> newline-delimited JSON-RPC stdio.

Use this when an MCP server speaks line-delimited JSON on stdio
but the client expects framed Content-Length transport.
"""

from __future__ import annotations

import argparse
import os
import signal
import subprocess
import sys
import threading
from typing import BinaryIO


def _read_framed_message(stream: BinaryIO) -> bytes | None:
    headers: dict[str, str] = {}

    while True:
        line = stream.readline()
        if line == b"":
            return None
        if line in (b"\n", b"\r\n"):
            break
        decoded = line.decode("utf-8", errors="replace").strip()
        if not decoded:
            break
        if ":" in decoded:
            key, value = decoded.split(":", 1)
            headers[key.strip().lower()] = value.strip()

    content_length = headers.get("content-length")
    if content_length is None:
        return None

    try:
        length = int(content_length)
    except ValueError:
        return None

    payload = stream.read(length)
    if len(payload) != length:
        return None
    return payload


def _write_framed_message(stream: BinaryIO, payload: bytes) -> None:
    header = f"Content-Length: {len(payload)}\r\n\r\n".encode("ascii")
    stream.write(header)
    stream.write(payload)
    stream.flush()


def _framed_to_lines(child: subprocess.Popen[bytes]) -> None:
    while True:
        payload = _read_framed_message(sys.stdin.buffer)
        if payload is None:
            try:
                child.stdin.close()  # type: ignore[union-attr]
            except Exception:
                pass
            return

        try:
            child.stdin.write(payload + b"\n")  # type: ignore[union-attr]
            child.stdin.flush()  # type: ignore[union-attr]
        except Exception:
            return


def _lines_to_framed(child: subprocess.Popen[bytes]) -> None:
    while True:
        line = child.stdout.readline()  # type: ignore[union-attr]
        if line == b"":
            return
        payload = line.strip()
        if not payload:
            continue
        _write_framed_message(sys.stdout.buffer, payload)


def _stderr_passthrough(child: subprocess.Popen[bytes]) -> None:
    while True:
        chunk = child.stderr.read(4096)  # type: ignore[union-attr]
        if not chunk:
            return
        sys.stderr.buffer.write(chunk)
        sys.stderr.buffer.flush()


def main() -> int:
    parser = argparse.ArgumentParser(description="Bridge framed stdio MCP to line-jsonrpc MCP")
    parser.add_argument("command", nargs=argparse.REMAINDER, help="Command to execute")
    args = parser.parse_args()

    if not args.command:
        print("No server command provided", file=sys.stderr)
        return 2

    if args.command[0] == "--":
        args.command = args.command[1:]
    if not args.command:
        print("No server command provided after --", file=sys.stderr)
        return 2

    child = subprocess.Popen(
        args.command,
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        bufsize=0,
        env=os.environ.copy(),
    )

    def _terminate(*_args: object) -> None:
        try:
            child.terminate()
        except Exception:
            pass

    signal.signal(signal.SIGINT, _terminate)
    signal.signal(signal.SIGTERM, _terminate)

    t_in = threading.Thread(target=_framed_to_lines, args=(child,), daemon=True)
    t_out = threading.Thread(target=_lines_to_framed, args=(child,), daemon=True)
    t_err = threading.Thread(target=_stderr_passthrough, args=(child,), daemon=True)

    t_in.start()
    t_out.start()
    t_err.start()

    code = child.wait()
    t_in.join(timeout=1)
    t_out.join(timeout=1)
    t_err.join(timeout=1)
    return code


if __name__ == "__main__":
    raise SystemExit(main())
