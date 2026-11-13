# API (Laravel) — v1

Kode: repo `velocitycustomer/arulsageni-dashboard` (Laravel 12, satu proyek dengan
panel admin web; berkas `routes/api.php`, `app/Http/Controllers/Api`, test
`tests/Feature/ApiTest.php`). Mengikuti kontrak `lib/data/repository.dart`.

| Lingkungan | Base URL |
|---|---|
| **Produksi / live** (via Cloudflare) | `https://velocitydatacenter.biz/arulsageni.com/api/v1` — bawaan build rilis APK |
| Domain sendiri (rencana, belum dipakai) | `https://arulsageni.com/api/v1` — build dengan `--dart-define=API_URL=...` |

- Auth: header `Authorization: Bearer <token>` (Laravel Sanctum). Token tidak kedaluwarsa;
  dicabut saat keluar, akun dinonaktifkan, atau sandi direset admin.
- Kirim `Accept: application/json`. Error selalu JSON:
  - `401` `{message: "Sesi berakhir. Silakan masuk lagi."}` → hapus token, ke layar Masuk
  - `403` akun nonaktif / peran salah · `404` `{message: "Data tidak ditemukan."}`
  - `422` validasi: `{message, errors: {kolom: ["pesan"]}}` — pesan sudah bahasa Indonesia, tampilkan apa adanya
  - `429` terlalu banyak percobaan
- Tanggal `YYYY-MM-DD`, jam slot `HH.mm` (`08.00`; `8:00` diterima dan dinormalkan),
  waktu ISO-8601 (`2026-11-12T08:56:11+07:00`).
- Respons tunggal/daftar dibungkus `data`. Daftar berhalaman menyertakan `meta`
  (`current_page`, `last_page`, `total`) dan `links`.

## Objek
```jsonc
// User
{"id":2,"nama":"Siti","no_hp":"081234567890","role":"pasien","aktif":true,"dibuat":"…",
 "username":"admin" /* hanya admin */, "jumlah_pendaftaran":3 /* hanya di daftar pasien admin */}

// Pendaftaran
{"id":7,"user_id":2,"nama":"Siti","umur":42,"alamat":"…","no_hp":"…","keluhan":"…",
 "status":"menunggu|perlu_dilengkapi|dijadwalkan|ditolak|selesai|tidak_hadir|batal","status_label":"Menunggu",
 "tanggal":"2026-11-20"|null,"jam":"08.00"|null,"nomor_antrean":3|null /* per tanggal */,"alasan":null,"dibuat":"…",
 "catatan":"…"|null /* catatan perlu dilengkapi terakhir dari admin; tetap ada setelah dilengkapi */,
 "dilengkapi":"…"|null /* waktu pasien terakhir melengkapi */,
 "media":[{"id":3,"jenis":"kondisi|ktp","mime":"image/jpeg","ukuran":123456,"url":"…/api/v1/media/3/kondisi-3.jpg"}],
 "pengajuan":{Pengajuan}|null /* terbaru; di daftar & detail pasien, daftar & detail admin */,
 "akun":{User} /* hanya admin, di detail */}

// Pengajuan (jadwal ulang / pembatalan dari pasien)
{"id":9,"jenis":"jadwal_ulang|batal","jenis_label":"Jadwal ulang","status":"menunggu|disetujui|ditolak",
 "tanggal":"2026-11-25"|null,"jam":"10.00"|null /* jadwal yang diminta (jadwal_ulang) */,
 "alasan":"…"|null /* dari pasien */,"alasan_tolak":"…"|null /* dari admin */,"dibuat":"…","diputuskan":"…"|null}

// Pesan
{"id":1,"pasien_id":2,"dari_admin":false,"isi":"…","waktu":"…","dibaca":false}

// Notifikasi
{"id":1,"judul":"…","isi":"…","waktu":"…","dibaca":false}
```

`media[].url` butuh header `Authorization` (pakai `headers:` di `Image.network` /
`VideoPlayerController.networkUrl(httpHeaders:)`). Mendukung `Range` untuk video.
Pasien hanya menerima media `kondisi` miliknya; KTP hanya untuk admin.

