# User guide

## English

### First run
1. Install the app (APK from Releases or build yourself).
2. **Create vault** → choose a strong master password (you will not be able to reset it).
3. Add passwords / notes / bookmarks with **+**.

### Daily use
- **Unlock** with master password or biometrics (after enabling in Security).
- Tap an item → copy username/password / view TOTP.
- **Lock** from the toolbar when you step away.

### Backup
1. Unlock → Sync / Backup.
2. **Export** encrypted `.enc` file → store on USB or another drive.
3. To restore: **Import** that file (same master password).

### Sync between phones
1. Configure **WebDAV** (e.g. Yandex Disk: `https://webdav.yandex.ru` + app password).
2. Device A: **Upload**. Device B: same master password → **Download**.

### Browser
- Install the extension from `extensions/chrome` (developer mode).
- Prefer desktop native host when on Linux; JSON import is only a temporary bridge.

---

## Русский

### Первый запуск
1. Установите приложение (APK из Releases или сборка).
2. **Создать хранилище** → придумайте надёжный мастер-пароль (восстановить его нельзя).
3. Добавляйте пароли / заметки / закладки кнопкой **+**.

### Каждый день
- **Разблокировка** мастер-паролем или биометрией (включить в «Безопасность»).
- Тап по записи → копировать логин/пароль / код TOTP.
- **Блокировка** из панели, когда отошли.

### Резервная копия
1. Разблокировать → Синхронизация.
2. **Экспорт** файла `.enc` → сохранить отдельно.
3. Восстановление: **Импорт** того же файла (тот же мастер-пароль).

### Синхронизация между телефонами
1. Настроить **WebDAV** (Яндекс.Диск: `https://webdav.yandex.ru` + пароль приложения).
2. Устройство A: **Выгрузить**. Устройство B: тот же мастер-пароль → **Скачать**.

### Браузер
- Расширение: `extensions/chrome` (режим разработчика).
- На Linux удобнее native host; JSON-импорт — временный мост.
