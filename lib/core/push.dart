import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../data/repository.dart';

/// Push notifikasi FCM untuk pasien (mode API saja; mode mock & pengujian tidak memakai Firebase).
///
/// Server mengirim push setiap kali membuat notifikasi (jadwal, pengingat H-1, chat admin, dst.).
/// Saat aplikasi tertutup/di latar, Android menampilkannya sendiri; saat terbuka, [aktifkan]
/// meneruskannya ke `onMasuk`. Data `jenis` (`notifikasi` | `chat`) menentukan layar yang dibuka.
class Push {
  Push._();

  static bool _siap = false;
  static final _langganan = <StreamSubscription<Object?>>[];

  /// Dipanggil sekali di `main()`. Gagal (mis. tanpa Google Play Services) = push nonaktif.
  static Future<void> init() async {
    try {
      await Firebase.initializeApp();
      _siap = true;
    } catch (e) {
      debugPrint('Push nonaktif: $e');
    }
  }

  /// Mulai menerima push untuk pasien yang sedang masuk: minta izin (Android 13+),
  /// kirim token ke server, dan dengarkan pesan. Aman dipanggil berulang.
  static Future<void> aktifkan({
    required Repository repo,
    required void Function(String judul, String isi, String jenis) onMasuk,
    required void Function(String jenis) onBuka,
  }) async {
    if (!_siap) return;
    await nonaktifkan();
    final fm = FirebaseMessaging.instance;
    String jenis(RemoteMessage m) => m.data['jenis'] as String? ?? 'notifikasi';

    _langganan
      ..add(FirebaseMessaging.onMessage.listen((m) {
        final n = m.notification;
        if (n != null) onMasuk(n.title ?? '', n.body ?? '', jenis(m));
      }))
      ..add(FirebaseMessaging.onMessageOpenedApp.listen((m) => onBuka(jenis(m))))
      // getToken/onTokenRefresh sengaja dipakai walau ditandai usang di firebase_messaging 17:
      // penggantinya (register/onRegistered) memberi Installation ID, bukan token registrasi
      // yang diterima kolom `message.token` FCM HTTP v1 di server.
      // ignore: deprecated_member_use
      ..add(fm.onTokenRefresh.listen((t) => _kirimToken(repo, t)));

    try {
      // Aplikasi dibuka dari notifikasi saat sebelumnya tertutup penuh.
      final awal = await fm.getInitialMessage();
      if (awal != null) onBuka(jenis(awal));
      await fm.requestPermission();
      // ignore: deprecated_member_use
      final token = await fm.getToken();
      if (token != null) await _kirimToken(repo, token);
    } catch (e) {
      // Offline / layanan Google tidak tersedia: dicoba lagi saat aplikasi dibuka berikutnya.
      debugPrint('Token push gagal: $e');
    }
  }

  /// Berhenti mendengarkan (pasien keluar). Token di server dihapus oleh endpoint keluar.
  static Future<void> nonaktifkan() async {
    for (final s in _langganan) {
      await s.cancel();
    }
    _langganan.clear();
  }

  static Future<void> _kirimToken(Repository repo, String token) async {
    try {
      await repo.kirimTokenPerangkat(token);
    } catch (e) {
      debugPrint('Kirim token push gagal: $e');
    }
  }
}
