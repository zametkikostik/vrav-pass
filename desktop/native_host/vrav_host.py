#!/usr/bin/env python3
"""Vrav Pass Native Messaging host (prototype).

Protocol: Chrome Native Messaging (4-byte LE length + JSON UTF-8).

Messages from extension:
  {"type": "ping"}
  {"type": "getStatus"}
  {"type": "findForUrl", "url": "https://..."}

This prototype does NOT unlock the Flutter vault yet — it answers ping/status.
Next step: connect to a local Flutter desktop process or encrypted DB path.
"""
from __future__ import annotations

import json
import struct
import sys


def read_message() -> dict | None:
    raw_len = sys.stdin.buffer.read(4)
    if not raw_len or len(raw_len) < 4:
        return None
    (length,) = struct.unpack("<I", raw_len)
    data = sys.stdin.buffer.read(length)
    return json.loads(data.decode("utf-8"))


def send_message(msg: dict) -> None:
    encoded = json.dumps(msg).encode("utf-8")
    sys.stdout.buffer.write(struct.pack("<I", len(encoded)))
    sys.stdout.buffer.write(encoded)
    sys.stdout.buffer.flush()


def handle(msg: dict) -> dict:
    t = msg.get("type")
    if t == "ping":
        return {"ok": True, "version": "0.1.0-host"}
    if t == "getStatus":
        return {"ok": True, "unlocked": False, "note": "Connect Flutter desktop vault"}
    if t == "findForUrl":
        return {"ok": True, "matches": []}
    return {"ok": False, "error": f"unknown type: {t}"}


def main() -> None:
    while True:
        msg = read_message()
        if msg is None:
            break
        send_message(handle(msg))


if __name__ == "__main__":
    main()