## Auth & akun
| Method | Endpoint | Body | Balasan |
|---|---|---|---|
| POST | `/auth/daftar` | nama, no_hp, sandi (min. 6) | `201 {token, user}` |
| POST | `/auth/masuk` | no_hp, sandi | `{token, user}` · nonaktif `403` |
| POST | `/auth/masuk-admin` | username, sandi | `{token, user}` |
| POST | `/auth/keluar` | – | `204`; juga mengosongkan `fcm_token` (HP berhenti menerima push akun ini) |
| GET | `/me` | – | `{data: User}` |
| PUT | `/me/sandi` | sandi_baru (min. 6); **admin** wajib `sandi_lama` (salah → `422 sandi_lama`) | `204` |
| PATCH | `/me` | **admin saja**: nama, email (boleh kosong, unik) | `{data: user}` (user admin memuat `email`) |
| POST | `/me/device-token` | token (FCM, boleh null) | `204`; token yang sama dilepas dari akun lain (ganti akun di HP yang sama) |

Nomor HP disimpan hanya angka berawalan `0`; `+62 812-…`, `0812-…`, `62812…` dianggap sama.
Batas: 5 percobaan/menit per nomor/username, 60/menit per IP.

## Umum (semua peran yang masuk)
| Method | Endpoint | Keterangan |
|---|---|---|
| GET | `/media-sosial` | **publik**; `{data:[{platform,nama,url}]}` aktif, berurutan |
| GET | `/info-klinik` | **publik**; `{data:{alamat, maps_url, wa_admin, biaya (satu baris = satu poin), biaya_catatan, website_url (kosong = sembunyikan), website_keterangan, jadwal_berobat (satu baris = satu paragraf; `{tanggal}` diganti tanggal pasien), penanda_tanggal, logo_url (halaman Masuk & Daftar Akun), foto_url (foto profil menu Info); null = gambar bawaan aplikasi}}` |
| GET | `/gambar/{jenis}` | **publik**; `jenis` = `logo` (halaman Masuk & Daftar Akun) atau `foto` (foto profil menu Info). `404` bila belum diatur. Pakai `logo_url` / `foto_url` dari `/info-klinik` (memuat `?v=` agar cache diperbarui saat gambar diganti) |
| GET | `/media/{id}/{nama}` | berkas foto/video/KTP (lihat aturan di atas); `{nama}` hanya penanda jenis, mis. `kondisi-3.mp4` |
| GET | `/notifikasi` | 100 terbaru + `belum_dibaca` |
| POST | `/notifikasi/dibaca` | tandai semua dibaca · `204` |

## Pasien
| Method | Endpoint | Keterangan |
|---|---|---|
| GET | `/pendaftaran` | milik akun, terbaru dulu, dengan media |
| POST | `/pendaftaran` | multipart: nama, umur, no_hp, alamat, keluhan, `kondisi[]` (wajib; ≤5 foto JPG/PNG ≤5 MB, ≤1 video MP4 ≤30 MB), `ktp` (wajib; JPG/PNG ≤5 MB) → `201 {data: Pendaftaran}` |
| GET | `/pendaftaran/{id}` | hanya pemilik, selain itu `404` |
| POST | `/pendaftaran/{id}/lengkapi` | hanya status `perlu_dilengkapi` (selain itu `422 status`). Multipart: nama, umur, no_hp, alamat, keluhan, `pertahankan[]` (id media kondisi lama yang tetap dipakai; sisanya dihapus), `kondisi[]` baru (opsional), `ktp` baru (opsional, mengganti yang lama). Total kondisi ≥1, ≤5 foto, ≤1 video → `{data: Pendaftaran}` status `menunggu`, `catatan` tetap, `dilengkapi` terisi |
| POST | `/pendaftaran/{id}/pengajuan` | jenis `jadwal_ulang` (+ tanggal > hari ini, jam; slot harus aktif & bersisa, beda dari jadwal sekarang; hanya untuk `dijadwalkan`) atau `batal` (untuk `menunggu`/`perlu_dilengkapi`/`dijadwalkan`), alasan? (≤1000) → `201 {data: Pendaftaran}`. `422` bila masih ada pengajuan menunggu |
| DELETE | `/pendaftaran/{id}/pengajuan` | tarik pengajuan yang masih menunggu → `{data: Pendaftaran}` |
| GET | `/kalender?dari=&sampai=` | sisa kuota slot aktif per tanggal (seperti `/admin/kalender`), untuk memilih jadwal ulang |
| GET | `/slot?tanggal=` | `{data:[{jam,kuota,aktif,terisi,sisa}]}` hanya slot aktif, tanpa data pasien lain |
| GET | `/chat?after={id}` | pesan sesudah id (polling tiap 3 detik saat layar chat terbuka) + `belum_dibaca`, `mengetik` (admin sedang mengetik), `dibaca_hingga` (id pesan sendiri terbesar yang sudah dibaca admin → centang dua) |
| POST | `/chat` | isi (≤2000, emoji boleh) → `201 {data: Pesan}`; menghapus status mengetik pengirim |
| POST | `/chat/dibaca` | tandai pesan admin dibaca · `204` |
| POST | `/chat/mengetik` | `aktif` (bawaan `true`; `false` saat kolom dikosongkan) · `204`. Kirim paling sering tiap 3 detik selama mengetik; status hilang sendiri setelah 6 detik |

