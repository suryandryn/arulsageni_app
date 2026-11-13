import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Tempat menyimpan token & data pengguna agar tetap masuk setelah aplikasi ditutup.
abstract class PenyimpanSesi {
  Future<String?> baca(String kunci);
  Future<void> tulis(String kunci, String nilai);
  Future<void> hapusSemua();
}

/// Android Keystore (terenkripsi).
class PenyimpanAman implements PenyimpanSesi {
  const PenyimpanAman();

  static const _s = FlutterSecureStorage();

  @override
  Future<String?> baca(String kunci) => _s.read(key: kunci);

  @override
  Future<void> tulis(String kunci, String nilai) => _s.write(key: kunci, value: nilai);

  @override
  Future<void> hapusSemua() => _s.deleteAll();
}

/// Untuk pengujian.
class PenyimpanMemori implements PenyimpanSesi {
  final data = <String, String>{};

  @override
  Future<String?> baca(String kunci) async => data[kunci];

  @override
  Future<void> tulis(String kunci, String nilai) async => data[kunci] = nilai;

  @override
  Future<void> hapusSemua() async => data.clear();
}
