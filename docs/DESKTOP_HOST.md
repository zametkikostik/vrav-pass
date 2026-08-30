# Desktop Native Messaging Host

Chrome ↔ local host over stdio. Preferred path for desktop autofill.

## Quick install (Linux)

1. Load unpacked extension → copy **Extension ID** from `chrome://extensions`
2. ```bash
   cd desktop/native_host
   chmod +x install_linux.sh vrav_host.py
   ./install_linux.sh YOUR_EXTENSION_ID
   ```
3. Reload extension → **Options → Test native host**

Expected response: `{ "ok": true, "host": { "ok": true, "version": "0.1.0-host" } }`

## Components

| Piece | Path |
|-------|------|
| Host script | `desktop/native_host/vrav_host.py` |
| Manifest template | `desktop/native_host/com.vravpass.host.json` |
| Install script | `desktop/native_host/install_linux.sh` |
| Extension client | `extensions/chrome/lib/native_host.js` |

## Protocol

| type | direction | response |
|------|-----------|----------|
| `ping` | ext→host | `{ok, version}` |
| `getStatus` | ext→host | `{ok, unlocked, …}` |
| `findForUrl` | ext→host | `{ok, matches: [...]}` |

Extension `findForTab` tries host first, then local cache.

## Windows

Create registry value:

`HKCU\Software\Google\Chrome\NativeMessagingHosts\com.vravpass.host`

= full path to `com.vravpass.host.json` (edit `path` inside to `vrav_host.py` or a `.bat` wrapper).

## Roadmap

1. ✅ stdio host + extension client + install script
2. ⏳ Flutter desktop app holds unlocked vault
3. ⏳ Host queries Flutter (local socket) for `findForUrl`
4. ⏳ Return only credentials for active tab domain
