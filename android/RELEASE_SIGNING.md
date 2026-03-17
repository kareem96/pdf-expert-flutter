# Panduan Sertifikat Rilis (Release Signing)

Sertifikat ini sangat penting untuk pembaruan aplikasi di masa mendatang. Jika hilang, Anda tidak akan bisa mengunggah versi baru aplikasi ke Play Store.

## Lokasi File
- **Keystore**: `android/app/upload-keystore.jks`
- **Konfigurasi**: `android/key.properties`

## Detail Credential
- **Keystore Password**: `password123`
- **Key Alias**: `upload`
- **Key Password**: `password123`

## Cara Kerja
Gradle akan secara otomatis membaca file `key.properties` saat Anda menjalankan perintah:
```bash
flutter build appbundle --release
```

## Keamanan (PENTING)
1. **Cadangkan (Backup)**: Simpan salinan `upload-keystore.jks` di tempat aman (Google Drive/Cloud pribadi).
2. **Git**: Pastikan `key.properties` sudah ada di dalam `.gitignore` agar tidak bocor ke publik.
3. **Ganti Password**: Jika ingin mengganti password di masa depan, gunakan perintah `keytool -storepasswd`.

---
*Dibuat otomatis oleh Antigravity (Protokol KAREEM)*
