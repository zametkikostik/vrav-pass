# Security Policy

## Supported versions

| Version | Supported |
|---------|-----------|
| `main` (beta) | ✅ best-effort |
| Tagged releases | ✅ until next major |

## What we protect

- Vault ciphertext confidentiality without master password / DEK
- No plaintext passwords sent to any Vrav-operated server (there is none)

## What we do not claim

- Formal third-party audit (planned when community grows)
- Post-quantum security unless `liboqs` is loaded (`isPostQuantumNative`)
- Protection against a compromised OS or malicious browser extension with full device control

## Reporting a vulnerability

**Please do not open a public issue for critical crypto/leak bugs.**

1. Email or contact the maintainer via GitHub: [@zametkikostik](https://github.com/zametkikostik)
2. Include: affected component (mobile / extension / host), steps, impact, optional PoC
3. Allow reasonable time for a fix before public disclosure

We will acknowledge reports as soon as practical and credit you if you want.

## Safe harbor

Good-faith research on **your own** vault/data is welcome. Do not attack third-party systems or other users’ machines.
