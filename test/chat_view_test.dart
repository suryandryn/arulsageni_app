import 'package:arulsageni/data/mock_repository.dart';
import 'package:arulsageni/data/repository.dart';
import 'package:arulsageni/features/chat/chat_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

class _RepoUji extends MockRepository {
  final sinyal = <bool>[];

  @override
  Future<void> kirimMengetik(String pasienId, {required bool aktif}) async => sinyal.add(aktif);
}

void main() {
  setUpAll(() => initializeDateFormatting('id_ID'));

  testWidgets('chat admin: centang dibaca, animasi mengetik, emoji, sinyal mengetik', (tester) async {
    final repo = _RepoUji();
    await tester.pumpWidget(ChangeNotifierProvider<Repository>.value(
      value: repo,
      child: const MaterialApp(home: Scaffold(body: ChatView(pasienId: '2', sebagaiAdmin: true))),
    ));
    await tester.pumpAndSettle();

    // Pesan sambutan admin ke Siti sudah dibaca → centang dua.
    expect(find.byIcon(Icons.done_all), findsOneWidget);
    expect(find.byIcon(Icons.done), findsNothing);

    // Pasien mulai mengetik → gelembung tiga titik muncul tanpa memuat ulang daftar.
    repo.lawanMengetik('2').value = true;
    await tester.pump();
    expect(find.bySemanticsLabel('Pasien sedang mengetik'), findsOneWidget);
    repo.lawanMengetik('2').value = false;
    await tester.pump();
    expect(find.bySemanticsLabel('Pasien sedang mengetik'), findsNothing);

    // Emoji disisipkan ke kolom pesan; mengetik mengirim sinyal sekali (dibatasi 3 detik).
    await tester.tap(find.byTooltip('Emoji'));
    await tester.pump();
    await tester.tap(find.text('😊'));
    await tester.tap(find.text('🙏'));
    await tester.pump();
    expect(find.text('😊🙏'), findsOneWidget);
    expect(repo.sinyal, [true]);

    // Kirim → pesan baru belum dibaca pasien (centang satu), panel tetap bisa ditutup.
    await tester.tap(find.byTooltip('Kirim'));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.done), findsOneWidget);
    expect(repo.sinyal, [true], reason: 'server menghapus status mengetik saat pesan terkirim');

    // Mengetik lalu menghapus → sinyal berhenti.
    await tester.enterText(find.byType(TextField), 'Halo');
    await tester.enterText(find.byType(TextField), '');
    expect(repo.sinyal, [true, true, false]);

    await tester.pumpWidget(const SizedBox());
  });
}
