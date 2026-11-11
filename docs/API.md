# Rancangan API (Laravel) — v1

Base URL: `https://arulsageni.com/api/v1`
Auth: header `Authorization: Bearer <token>` (Laravel Sanctum).
Format: JSON; upload memakai `multipart/form-data`.
Peran: `pasien`, `admin`.

## Auth
| Method | Endpoint | Peran | Keterangan |
|---|---|---|---|
| POST | `/auth/register` | publik | nama, no_wa, password |
| POST | `/auth/login` | publik | no_wa/email + password → token + user |
| POST | `/auth/logout` | semua | cabut token |
| GET | `/me` | semua | profil |
| POST | `/me/device-token` | semua | simpan token FCM |

## Pasien
| Method | Endpoint | Keterangan |
|---|---|---|
| GET | `/klinik` | info klinik, biaya, medsos (publik) |
| GET | `/pendaftaran` | daftar milik pasien |
| POST | `/pendaftaran` | multipart: nama, no_wa, kota, keluhan, `media_kondisi[]`, `foto_ktp` |
| GET | `/pendaftaran/{id}` | detail |
| POST | `/pendaftaran/{id}/lengkapi` | kirim ulang data yang diminta |
| POST | `/pendaftaran/{id}/jadwal-ulang` | alasan |
| POST | `/pendaftaran/{id}/batal` | |
| GET | `/notifikasi` | |
| GET | `/chat?after={id}` | pesan dengan admin (polling) |
| POST | `/chat` | teks |

## Admin
| Method | Endpoint | Keterangan |
|---|---|---|
| GET | `/admin/ringkas` | jumlah menunggu, jadwal besok, total, chat terbaru |
| GET | `/admin/pendaftar?status=` | |
| GET | `/admin/pendaftar/{id}` | detail + URL media bertanda tangan |
| GET | `/admin/media/{id}` | stream file (cek peran admin) |
| POST | `/admin/pendaftar/{id}/jadwalkan` | tanggal, jam → nomor antrean otomatis + push |
| POST | `/admin/pendaftar/{id}/minta-lengkapi` | catatan |
| POST | `/admin/pendaftar/{id}/tolak` | catatan → status `tidak_dapat_ditangani` |
| POST | `/admin/pendaftar/{id}/selesai` | |
| POST | `/admin/pendaftar/{id}/tidak-hadir` | |
| POST | `/admin/pendaftar/{id}/ingatkan` | kirim push pengingat |
| GET | `/admin/jadwal?tanggal=` | daftar pasien + kuota terisi |
| GET | `/admin/kalender?bulan=` | ketersediaan per tanggal (sisa kuota/libur) |
| GET/PUT | `/admin/pengaturan` | info klinik, kuota, hari & jam praktik, slot jam, periode |
| POST | `/admin/periode/perpanjang` | tahun: 1 atau 2 |
| GET/POST/DELETE | `/admin/tanggal-khusus` | kuota khusus / libur |
| GET | `/admin/chat` | daftar percakapan |
| GET/POST | `/admin/chat/{userId}` | |

## Tabel (MySQL)
- `users` (id, nama, no_wa, email, password, role, fcm_token)
- `pendaftaran` (id, user_id, kode, nama, no_wa, kota, keluhan, status, catatan_admin, tanggal, jam, no_antrean, timestamps)
- `media` (id, pendaftaran_id, jenis[kondisi_foto|kondisi_video|ktp], path, ukuran)
- `pesan` (id, user_id, dari_admin, isi, dibaca_at, created_at)
- `notifikasi` (id, user_id, judul, isi, data, dibaca_at, created_at)
- `pengaturan` (key, value JSON) — info klinik, kuota default, hari/jam praktik, slot, periode_akhir
- `tanggal_khusus` (tanggal, libur, kuota)

## Cron (cPanel)
- Tiap jam: kirim pengingat H-1 dan hari H.
- Harian: hapus media pendaftaran yang sudah selesai/ditolak > N hari.
