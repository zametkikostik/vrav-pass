# Android permissions (after `flutter create .`)

Add to `android/app/src/main/AndroidManifest.xml` inside `<manifest>`:

```xml
<uses-permission android:name="android.permission.USE_BIOMETRIC"/>
<uses-permission android:name="android.permission.USE_FINGERPRINT"/>
```

For `local_auth` on Android, also ensure `minSdkVersion` is at least 23 in `android/app/build.gradle`.
