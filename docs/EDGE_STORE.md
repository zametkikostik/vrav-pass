# Microsoft Edge Add-ons — notes for Vrav Pass

The extension package is the same Chromium MV3 tree: `extensions/chrome`.

Edge is Chromium-based; **Load unpacked** works like Chrome.

## Sideload (development / friends)

1. Open `edge://extensions`
2. Enable **Developer mode**
3. **Load unpacked** → select `extensions/chrome`

Yandex Browser and Brave: same steps on their extensions page.

## Publishing to Microsoft Edge Add-ons (later)

When you want a public listing:

1. Partner Center / [Edge Add-ons dashboard](https://partner.microsoft.com/dashboard/microsoftedge/overview)
2. Zip the contents of `extensions/chrome` (manifest at zip root, no parent folder required)
3. Provide:
   - Short description (offline-first, no Vrav servers)
   - Privacy statement URL (or GitHub SECURITY + README)
   - Screenshots of popup + options
   - Category: Productivity / Privacy & security
4. Permissions justification:
   - `storage` — local encrypted cache
   - `activeTab` / `scripting` — autofill on user gesture
   - `host_permissions` / `<all_urls>` — match login forms (minimize in store review notes: only for autofill)
   - `nativeMessaging` — optional desktop host; say “optional, local only”
   - `clipboardWrite` — copy credentials on user action

### Review tips

- Do **not** claim “military-grade” or full post-quantum unless liboqs ships
- State clearly: vault source of truth is the mobile/desktop app; extension holds a user-locked cache
- JSON import is plaintext at import time — mention as advanced/temporary

### Store vs GitHub

| Path | When |
|------|------|
| Load unpacked / GitHub | Friends, beta, OSS users |
| Edge Add-ons signed | Broader Windows audience |
| Chrome Web Store | Separate registration + fee |

For beta, **GitHub + Load unpacked** is enough.
