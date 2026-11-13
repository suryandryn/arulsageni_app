/// Identitas padepokan yang tetap (diatur saat pembuatan aplikasi).
///
/// Alamat, Google Maps, WA admin, biaya, website, dan kalimat jadwal diatur admin:
/// lihat [InfoKlinik] (models.dart) dan `Repository.infoKlinik()`.
class Klinik {
  Klinik._();

  static const nama = 'Padepokan Arul Sageni';
  static const pemilik = 'Kang Arul Sageni';
  static const foto = 'assets/images/kang_arul.jpeg';
}
