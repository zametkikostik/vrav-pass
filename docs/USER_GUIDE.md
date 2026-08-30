# User guide

## English

### First run
1. Install the app (APK from Releases or build yourself).
2. **Create vault** → strong master password (cannot be reset).
3. Add items with **+**, or **Import** (Bitwarden / Chrome).

### Daily use
- Unlock with password or biometrics.
- Search and filter by type; star favorites.
- Copy fields — clipboard clears after ~45s.
- **Lock** when you leave the phone.

### Backup
1. Sync → **Export** `.enc` → keep a copy offline.
2. Restore: **Import** that file (same master password).

### Sync phones
WebDAV (e.g. Yandex Disk) → **Upload** on A → **Download** on B (same master password).

### Import from Chrome
Chrome → Settings → Passwords → ⋮ → Export → CSV → Vrav Pass → Import → Chrome.

### Import from Bitwarden
Bitwarden → Export **unencrypted** JSON/CSV → Import → Bitwarden.

### Browser extension
- Chrome/Yandex: load `extensions/chrome` unpacked.
- Firefox: temporary add-on → same `manifest.json`.
- Options: import JSON or use desktop native host.

---

## Русский

### Первый запуск
1. Установите APK (Releases или своя сборка).
2. **Создать хранилище** → надёжный мастер-пароль (сбросить нельзя).
3. Добавляйте записи **+** или **Импорт** (Bitwarden / Chrome).

### Каждый день
- Разблокировка паролем или биометрией.
- Поиск, фильтры, избранное ★.
- Копирование — буфер очищается ~через 45 с.
- **Блокировка**, когда отошли.

### Резервная копия
Экспорт `.enc` → храните отдельно. Импорт того же файла с тем же мастер-паролем.

### Синхронизация
WebDAV → **Выгрузить** / **Скачать** на втором устройстве.

### Импорт Chrome
Chrome → Пароли → ⋮ → Экспорт → CSV → в приложении Импорт → Chrome.

### Импорт Bitwarden
Экспорт **без шифрования** JSON/CSV → Импорт → Bitwarden.

### Расширение
Chrome/Yandex — unpacked `extensions/chrome`.  
Firefox — временное дополнение, тот же `manifest.json`.
