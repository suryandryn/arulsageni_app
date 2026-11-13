# Padepokan Arul Sageni

Aplikasi Android pendaftaran berobat & janji temu untuk Padepokan Arul Sageni
(Kang Arul Sageni, Subang). Pasien mendaftar, admin menilai dan memberi jadwal,
pasien menerima notifikasi dan nomor antrean.

- **Aplikasi**: Flutter (Android 8+), package `com.arulsageni.app`
- **Backend** (menyusul): Laravel + MySQL di hosting `arulsageni.com`
- **Notifikasi push**: Firebase Cloud Messaging, proyek `arul-sageni` (hanya pengantar: data tetap di server, push membawa judul & isi singkat)

## Dokumentasi
| Dokumen | Isi |
|---|---|
| [docs/SPESIFIKASI.md](docs/SPESIFIKASI.md) | Fitur, menu, status, aturan jadwal, data yang masih ditunggu |
| [docs/ARSITEKTUR.md](docs/ARSITEKTUR.md) | Diagram sistem, keputusan teknis, batasan hosting, struktur kode |
| [docs/API.md](docs/API.md) | Rancangan endpoint, tabel MySQL, cron |
| `reference/` | Dokumen asli dari klien (file kredensial tidak di-commit) |

## Menjalankan
```bash
flutter pub get
flutter run                                   # server Laravel di laptop (emulator), DB sama dengan panel web
adb reverse tcp:8000 tcp:8000 && flutter run --dart-define=API_URL=http://127.0.0.1:8000/api/v1   # HP lewat kabel USB (paling mudah)
flutter run --dart-define=API_URL=http://<IP-laptop>:8000/api/v1   # HP satu WiFi dengan laptop (server: --host=0.0.0.0, izinkan port 8000 di firewall)
flutter run --dart-define=ENV=mock            # data contoh di memori, tanpa server
flutter run --dart-define=ENV=produksi        # debug ke server live velocitydatacenter.biz/arulsageni.com
flutter build apk --release                   # rilis → server live (lihat "Build rilis")
flutter test
flutter analyze
```

Lingkungan diatur di `lib/core/config.dart`. Build debug mengizinkan `http://`
(server lokal); build rilis wajib `https://`.

### Build rilis (APK untuk pengguna)
Server live: `https://velocitydatacenter.biz/arulsageni.com/api/v1` (`AppConfig.urlProduksi` di
`lib/core/config.dart`; ganti di sana bila pindah domain).

1. **Sekali saja: buat keystore rilis** (pilih sandi sendiri, simpan baik-baik + cadangkan file `.jks`;
   tanpa file & sandi yang sama, aplikasi tidak bisa di-update di HP pengguna):
   ```bash
   keytool -genkey -v -keystore android/arulsageni-rilis.jks -keyalg RSA -keysize 2048 -validity 10000 -alias arulsageni
   ```
   Salin `android/key.properties.contoh` → `android/key.properties`, isi sandinya.
   (`*.jks` dan `key.properties` tidak di-commit.)
2. **Tiap rilis: naikkan angka setelah `+`** di `version:` pada `pubspec.yaml` (mis. `1.0.0+1` → `1.0.0+2`).
3. `flutter build apk --release` → `build/app/outputs/flutter-apk/app-release.apk`.
   Tanpa `android/key.properties`, APK ditandatangani kunci **debug** (jangan dibagikan). Cek sebelum membagikan
   (`apksigner` ada di Android SDK `build-tools`; `keytool` di `Android Studio\jbr\bin`):
   `apksigner verify --print-certs build/app/outputs/flutter-apk/app-release.apk` → `DN` harus bukan `CN=Android Debug`.

### Server lokal (Laravel di laptop)
Repo backend `D:\arulsageni-dashboard`, database MySQL Laragon `arulsageni`:
```bash
cd D:\arulsageni-dashboard
php artisan serve --host=0.0.0.0 --port=8000   # panel web: http://localhost:8000
```
Uji integrasi aplikasi ↔ server (membuat data uji di database lokal):
```bash
flutter test test/api_lokal_test.dart --dart-define=API_LOKAL=http://127.0.0.1:8000/api/v1
```

### Akun
Mode mock dan server lokal (data `ContohSeeder`) memakai akun yang sama:

| Peran | Login | Kata sandi |
|---|---|---|
| Pasien | `0812-3456-7890` | `123456` |
| Admin | `admin` | `123456` (lokal; staging/produksi berbeda) |

(Di mode mock, kolom masuk sudah terisi.)

## Status
- [x] Tampilan & alur mengikuti demo desain (hijau `#2F5D3A`, emas, krem; font Lora + Plus Jakarta Sans)
- [x] Semua layar pasien & admin dengan data contoh
- [x] Jadwal berbasis slot jam + kuota, kalender sisa kuota, slot massal (teruji)
- [x] API Laravel (`/api/v1`, repo dashboard) + `ApiRepository`, sesi tersimpan, polling chat (teruji, termasuk integrasi ke server lokal)
- [ ] API di staging & produksi (cPanel)
- [ ] Pemutar video (sekarang video ditampilkan sebagai kotak nama berkas)
- [x] Notifikasi push (FCM) & pengingat H-1 otomatis (cron server)
- [ ] Kompresi video sebelum upload
- [ ] Logo & ikon aplikasi (menunggu logo klien)
- [ ] Keystore rilis & unggah Play Store

### Mengembalikan data lokal ke data demo
Menghapus seluruh isi database lokal `arulsageni` dan berkas pasien, lalu mengisi ulang
data yang sama dengan mode mock:
```bash
cd D:\arulsageni-dashboard
rm -rf storage/app/private/pasien
php artisan migrate:fresh --seed
php artisan db:seed --class=ContohSeeder
```
