import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'core/config.dart';
import 'core/push.dart';
import 'data/api_repository.dart';
import 'data/mock_repository.dart';
import 'data/repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID');

  final Repository repo = AppConfig.useMock ? MockRepository() : ApiRepository(baseUrl: AppConfig.apiBaseUrl);
  if (!AppConfig.useMock) await Push.init();
  // Baca sesi tersimpan (lokal, cepat) agar pengguna langsung masuk tanpa layar Masuk.
  final user = await repo.pulihkanSesi();

  runApp(PadepokanApp(repository: repo, userAwal: user));
}
