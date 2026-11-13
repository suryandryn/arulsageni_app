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
| Notifikasi | FCM **hanya sebagai pengantar**: setiap `Notifikasi::kirim()` disimpan di tabel lalu di-push (judul, isi singkat, `jenis` notifikasi/chat) setelah respons terkirim | Satu-satunya cara andal push di Android; data tetap di server |
| Pengingat jadwal | Cron server `pengingat:kirim` tiap hari 08.00 WIB untuk pasien yang dijadwalkan besok (H-1), sekali per tanggal jadwal; admin juga bisa kirim manual | Cukup satu sumber di server; ikut di-push ke HP |
| Chat | Polling tiap ±5 detik saat layar chat terbuka; push untuk pesan baru | Hosting bersama tidak mendukung websocket |
| Auth | Laravel Sanctum (token), disimpan di `flutter_secure_storage` | Password di-hash bcrypt di server |
| File pasien | Disimpan di luar `public/`, diakses lewat endpoint yang cek peran admin | KTP & foto kondisi hanya untuk admin |

## Batasan hosting 250 MB
Video kondisi pasien adalah risiko utama kapasitas. Mitigasi:
1. Video maks. 30 detik, dikompres di HP ke 540p sebelum upload (±5 MB; server menolak > 10 MB).
2. Foto dikompres (maks. 1600 px, JPEG 80%).
3. Hapus media otomatis: **tidak dibuat** (sudah diputuskan). Pantau ruang hosting secara berkala.
4. Admin mendapat indikator pemakaian ruang di menu Atur.

## Struktur kode Flutter
```
lib/
  main.dart              titik masuk
  app.dart               MaterialApp, tema, routing awal berdasarkan sesi
  core/                  token desain (theme), info klinik tetap, konfigurasi, format tanggal
  models/                model data (AppUser, Pendaftaran, Slot, MediaSosial, Pesan, ...)
  data/                  Repository (antarmuka), MockRepository, ApiRepository (menyusul)
  state/                 Session (masuk, peran)
  widgets/               komponen demo: Kartu, Tombol, Tag, Pil, header, NavBawah, toast,
                         KalenderBulan, KartuJadwal, GridMedia
  features/
    auth/                Masuk (tab Pasien/Admin), Daftar Akun
    pasien/              Beranda, Daftar, Daftar Berobat, Detail, Info, Profil, Notifikasi
    admin/               Beranda, Pendaftaran (+ detail), Jadwal (slot), Chat, Atur
    chat/                ChatView bersama pasien & admin
```

Tampilan meniru demo desain; lihat token & komponen di docs/SPESIFIKASI.md.

UI hanya bicara ke `Repository`. Saat ini memakai `MockRepository` (data contoh
di memori) agar tampilan bisa dikembangkan sebelum API siap; nanti cukup diganti
`ApiRepository` di `lib/core/config.dart`.
