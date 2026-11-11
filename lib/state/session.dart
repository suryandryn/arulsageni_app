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

  Future<void> login(String identitas, String password) async {
    _user = await _repo.login(identitas, password);
    notifyListeners();
  }

  Future<void> register({required String nama, required String noWa, required String password}) async {
    _user = await _repo.register(nama: nama, noWa: noWa, password: password);
    notifyListeners();
  }

  Future<void> logout() async {
    await _repo.logout();
    _user = null;
    notifyListeners();
  }
}
