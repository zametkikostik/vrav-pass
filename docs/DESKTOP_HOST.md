# Desktop Native Messaging Host

On **desktop**, Chrome can talk to a local host over stdio. This is the preferred path for autofill without exporting JSON.

## Components

| Piece | Path |
|-------|------|
| Host script (prototype) | `desktop/native_host/vrav_host.py` |
| Host manifest template | `desktop/native_host/com.vravpass.host.json` |
| Extension | `extensions/chrome` |

## Install host (Linux example)

1. Make script executable:
   ```bash
   chmod +x desktop/native_host/vrav_host.py
   ```
2. Copy manifest to Chrome's NativeMessagingHosts:
   ```bash
   # Edit path + extension id first
   mkdir -p ~/.config/google-chrome/NativeMessagingHosts
   cp desktop/native_host/com.vravpass.host.json \
      ~/.config/google-chrome/NativeMessagingHosts/
   ```
3. Set absolute `path` to `vrav_host.py` and `allowed_origins` to your extension ID (`chrome://extensions`).

Windows: registry key  
`HKCU\Software\Google\Chrome\NativeMessagingHosts\com.vravpass.host`

## Extension side

Add to `manifest.json`:

```json
"permissions": ["nativeMessaging"]
```

```js
chrome.runtime.sendNativeMessage('com.vravpass.host', { type: 'ping' }, console.log);
```

## Roadmap

1. ✅ stdio host prototype (ping/status)
2. ⏳ Flutter Linux/Windows/macOS desktop app as vault process
3. ⏳ Host asks Flutter over local socket for `findForUrl`
4. ⏳ Never send full vault to extension — only fill payloads for active tab