## Admin (`/admin/...`)
| Method | Endpoint | Keterangan |
|---|---|---|
| GET | `/admin/ringkas` | `{menunggu, hari_berikut, jadwal_hari_berikut:[{id,nama,jam,no_hp,nomor_antrean}] (urut nomor), sisa_kuota_30_hari, chat_belum_dibaca, pengajuan_menunggu, terbaru:[Pendaftaran]}` |
| GET | `/admin/pendaftaran?status=&q=&pengajuan=&page=&per_page=` | berhalaman (20) + `jumlah` per status + `pengajuan_menunggu`; q = nama / nomor HP; `pengajuan=1` = hanya yang punya pengajuan menunggu |
| GET | `/admin/pendaftaran/{id}` | detail + semua media + `akun` |
| POST | `/admin/pendaftaran/{id}/jadwalkan` | tanggal (> hari ini), jam → cek kuota (transaksi + lock) → notifikasi pasien. Ditolak untuk status selesai/tidak hadir/batal |
| POST | `/admin/pendaftaran/{id}/tolak` | alasan (wajib) → notifikasi |
| POST | `/admin/pendaftaran/{id}/perlu-dilengkapi` | catatan (wajib) → status `perlu_dilengkapi` + notifikasi "Mohon lengkapi data pendaftaran"; hanya dari `menunggu` / `perlu_dilengkapi` (mengganti catatan) |
| POST | `/admin/pendaftaran/{id}/status` | `selesai` / `tidak_hadir` / `batal`, hanya dari `dijadwalkan` |
| POST | `/admin/pendaftaran/{id}/ingatkan` | notifikasi pengingat; `422` bila belum dijadwalkan |
| POST | `/admin/pengajuan/{id}/setujui` | jadwal_ulang → jadwal dipindah (kuota dicek lagi dengan lock; `422 jam` bila sudah penuh) + notifikasi "Pengajuan jadwal ulang disetujui"; batal → status `batal` + notifikasi. `422` bila pengajuan sudah diputuskan |
| POST | `/admin/pengajuan/{id}/tolak` | alasan (wajib) → notifikasi ke pasien; pendaftaran tidak berubah |
| GET | `/admin/kalender?dari=&sampai=` | `{data: {"2026-11-13": 9, …}}` sisa kuota slot aktif; bawaan besok s.d. 6 bulan |
| GET | `/admin/slot?tanggal=` | `{data:[{jam,kuota,aktif,terisi,sisa}], pasien:[{id,nama,jam,nomor_antrean}]}` (pasien urut nomor antrean) |
| POST | `/admin/slot` | tanggal, jam, kuota → `201` |
| PATCH | `/admin/slot` | tanggal, jam, kuota? (≥ terisi), aktif? → `204` |
| DELETE | `/admin/slot?tanggal=&jam=` | `204`; `422` bila berisi pasien |
| POST | `/admin/slot/massal` | mulai, sampai (≤730 hari), hari[] (0=Min), jam[], kuota → `{baru, sudah_ada}` |
| GET | `/admin/chat` | `[{pasien: User, terakhir: Pesan, belum_dibaca}]` |
| GET | `/admin/chat/{userId}?after=` | pesan + `belum_dibaca`, `mengetik` (pasien), `dibaca_hingga` (pesan admin) |
| POST | `/admin/chat/{userId}` | isi → `201` + notifikasi ke pasien |
| POST | `/admin/chat/{userId}/dibaca` | `204` |
| POST | `/admin/chat/{userId}/mengetik` | `aktif` · `204` (panel web memakai route web `chat.mengetik` yang sama fungsinya) |
| GET | `/admin/pasien?q=&page=` | berhalaman (25) |
| PATCH | `/admin/pasien/{id}` | aktif (nonaktif = token pasien dicabut) |
| POST | `/admin/pasien/{id}/reset-sandi` | `{sandi}` 6 angka, tampilkan sekali untuk dikirim lewat WA |
| GET | `/admin/media-sosial` | semua + daftar `platform` |
| PUT | `/admin/media-sosial` | `data:[{platform,nama,url,aktif}]` seluruh daftar; URL wajib `https://` → `204` |
| PUT | `/admin/info-klinik` | semua kolom info klinik (Maps & website wajib `https://`, WA angka/spasi/+/-) → `204` |
| POST | `/admin/gambar/{jenis}` | multipart `gambar` (jpg/png/webp, maks. 2 MB) → `{data:{url}}`; berkas lama dihapus |
| DELETE | `/admin/gambar/{jenis}` | kembali ke gambar bawaan · `204` |

