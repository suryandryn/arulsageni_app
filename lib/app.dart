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
import 'state/session.dart';

class PadepokanApp extends StatelessWidget {
  const PadepokanApp({super.key, this.repository});

  /// Bisa diisi untuk pengujian; bawaan memakai [MockRepository].
  final Repository? repository;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // TODO(api): ganti dengan ApiRepository bila AppConfig.useMock == false.
        ChangeNotifierProvider<Repository>(create: (_) => repository ?? MockRepository()),
        ChangeNotifierProvider<Session>(create: (ctx) => Session(ctx.read<Repository>())),
      ],
      child: MaterialApp(
        title: Klinik.nama,
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        locale: const Locale('id'),
        supportedLocales: const [Locale('id'), Locale('en')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: const _Gerbang(),
      ),
    );
  }
}

/// Menentukan layar awal berdasarkan sesi & peran.
class _Gerbang extends StatelessWidget {
  const _Gerbang();

  @override
  Widget build(BuildContext context) {
    final user = context.watch<Session>().user;
    if (user == null) return const MasukPage();
    return user.isAdmin ? const AdminShell() : const PasienShell();
  }
}
