/// Konfigurasi global aplikasi.
class AppConfig {
  AppConfig._();

  /// Alamat API Laravel di hosting klien.
  static const apiBaseUrl = 'https://arulsageni.com/api/v1';

  /// `true` = pakai data contoh di memori (belum terhubung ke server).
  /// Ganti ke `false` setelah ApiRepository dan API Laravel siap.
  static const useMock = true;
}
