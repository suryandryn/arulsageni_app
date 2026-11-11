# Padepokan Arul Sageni

Aplikasi Android pendaftaran berobat & janji temu untuk Padepokan Arul Sageni
(Kang Arul Sageni, Subang). Pasien mendaftar, admin menilai dan memberi jadwal,
pasien menerima notifikasi dan nomor antrean.

- **Aplikasi**: Flutter (Android 8+), package `com.arulsageni.app`
- **Backend** (menyusul): Laravel + MySQL di hosting `arulsageni.com`
- **Notifikasi push**: Firebase Cloud Messaging (hanya pengantar, tanpa data)

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
flutter run            # HP / emulator Android
flutter test
flutter analyze
```

Saat ini aplikasi memakai **data contoh** (`AppConfig.useMock = true`), belum
terhubung ke server. Akun demo:

| Peran | Login | Kata sandi |
|---|---|---|
| Pasien | `081234567890` | `123456` |
| Admin | `admin` | `admin123` |

## Status
- [x] Struktur proyek, tema hijau-putih, navigasi pasien & admin
- [x] Semua layar pasien & admin dengan data contoh
- [x] Logika kuota, nomor antrean, tanggal libur, periode jadwal (teruji)
- [ ] API Laravel di hosting + `ApiRepository`
- [ ] Notifikasi push (FCM) & pengingat lokal
- [ ] Kompresi video sebelum upload
- [ ] Logo & ikon aplikasi (menunggu logo klien)
- [ ] Keystore rilis & unggah Play Store
