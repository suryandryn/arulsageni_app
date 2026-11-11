import 'package:arulsageni/app.dart';
import 'package:arulsageni/widgets/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() => initializeDateFormatting('id_ID'));

  Future<void> tunggu(WidgetTester t) async {
    for (var i = 0; i < 5; i++) {
      await t.pump(const Duration(milliseconds: 200));
    }
  }

  /// Habiskan timer toast (3,8 detik) sebelum tes selesai.
  Future<void> habiskanToast(WidgetTester t) => t.pump(const Duration(seconds: 5));

  Finder nav(String label) => find.descendant(of: find.byType(NavBawah), matching: find.text(label));

  testWidgets('pasien demo masuk, melihat jadwal, lalu membuka Info', (tester) async {
    await tester.pumpWidget(const PadepokanApp());
    expect(find.text('Padepokan Arul Sageni'), findsOneWidget);
    expect(find.text('Demo: data masuk sudah terisi.'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Masuk'));
    await tunggu(tester);

    expect(find.text('Halo, Siti'), findsOneWidget);
    expect(find.text('Jadwal berobat - Siti Rahmawati'), findsOneWidget);
    expect(find.text('JADWAL BEROBAT (SITI RAHMAWATI)'), findsOneWidget);

    await tester.tap(nav('Info'));
    await tunggu(tester);
    expect(find.text('Buka Google Maps'), findsOneWidget);
  });

  testWidgets('sandi salah menampilkan pemberitahuan', (tester) async {
    await tester.pumpWidget(const PadepokanApp());
    await tester.enterText(find.byType(TextField).at(1), 'salah');
    await tester.tap(find.widgetWithText(FilledButton, 'Masuk'));
    await tunggu(tester);

    expect(find.text('Gagal masuk'), findsOneWidget);
    expect(find.text('Nomor HP atau sandi salah.'), findsOneWidget);
    await habiskanToast(tester);
  });

  testWidgets('admin masuk ke Beranda Admin dan membuka Pendaftaran', (tester) async {
    await tester.pumpWidget(const PadepokanApp());
    await tester.tap(find.text('Admin'));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Masuk Admin'));
    await tunggu(tester);

    expect(find.text('Beranda Admin'), findsOneWidget);
    expect(find.text('Pendaftaran menunggu'), findsOneWidget);

    await tester.tap(nav('Pendaftaran'));
    await tunggu(tester);
    expect(find.text('Hendra Wijaya'), findsOneWidget);
    expect(find.text('Ibu Marni'), findsOneWidget);
  });
}
