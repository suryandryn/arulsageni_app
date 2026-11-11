# Spesifikasi Aplikasi — Padepokan Arul Sageni

Sumber, berurutan dari yang paling berlaku:
1. **Demo desain** yang disetujui: https://velocity.ai.id/preview/aplikasi-janji-pengobatan-958cad/
   (tampilan, alur, dan teks mengikuti demo ini)
2. `reference/Rangkuman-Aplikasi-Android-Konsep-Pengobatan.docx`
3. `reference/FORM APK (G) CUSTOM.doc`

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
| Alamat | RT.013/RW.004, Kampung Curug Rendeng, Kec. Jalan Cagak, Kabupaten Subang, Jawa Barat 41281 |
| Google Maps | https://maps.app.goo.gl/uvurN77g3fJBCdNa6 |
| WA admin resmi | 0895 2203 3857 |
| Website | https://pengobatankangarulsageni.com |
| Minimum Android | 8.0 (API 26) |

## Desain (dari demo)
| Token | Nilai |
|---|---|
| Hijau utama | `#2F5D3A` (ditekan `#244A2E`) |
| Aksen emas | `#B8892B` |
| Latar krem | `#F7F3EA`, kartu putih, garis `#E4DDCD` |
| Teks | `#1F2A22`, redup `#5B665E` |
| Peringatan | latar `#FFF4D6`, teks `#7A5200` |
| Merah / OK / WhatsApp | `#B3261E` / `#2E7D4F` / `#25D366` |
| Font | Judul **Lora** 600/700, isi **Plus Jakarta Sans** 400–700 (dipaketkan di `assets/fonts`) |
| Bentuk | Kartu sudut 16, tombol sudut 10 tinggi 48, isian sudut 6, pil bulat |

Token ada di `lib/core/theme.dart`; komponen (kartu, tombol, tag, pil, header,
nav bawah, toast) di `lib/widgets/ui.dart`.

## Peran & menu
**Pasien** — nav bawah: Beranda · Daftar · Chat · Info · Profil (+ tombol "Notif" di header bila ada yang baru)

| Menu | Isi |
|---|---|
| Masuk | Foto Kang Arul, tab Pasien/Admin, nomor HP + sandi, "Daftar akun" |
| Beranda | Kartu jadwal terdekat (H-n, Buka Google Maps) + arahan kedatangan, tombol Daftar Berobat, daftar "Pendaftaran saya" |
| Daftar | Semua pendaftaran akun (satu akun bisa mendaftarkan anggota keluarga) |
| Detail | Kartu jadwal, data, alasan bila ditolak, foto/video, "Tanya admin lewat chat" |
| Daftar Berobat | Nama, umur, nomor HP, alamat, keluhan, foto/video kondisi (wajib), foto KTP (wajib) + peringatan & centang "NIK sudah ditutup" |
| Chat | Chat teks dengan admin |
| Info | Foto & alamat, Google Maps, WA admin, estimasi biaya, website, media sosial |
| Profil | Data akun, ubah sandi, notifikasi, keluar |

**Admin** — nav bawah: Beranda · Pendaftaran · Jadwal · Chat · Atur

| Menu | Isi |
|---|---|
| Beranda | Pendaftaran menunggu, jadwal hari praktik berikutnya, sisa kuota 30 hari, chat belum dibaca |
| Pendaftaran | Cari nama/nomor, filter status; detail: data, media, KTP, WhatsApp & Chat, **Beri/Pindah jadwal** (kalender + jam bersisa kuota), **Tolak** dengan alasan, kirim pengingat, Selesai / Tidak hadir / Batal |
| Jadwal | Kalender bulanan (sisa kuota per tanggal); per tanggal: slot jam, kuota, aktif/nonaktif, hapus, tambah jam; **buat slot massal** (rentang ≤ 24 bulan, hari praktik, jam, kuota per jam) |
| Chat | Daftar percakapan + jumlah pesan baru; ruang chat dengan tombol WhatsApp |
| Atur | Data pasien (reset sandi, aktif/nonaktif), Media sosial (tambah, ubah, urutkan, aktif/nonaktif, hapus), keluar |

## Status pendaftaran
```
Menunggu ──▶ Dijadwalkan ──▶ Selesai
   │              ├──▶ Tidak hadir
   │              └──▶ Batal
   └──▶ Ditolak (alasan wajib, dikirim ke pasien)
```

## Aturan jadwal (slot)
- Jadwal dibuka per **slot = tanggal + jam**, masing-masing dengan kuota.
- Slot dibuat massal oleh admin (mis. Sen–Sab, 08.00/10.00/13.00/15.00, kuota 3, 2 tahun).
  Slot yang sudah ada dilewati. Untuk periode berikutnya, ulangi dengan tanggal mulai baru.
- Tanggal bisa dipilih bila setelah hari ini, punya slot aktif, dan sisa kuota > 0.
- Kuota slot tidak boleh di bawah jumlah pasien terjadwal; slot berisi tidak bisa dihapus (nonaktifkan saja).
- Libur = nonaktifkan / hapus slot tanggal itu.

## Batas berkas
Foto jpg/png maks. 5 MB (maks. 5 berkas), video mp4 maks. 30 MB (1 berkas). Foto dikompres di HP.

## Info tetap (diatur saat pembuatan aplikasi)
Alamat, biaya, nomor admin, website ada di `lib/core/klinik.dart`. Teks estimasi
biaya dan arahan jadwal ("JAM 04.00 PAGI SUDAH HARUS DI LOKASI ...") persis teks klien.

## Perbedaan demo vs dokumen konsep (keputusan: ikut demo)
| Konsep (.docx) | Demo / aplikasi |
|---|---|
| Status "Perlu dilengkapi" & tombol "Minta dilengkapi" | Tidak ada — admin meminta lewat Chat/WhatsApp |
| Nomor antrean otomatis | Tidak ditampilkan; kuota per jam |
| Pasien mengajukan jadwal ulang / membatalkan | Tidak ada di demo — pasien menghubungi admin lewat chat |
| Admin mengatur alamat/biaya/nomor | Tetap di aplikasi; admin hanya mengatur media sosial |
| Kuota per hari, periode diperpanjang 1/2 tahun | Kuota per slot jam, slot massal ≤ 24 bulan |

## Di luar cakupan
Rekam medis, resep, kasir, BPJS, pembayaran online, pengiriman WhatsApp
otomatis (tombol WA hanya membuka aplikasi WhatsApp).

## Data yang masih ditunggu dari klien
- [ ] Logo (PNG, min. 1024×1024) untuk ikon aplikasi
- [ ] Email akun admin
- [ ] Deskripsi singkat & lengkap untuk Play Store, kategori aplikasi
- [ ] Akses cPanel (username) untuk pemasangan API
