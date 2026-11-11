# Arsitektur

```
┌────────────────────┐   HTTPS (JSON + multipart)   ┌──────────────────────────────┐
│  Aplikasi Flutter  │ ───────────────────────────▶ │ API Laravel — arulsageni.com │
│  (Android 8+)      │ ◀─────────────────────────── │  /api/v1/...                 │
└─────────┬──────────┘                              └──────┬───────────────┬───────┘
          │ push                                           │               │
          │                                                ▼               ▼
┌─────────┴──────────┐   kirim notifikasi (HTTP v1)  ┌──────────┐   ┌─────────────────┐
│ Firebase Cloud     │ ◀──────────────────────────── │  MySQL   │   │ storage/private │
│ Messaging (FCM)    │                               │ (hosting)│   │ foto/video/KTP  │
└────────────────────┘                               └──────────┘   └─────────────────┘
```

## Keputusan
| Topik | Keputusan | Alasan |
|---|---|---|
| Aplikasi | Flutter | Satu kode, performa native |
| Backend | Laravel (PHP) di hosting cPanel klien | Data tetap di hosting klien; sesuai konsep awal |
| Database | MySQL di hosting | Sudah tersedia di paket hosting |
| Notifikasi | FCM **hanya sebagai pengantar** | Satu-satunya cara andal push di Android; tidak menyimpan data |
| Pengingat jadwal | Notifikasi lokal terjadwal di HP + push dari cron server | Tetap muncul walau internet mati saat hari H |
| Chat | Polling tiap ±5 detik saat layar chat terbuka; push untuk pesan baru | Hosting bersama tidak mendukung websocket |
| Auth | Laravel Sanctum (token), disimpan di `flutter_secure_storage` | Password di-hash bcrypt di server |
| File pasien | Disimpan di luar `public/`, diakses lewat endpoint yang cek peran admin | KTP & foto kondisi hanya untuk admin |

## Batasan hosting 250 MB
Video kondisi pasien adalah risiko utama kapasitas. Mitigasi:
1. Batas video maksimal ±30 detik, dikompres di HP sebelum upload (target < 8 MB).
2. Foto dikompres (maks. 1600 px, JPEG 80%).
3. Media kondisi & KTP dihapus otomatis (cron) X hari setelah janji selesai /
   ditolak — durasi disepakati dengan klien.
4. Admin mendapat indikator pemakaian ruang di menu Atur.

## Struktur kode Flutter
```
lib/
  main.dart              titik masuk
  app.dart               MaterialApp, tema, routing awal berdasarkan sesi
  core/                  tema, konfigurasi, util format tanggal/rupiah
  models/                model data (User, Pendaftaran, KlinikInfo, Pesan, ...)
  data/                  Repository (antarmuka), MockRepository, ApiRepository
  state/                 SessionController (login, peran)
  features/
    auth/                masuk & daftar akun
    pasien/              shell + Beranda, Daftar, Janji, Chat, Notifikasi, Info
    admin/               shell + Ringkas, Pendaftar, Jadwal, Atur
```

UI hanya bicara ke `Repository`. Saat ini memakai `MockRepository` (data contoh
di memori) agar tampilan bisa dikembangkan sebelum API siap; nanti cukup diganti
`ApiRepository` di `lib/core/config.dart`.
