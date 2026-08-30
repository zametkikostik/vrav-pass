# Desktop Native Messaging Host

Flow:

```
Chrome extension  →  Native Host (Python)  →  Flutter LocalVaultServer (127.0.0.1)
```

## Quick install (Linux)

1. Load unpacked extension → copy **Extension ID**
2. ```bash
   cd desktop/native_host
   chmod +x install_linux.sh vrav_host.py
   ./install_linux.sh YOUR_EXTENSION_ID
   ```
3. Run desktop app and **unlock** vault:
   ```bash
   cd mobile
   flutter create . --platforms=linux,windows,macos
   flutter run -d linux   # or windows / macos
   ```
4. Options → **Test native host** → should show `desktop: true`

## Local API (Flutter)

On unlock, desktop app:

- Binds `http://127.0.0.1:17321`
- Writes `~/.config/vrav-pass/desktop-api.json` with `{port, token}`
- Requires `Authorization: Bearer <token>`

Endpoints:

| Path | Result |
|------|--------|
| `GET /ping` | service alive |
| `GET /status` | unlocked |
| `GET /find?url=` | matching passwords |

On lock, server stops and config file is deleted.

## Protocol (extension ↔ host)

| type | response |
|------|----------|
| `ping` | host version + desktop connectivity |
| `getStatus` | unlocked if Flutter API up |
| `findForUrl` | matches from desktop vault |

Extension falls back to its own encrypted cache if host/desktop offline.

## Security notes

- API is **loopback only**
- Random bearer token per unlock session
- Token never sent to Google/our servers
- Host is local stdio only (Chrome policy)
