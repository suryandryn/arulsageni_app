import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/klinik.dart';
import 'core/theme.dart';
import 'data/mock_repository.dart';
import 'data/repository.dart';
import 'features/admin/admin_shell.dart';
import 'features/auth/masuk_page.dart';
import 'features/pasien/pasien_shell.dart';
import 'models/models.dart';
import 'state/session.dart';

class PadepokanApp extends StatelessWidget {
  const PadepokanApp({super.key, this.repository, this.userAwal});

  /// Diisi oleh `main()` (Mock / Api sesuai AppConfig); bawaan [MockRepository] untuk pengujian.
  final Repository? repository;

  /// Pengguna dari sesi tersimpan, agar langsung masuk.
  final AppUser? userAwal;

  static final _navigator = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<Repository>(create: (_) => repository ?? MockRepository()),
        ChangeNotifierProvider<Session>(create: (ctx) => Session(ctx.read<Repository>(), awal: userAwal)),
      ],
      child: MaterialApp(
        navigatorKey: _navigator,
        title: Klinik.nama,
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        locale: const Locale('id'),
        supportedLocales: const [Locale('id'), Locale('en')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: _Gerbang(navigator: _navigator),
      ),
    );
  }
}

/// Menentukan layar awal berdasarkan sesi & peran.
class _Gerbang extends StatefulWidget {
  const _Gerbang({required this.navigator});
  final GlobalKey<NavigatorState> navigator;

  @override
  State<_Gerbang> createState() => _GerbangState();
}

class _GerbangState extends State<_Gerbang> {
  AppUser? _sebelum;

  @override
  Widget build(BuildContext context) {
    final user = context.watch<Session>().user;
    // Keluar (termasuk sesi berakhir dari server) saat ada layar lain di atas: tutup semuanya.
    if (_sebelum != null && user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => widget.navigator.currentState?.popUntil((r) => r.isFirst));
    }
    _sebelum = user;
    if (user == null) return const MasukPage();
    return user.isAdmin ? const AdminShell() : const PasienShell();
  }
}
