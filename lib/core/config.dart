import 'package:flutter/foundation.dart';

/// Konfigurasi global aplikasi.
///
/// Pilih lingkungan saat menjalankan:
/// ```
/// flutter run                                  # debug: server Laravel di laptop (emulator)
/// flutter run --dart-define=API_URL=http://192.168.x.x:8000/api/v1   # HP satu WiFi dengan laptop
/// flutter run --dart-define=ENV=mock           # data contoh di memori, tanpa server
/// flutter run --dart-define=ENV=staging        # velocitydatacenter.biz
/// flutter build apk                            # rilis: produksi
/// ```
class AppConfig {
  AppConfig._();

  static const _env = String.fromEnvironment('ENV');
  static const _apiUrl = String.fromEnvironment('API_URL');

  /// `mock` | `lokal` | `staging` | `produksi`. Bawaan: rilis = produksi, debug = lokal
  /// (aplikasi & panel web lokal memakai database yang sama).
  static String get env => _env.isNotEmpty ? _env : (kReleaseMode ? 'produksi' : 'lokal');

  /// `true` = pakai data contoh di memori (tanpa server).
  static bool get useMock => env == 'mock';

  /// Alamat API Laravel.
  static String get apiBaseUrl {
    if (_apiUrl.isNotEmpty) return _apiUrl;
    return switch (env) {
      // 10.0.2.2 = laptop, dilihat dari emulator Android.
      'lokal' => 'http://10.0.2.2:8000/api/v1',
      'staging' => 'https://velocitydatacenter.biz/arulsageni.com/api/v1',
      _ => 'https://arulsageni.com/api/v1',
    };
  }
}
