# Rancangan API (Laravel) — v1

Mengikuti kontrak `lib/data/repository.dart` (alur demo desain).

Base URL: `https://arulsageni.com/api/v1`
Auth: header `Authorization: Bearer <token>` (Laravel Sanctum).
Format: JSON; upload memakai `multipart/form-data`.
Peran: `pasien`, `admin`. Tanggal `YYYY-MM-DD`, jam `HH.mm` (mis. `08.00`).

## Auth & akun
| Method | Endpoint | Peran | Keterangan |
|---|---|---|---|
| POST | `/auth/daftar` | publik | nama, no_hp, sandi → token + user |
| POST | `/auth/masuk` | publik | no_hp + sandi → token + user (akun nonaktif ditolak) |
| POST | `/auth/masuk-admin` | publik | username + sandi |
| POST | `/auth/keluar` | semua | cabut token |
| PUT | `/me/sandi` | semua | sandi_baru (min. 6) |
| POST | `/me/device-token` | semua | simpan token FCM |

## Pasien
| Method | Endpoint | Keterangan |
|---|---|---|
| GET | `/media-sosial` | tautan aktif (publik) |
| GET | `/pendaftaran` | milik akun |
| POST | `/pendaftaran` | multipart: nama, umur, no_hp, alamat, keluhan, `kondisi[]` (≤5 foto ≤5 MB, ≤1 video ≤30 MB), `ktp` |
| GET | `/pendaftaran/{id}` | detail (hanya pemilik) |
| GET | `/notifikasi` · POST `/notifikasi/dibaca` | |
| GET | `/chat?after={id}` · POST `/chat` · POST `/chat/dibaca` | polling saat layar chat terbuka |

## Admin
| Method | Endpoint | Keterangan |
|---|---|---|
| GET | `/admin/ringkas` | menunggu, jadwal hari praktik berikutnya, sisa kuota 30 hari, chat belum dibaca |
| GET | `/admin/pendaftaran?status=&q=` | cari nama / nomor HP |
| GET | `/admin/pendaftaran/{id}` | detail + URL media bertanda tangan (kedaluwarsa singkat) |
| POST | `/admin/pendaftaran/{id}/jadwalkan` | tanggal, jam → cek kuota slot (transaksi + lock) → push ke pasien |
| POST | `/admin/pendaftaran/{id}/tolak` | alasan (wajib) → push |
| POST | `/admin/pendaftaran/{id}/status` | `selesai` / `tidak_hadir` / `batal` |
| POST | `/admin/pendaftaran/{id}/ingatkan` | push pengingat |
| GET | `/admin/kalender?dari=&sampai=` | sisa kuota per tanggal (slot aktif) |
| GET | `/admin/slot?tanggal=` | slot + terisi |
| POST | `/admin/slot` | tanggal, jam, kuota |
| PATCH | `/admin/slot` | tanggal, jam, kuota? / aktif? (kuota ≥ terisi) |
| DELETE | `/admin/slot?tanggal=&jam=` | ditolak bila berisi pasien |
| POST | `/admin/slot/massal` | mulai, sampai (≤ 730 hari), hari[] (0=Min), jam[], kuota → {baru, sudah_ada} |
| GET | `/admin/chat` · GET/POST `/admin/chat/{userId}` | |
| GET | `/admin/pasien` · POST `/admin/pasien/{id}/reset-sandi` · PATCH `/admin/pasien/{id}` (aktif) | |
| GET/PUT | `/admin/media-sosial` | simpan seluruh daftar (urutan, aktif); URL wajib `https://` |

## Tabel (MySQL)
- `users` (id, nama, no_hp, password, role, aktif, fcm_token, timestamps)
- `pendaftaran` (id, user_id, nama, umur, alamat, no_hp, keluhan, status[menunggu|dijadwalkan|ditolak|selesai|tidak_hadir|batal], tanggal, jam, alasan, timestamps)
- `media` (id, pendaftaran_id, jenis[kondisi|ktp], path, mime, ukuran)
- `slot` (tanggal, jam, kuota, aktif) — PK (tanggal, jam)
- `pesan` (id, pasien_id, dari_admin, isi, dibaca_at, created_at)
- `notifikasi` (id, user_id, judul, isi, dibaca_at, created_at)
- `media_sosial` (id, platform, nama, url, aktif, urutan)

## Cron (cPanel)
- Tiap jam: push pengingat H-1 untuk pendaftaran `dijadwalkan`.
- Harian: hapus media pendaftaran yang sudah selesai/ditolak/batal > N hari (hemat ruang 250 MB).
