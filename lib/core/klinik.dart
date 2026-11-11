/// Info padepokan yang tetap (diatur saat pembuatan aplikasi, bukan oleh admin).
/// Teks biaya persis kiriman klien.
class Klinik {
  Klinik._();

  static const nama = 'Padepokan Arul Sageni';
  static const pemilik = 'Kang Arul Sageni';
  static const foto = 'assets/images/kang_arul.jpeg';
  static const alamat =
      'RT.013/RW.004, Kampung Curug Rendeng, Kec. Jalan Cagak, Kabupaten Subang, Jawa Barat 41281';
  static const maps = 'https://maps.app.goo.gl/uvurN77g3fJBCdNa6';
  static const waAdmin = '0895 2203 3857';
  static const website = 'https://pengobatankangarulsageni.com';

  static const biaya = [
    'Untuk pendaftaran 10 rb bayar di tempat',
    'Pengobatan Se iklasnya Untuk Kang Arul Sageni',
    'Untuk Obatnya dan vitaminnya nanti di Harga 600rb untuk Segala Macam penyakit Medis non Medis dapat (6 Produk)',
  ];
  static const biayaAkhir = 'Semuanya bayar di tempat Saat Pengobatan';

  /// Pesan arahan yang tampil di bawah kartu jadwal (teks klien).
  static List<String> arahanJadwal(String tanggalKapital) => [
        '$tanggalKapital JAM 04.00 PAGI SUDAH HARUS DI LOKASI KARENA PENDAFTARAN DI TUTUP (JAM 8 PAGI) '
            'JANGAN SAMPAI ANDA TIDAK MENDAPTKAN ANTRIAN',
        'SILAHKAN DATANG TEPAT WAKTU SESUAI JADWAL YANG SUDAH DI TENTUKAN🙏 JANGAN SAMPAI TELAT.',
        'KALAU BISA DATANG LEBIH AWAL LEBIH BAIK JANGAN KHAWATIR KAMI SUDAH SEDIAKAN PENGINAPAN GRATIS '
            'UNTUK PASIEN ISTIRAHAT. TERIMAKASIH SALAM SEHAT UNTUK SEMUA☺️🙏',
      ];
}
