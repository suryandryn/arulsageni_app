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
| Pasien | `0812-3456-7890` | `123456` |
| Admin | `admin` | `123456` |

(Di mode demo, kolom masuk sudah terisi.)

## Status
- [x] Tampilan & alur mengikuti demo desain (hijau `#2F5D3A`, emas, krem; font Lora + Plus Jakarta Sans)
- [x] Semua layar pasien & admin dengan data contoh
- [x] Jadwal berbasis slot jam + kuota, kalender sisa kuota, slot massal (teruji)
- [ ] API Laravel di hosting + `ApiRepository`
- [ ] Notifikasi push (FCM) & pengingat lokal
- [ ] Kompresi video sebelum upload
- [ ] Logo & ikon aplikasi (menunggu logo klien)
- [ ] Keystore rilis & unggah Play Store
