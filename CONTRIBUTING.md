# Contributing to Vrav Pass

Thanks for helping build a sovereign, offline-first vault.

## Principles

1. **No plaintext to the cloud** — sync paths must stay E2EE.
2. **Local-first** — app must work fully offline.
3. **Honest security claims** — no marketing crypto.
4. **Small focused PRs** beat giant dumps.

## Dev setup

```bash
cd mobile
./scripts/bootstrap.sh
flutter pub get
flutter analyze
flutter test
flutter run
```

Extension: load `extensions/chrome` as unpacked.

## PR checklist

- [ ] Does not log secrets
- [ ] UI strings added for **en, ru, bg, th** when user-visible
- [ ] `flutter analyze` reasonably clean
- [ ] Crypto changes explained in the PR body
- [ ] Docs updated if behavior changes

## Good first issues

- Bitwarden CSV/JSON import
- Clipboard auto-clear
- Search in vault list
- Firefox extension port
- Better empty states / onboarding copy

## Code of conduct

Be respectful. No harassment. Assume good faith.
