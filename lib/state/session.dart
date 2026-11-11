import 'package:flutter/foundation.dart';

import '../data/repository.dart';
import '../models/models.dart';

/// Menyimpan pengguna yang sedang masuk.
// TODO(api): simpan token di flutter_secure_storage agar tetap masuk setelah aplikasi ditutup.
class Session extends ChangeNotifier {
  Session(this._repo);

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

  Future<void> keluar() async {
    await _repo.logout();
    _user = null;
    notifyListeners();
  }
}