## Tabel (MySQL)
- `users` (id, name, username, no_hp, email, password, role, aktif, fcm_token, timestamps)
- `pendaftaran` (id, user_id, nama, umur, alamat, no_hp, keluhan, status (≤20), tanggal, jam, nomor_antrean, dijadwalkan_at, diingatkan_untuk, alasan, catatan, dilengkapi_at, timestamps)

## Nomor antrean (`AntreanService`)
- Per tanggal, urut `dijadwalkan_at` (siapa yang lebih dulu dijadwalkan admin). Pindah jam di tanggal
  yang sama tetap di posisinya; pindah tanggal masuk paling belakang di tanggal baru.
- Yang dihitung: `dijadwalkan`, `selesai`, `tidak_hadir` (nomor tidak bergeser di hari praktik).
- Batal / ditolak / pindah tanggal → nomor disusun ulang; pasien terjadwal yang nomornya berubah
  mendapat notifikasi "Nomor antrean diperbarui". Notifikasi jadwal & pengingat menyertakan nomor.
- `media` (id, pendaftaran_id, jenis[kondisi|ktp], path, mime, ukuran) — berkas di `storage/app/private`
- `slot` (id, tanggal, jam, kuota, aktif) — unik (tanggal, jam)
- `pengajuan` (id, pendaftaran_id, jenis[jadwal_ulang|batal], tanggal, jam, alasan, status[menunggu|disetujui|ditolak], alasan_tolak, diputuskan_at, timestamps).
  Pengajuan menunggu otomatis ditutup (ditolak, tanpa notifikasi) bila admin menolak pendaftaran atau menandai Selesai/Tidak hadir/Batal.
- `pesan` (id, pasien_id, dari_admin, isi, dibaca_at, created_at)
- `notifikasi` (id, user_id, judul, isi, dibaca_at, created_at)
- `media_sosial` (id, platform, nama, url, aktif, urutan)
- `pengaturan` (id, kunci, nilai) — info klinik; kunci yang belum disimpan memakai nilai bawaan klien
- `personal_access_tokens` (Sanctum)

## Server (staging & produksi)
- PHP **8.3+** (composer.lock memuat paket yang mensyaratkan 8.3).
- `upload_max_filesize` ≥ 40M dan `post_max_size` ≥ 80M (5 foto + 1 video + KTP sekali kirim).
- Cloudflare: bila aplikasi mendapat `403` HTML, buat aturan lewati challenge untuk `/arulsageni.com/api/*`.
- Di balik Cloudflare Tunnel server membaca IP asli pengunjung dari `X-Forwarded-For` (proxy dipercaya di
  `bootstrap/app.php`), jadi batas 60/menit berlaku per pengunjung. Langkah pasang live lengkap: `DEPLOY.md` di repo server.
- **Cron** (cPanel → Cron Jobs, tiap menit):
  `* * * * * cd /path/ke/arulsageni-dashboard && php artisan schedule:run >> /dev/null 2>&1`
  Menjalankan `pengingat:kirim` tiap hari 08.00 WIB: notifikasi "Pengingat jadwal berobat" ke pasien
  berstatus dijadwalkan untuk besok. Kolom `diingatkan_untuk` mencegah dobel; jadwal yang dipindah
  diingatkan lagi. Uji manual: `php artisan pengingat:kirim`.
- **Push FCM**: unggah file service account Firebase ke `storage/app/firebase.json` (di luar `public/`,
  tidak di-commit) atau isi `FCM_KREDENSIAL` di `.env` dengan path-nya. File tidak ada = push nonaktif,
  notifikasi tetap tersimpan. Pengiriman gagal dicatat di `storage/logs` ("FCM gagal"); token `UNREGISTERED`
  (aplikasi di-uninstall) dihapus otomatis. Satu akun = satu HP (HP terakhir yang masuk).

## Belum dibuat
- (Diputuskan tidak dibuat: hapus media lama otomatis.)
