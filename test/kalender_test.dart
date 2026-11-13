import 'package:arulsageni/core/format.dart';
import 'package:arulsageni/widgets/kalender.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() => initializeDateFormatting('id_ID'));

  test('normalJam sama dengan server: jam 1 digit, titik atau titik dua', () {
    expect(normalJam('8:00'), '08.00');
    expect(normalJam(' 08.00 '), '08.00');
    expect(normalJam('13:05'), '13.05');
    expect(normalJam('24.00'), isNull);
    expect(normalJam('8.5'), isNull);
    expect(normalJam('jam 8'), isNull);
  });

  // 10 November 2026; tanggal 12 punya slot penuh (sisa 0), 13 masih ada sisa, 14 tanpa slot.
  final hariIni = DateTime(2026, 11, 10);
  final sisa = {DateTime(2026, 11, 12): 0, DateTime(2026, 11, 13): 2};

  Future<List<DateTime>> ketukSemua(WidgetTester tester, KalenderBulan Function(ValueChanged<DateTime>) buat) async {
    final dipilih = <DateTime>[];
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: SingleChildScrollView(child: buat(dipilih.add)))));
    for (final d in ['12', '13', '14']) {
      await tester.tap(find.text(d).first);
    }
    return dipilih;
  }

  testWidgets('pasien: hanya tanggal yang masih ada sisa', (tester) async {
    final dipilih = await ketukSemua(
      tester,
      (onPilih) => KalenderBulan(sisa: sisa, terpilih: null, wajibAdaSisa: true, hariIni: hariIni, onPilih: onPilih),
    );
    expect(dipilih, [DateTime(2026, 11, 13)]);
  });

  testWidgets('pindah jadwal: tanggal pasien sendiri tetap bisa dipilih walau penuh', (tester) async {
    final dipilih = await ketukSemua(
      tester,
      (onPilih) => KalenderBulan(
        sisa: sisa,
        terpilih: null,
        wajibAdaSisa: true,
        tanggalSendiri: DateTime(2026, 11, 12),
        hariIni: hariIni,
        onPilih: onPilih,
      ),
    );
    expect(dipilih, [DateTime(2026, 11, 12), DateTime(2026, 11, 13)]);
  });

  testWidgets('admin atur slot: tanggal tanpa slot juga bisa dibuka', (tester) async {
    final dipilih = await ketukSemua(
      tester,
      (onPilih) => KalenderBulan(sisa: sisa, terpilih: null, bebasPilih: true, hariIni: hariIni, onPilih: onPilih),
    );
    expect(dipilih, [DateTime(2026, 11, 12), DateTime(2026, 11, 13), DateTime(2026, 11, 14)]);
  });

  test('hMinus sama dengan panel web', () {
    final s = DateTime(2026, 11, 10, 15);
    expect(hMinus(DateTime(2026, 11, 13), sekarang: s), 'H-3');
    expect(hMinus(DateTime(2026, 11, 10), sekarang: s), 'Hari ini');
    expect(hMinus(DateTime(2026, 11, 9), sekarang: s), 'Sudah lewat');
  });

  testWidgets('admin: lompat langsung lewat dropdown bulan & tahun', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: KalenderBulan(
            sisa: sisa,
            terpilih: null,
            bebasPilih: true,
            pilihBulanTahun: true,
            hariIni: hariIni,
            onPilih: (_) {},
          ),
        ),
      ),
    ));
    expect(find.text('November'), findsOneWidget);
    expect(find.text('2026'), findsOneWidget);

    // Pindah ke 2027: tetap November.
    await tester.tap(find.text('2026'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('2027').last);
    await tester.pumpAndSettle();
    expect(find.text('2027'), findsOneWidget);
    expect(find.text('November'), findsOneWidget);

    // Pilih Oktober 2027 langsung (item menu yang jauh dari bulan aktif tidak dibangun di tes).
    await tester.tap(find.text('November'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Oktober').last);
    await tester.pumpAndSettle();
    expect(find.text('Oktober'), findsOneWidget);
    expect(find.text('31'), findsOneWidget, reason: 'Oktober punya 31 hari');
  });
}
