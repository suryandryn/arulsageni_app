import 'package:flutter/foundation.dart';

import '../data/repository.dart';
import '../models/models.dart';

/// Menyimpan pengguna yang sedang masuk. Token disimpan oleh [Repository]
/// (ApiRepository: flutter_secure_storage), jadi tetap masuk setelah aplikasi ditutup.
class Session extends ChangeNotifier {
  Session(this._repo, {AppUser? awal}) : _user = awal {
    // Server menolak token (dikeluarkan admin / akun nonaktif) → kembali ke layar Masuk.
    _repo.onSesiBerakhir = () {
      if (_user == null) return;
      _user = null;
      notifyListeners();
    };
  }

  final Repository _repo;
  AppUser? _user;

  AppUser? get user => _user;

  Future<void> masukPasien(String noHp, String sandi) async {
    _user = await _repo.loginPasien(noHp, sandi);
    notifyListeners();
  }

  Future<void> masukAdmin(String username, String sandi) async {
    _user = await _repo.loginAdmin(username, sandi);
    notifyListeners();
  }

  Future<void> daftarAkun({required String nama, required String noHp, required String sandi}) async {
    _user = await _repo.daftarAkun(nama: nama, noHp: noHp, sandi: sandi);
    notifyListeners();
  }

  /// Admin: simpan nama & email baru, lalu perbarui pengguna yang sedang masuk.
  Future<void> ubahProfilAdmin({required String nama, required String email}) async {
    _user = await _repo.ubahProfilAdmin(nama: nama, email: email);
    notifyListeners();
  }

  Future<void> keluar() async {
    await _repo.logout();
    _user = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _repo.onSesiBerakhir = null;
    super.dispose();
  }
}
