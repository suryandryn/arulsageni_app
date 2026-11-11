# Spesifikasi Aplikasi — Padepokan Arul Sageni

Sumber: `reference/Rangkuman-Aplikasi-Android-Konsep-Pengobatan.docx` dan
`reference/FORM APK (G) CUSTOM.doc`. Dokumen ini adalah ringkasan kerja; bila
ada perbedaan, dokumen referensi klien yang berlaku.

## Tujuan
Aplikasi Android untuk pendaftaran berobat dan janji temu, menggantikan
pendaftaran lewat WhatsApp. Jadwal tersimpan di server (akun pasien), tetap
terlihat walau pasien ganti HP.

## Identitas
| Item | Nilai |
|---|---|
| Nama aplikasi | Padepokan Arul Sageni |
| Domain | arulsageni.com |
| Package name | `com.arulsageni.app` |
| Pemilik | Kang Arul Sageni |
| Alamat | Kp. Curug Rendeng RT 13 RW 04, Subang, Jawa Barat 41281 |
| WA admin resmi | 0895 2203 3857 |
| Warna | Hijau & putih (final menyesuaikan logo) |
| Minimum Android | 8.0 (API 26) |
| Referensi desain | https://velocity.ai.id/preview/aplikasi-janji-pengobatan-958cad/ |

## Peran
- **Pasien**: daftar akun, daftar berobat, lihat status & jadwal, jadwal ulang /
  batal, chat admin, lihat info klinik.
- **Admin klinik**: menilai pendaftar, memberi jadwal, minta data dilengkapi,
  menolak, chat & WhatsApp pasien, mengatur info klinik dan jadwal praktik.

## Status pendaftaran / janji
```
menunggu_verifikasi ──▶ perlu_dilengkapi ──▶ (pasien melengkapi) ──▶ menunggu_verifikasi
        │
        ├──▶ tidak_dapat_ditangani
        └──▶ terjadwal ──▶ selesai
                     ├──▶ tidak_hadir
                     └──▶ dibatalkan / (jadwal ulang ──▶ menunggu_verifikasi)
```

## Formulir Daftar Berobat
- Nama, nomor WhatsApp, kota, keluhan
- Foto/video kondisi pasien — **wajib**
- Foto KTP — dengan peringatan **NIK harus ditutup**
- Foto KTP & foto/video kondisi hanya bisa dilihat admin

## Menu Pasien
| Menu | Isi |
|---|---|
| Beranda | Janji terdekat + hitung mundur, tombol Daftar Berobat, pintasan alamat & estimasi biaya |
| Daftar | Formulir pendaftaran |
| Janji | Daftar pendaftaran/janji + status, detail, jadwal ulang, batal |
| Chat | Chat teks dengan admin |
| Notifikasi | Jadwal, pengingat, pesan klinik |
| Info | Foto Kang Arul Sageni, alamat, Google Maps, WA admin, estimasi biaya, media sosial, data pasien, keluar |

## Menu Admin
| Menu | Isi |
|---|---|
| Ringkas | Jumlah pendaftar menunggu, jadwal besok, total terdaftar, chat terbaru |
| Pendaftar | Filter status, detail, media, tombol WA & Chat, beri jadwal, minta dilengkapi, tidak dapat ditangani |
| Jadwal | Jadwal per tanggal + kuota terisi, tandai Selesai / Tidak hadir |
| Atur | Info klinik, kuota/hari, hari & jam praktik, pilihan jam janji, periode jadwal (perpanjang 1/2 tahun), tanggal khusus/libur |

## Aturan jadwal
- Nomor antrean otomatis per tanggal.
- Tanggal penuh (kuota habis), libur, atau di luar periode tidak bisa dipilih.
- Periode jadwal dibuka oleh admin (mis. 2 tahun) dan bisa diperpanjang dari aplikasi.

## Estimasi biaya (ditampilkan di aplikasi)
- Pendaftaran Rp10.000, bayar di tempat
- Pengobatan seikhlasnya untuk Kang Arul Sageni
- Obat & vitamin Rp600.000 untuk segala macam penyakit medis/non-medis (6 produk)
- Semua dibayar di tempat saat pengobatan

## Media sosial
| Platform | Nama | Link |
|---|---|---|
| YouTube | PAGADEN PROJECT | https://youtube.com/@pagadenprojects |
| Facebook | PAGADEN PROJECT | https://www.facebook.com/share/1F7NfuC6So/ |
| TikTok | PAGADEN PROJECT | https://www.tiktok.com/@pagaden_project |
| TikTok | KANG ARUL SAGENI | https://www.tiktok.com/@kang_arul_sageni |
| Instagram | RULZ_357 | https://www.instagram.com/rulz_357 |
| Snack Video | PAGADEN PROJECT | https://s.snackvideo.com/u/@Pagaden_Project/lvdG7xjf |

Website terkait: pengobatankangarulsageni.com (diminta dimasukkan ke aplikasi).

## Di luar cakupan
Rekam medis, resep, kasir, BPJS, pembayaran online, pengiriman WhatsApp
otomatis (tombol WA hanya membuka aplikasi WhatsApp di HP admin).

## Data yang masih ditunggu dari klien
- [ ] Logo (PNG, min. 1024×1024)
- [ ] Alamat lengkap tertulis untuk aplikasi + link Google Maps
- [ ] Hari & jam praktik, kuota pasien per hari
- [ ] Email akun admin
- [ ] Deskripsi singkat & lengkap untuk Play Store, kategori aplikasi
- [ ] Akses cPanel (username) untuk pemasangan API
