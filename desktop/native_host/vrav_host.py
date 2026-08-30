#!/usr/bin/env python3
"""Vrav Pass Native Messaging host.

Talks to Flutter desktop LocalVaultServer via 127.0.0.1 when unlocked.
Config: ~/.config/vrav-pass/desktop-api.json (written by Flutter on unlock)
"""
from __future__ import annotations

import json
import os
import struct
import sys
import urllib.error
import urllib.parse
import urllib.request

VERSION = "0.2.0-host"


def config_path() -> str:
    if sys.platform == "win32":
        base = os.environ.get("APPDATA", ".")
        return os.path.join(base, "vrav-pass", "desktop-api.json")
    home = os.path.expanduser("~")
    return os.path.join(home, ".config", "vrav-pass", "desktop-api.json")


def load_api_config() -> dict | None:
    path = config_path()
    if not os.path.isfile(path):
        return None
    try:
        with open(path, "r", encoding="utf-8") as f:
            return json.load(f)
    except Exception:
        return None


def api_get(path: str, query: str = "") -> dict | None:
    cfg = load_api_config()
    if not cfg or "port" not in cfg or "token" not in cfg:
        return None
    url = f"http://127.0.0.1:{cfg['port']}{path}"
    if query:
        url += "?" + query
    req = urllib.request.Request(
        url,
        headers={"Authorization": f"Bearer {cfg['token']}"},
        method="GET",
    )
    try:
        with urllib.request.urlopen(req, timeout=2.0) as resp:
            return json.loads(resp.read().decode("utf-8"))
    except (urllib.error.URLError, TimeoutError, json.JSONDecodeError, OSError):
        return None


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
        api = api_get("/ping")
        return {
            "ok": True,
            "version": VERSION,
            "desktop": api is not None,
            "desktopPing": api,
        }
    if t == "getStatus":
        api = api_get("/status")
        if api and api.get("ok"):
            return {"ok": True, "unlocked": True, "source": "desktop"}
        return {
            "ok": True,
            "unlocked": False,
            "note": "Unlock Vrav Pass desktop app first",
        }
    if t == "findForUrl":
        url = msg.get("url") or ""
        q = "url=" + urllib.parse.quote(url, safe="")
        api = api_get("/find", q)
        if api and api.get("ok"):
            return {
                "ok": True,
                "matches": api.get("matches") or [],
                "source": "desktop",
            }
        return {"ok": True, "matches": [], "source": "none"}
    return {"ok": False, "error": f"unknown type: {t}"}


def main() -> None:
    while True:
        msg = read_message()
        if msg is None:
            break
        send_message(handle(msg))


if __name__ == "__main__":
    main()
