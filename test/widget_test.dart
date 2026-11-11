import 'package:arulsageni/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() => initializeDateFormatting('id_ID'));

  testWidgets('Layar masuk tampil, pasien demo bisa masuk ke Beranda', (tester) async {
    await tester.pumpWidget(const PadepokanApp());
    expect(find.text('Padepokan Arul Sageni'), findsOneWidget);
    expect(find.text('Masuk'), findsWidgets);

    await tester.enterText(find.byType(TextFormField).at(0), '081234567890');
    await tester.enterText(find.byType(TextFormField).at(1), '123456');
    await tester.tap(find.widgetWithText(FilledButton, 'Masuk'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Halo, Budi 👋'), findsOneWidget);
    expect(find.text('Janji berobat terdekat'), findsOneWidget);
  });

  testWidgets('Kata sandi salah menampilkan pesan galat', (tester) async {
    await tester.pumpWidget(const PadepokanApp());
    await tester.enterText(find.byType(TextFormField).at(0), '081234567890');
    await tester.enterText(find.byType(TextFormField).at(1), 'salah');
    await tester.tap(find.widgetWithText(FilledButton, 'Masuk'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Nomor WhatsApp atau kata sandi salah.'), findsOneWidget);
  });

  testWidgets('Admin masuk ke menu Ringkas', (tester) async {
    await tester.pumpWidget(const PadepokanApp());
    await tester.enterText(find.byType(TextFormField).at(0), 'admin');
    await tester.enterText(find.byType(TextFormField).at(1), 'admin123');
    await tester.tap(find.widgetWithText(FilledButton, 'Masuk'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Admin • Ringkas'), findsOneWidget);
    expect(find.text('Menunggu verifikasi'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
  });
}
