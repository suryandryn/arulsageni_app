import 'dart:convert';

import 'package:arulsageni/data/api_repository.dart';
import 'package:arulsageni/data/mock_repository.dart';
import 'package:arulsageni/data/penyimpan_sesi.dart';
import 'package:arulsageni/data/repository.dart';
import 'package:arulsageni/features/admin/info_klinik_page.dart';
import 'package:arulsageni/models/models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

void main() {
  setUpAll(() => initializeDateFormatting('id_ID'));

  test('kalimat jadwal: penanda tanggal diganti, baris kosong dilewati', () {
    const info = InfoKlinik(
      alamat: 'a',
      mapsUrl: 'https://m',
      waAdmin: '0812',
      biaya: 'Satu\n\n  Dua  ',
      websiteUrl: 'https://www.contoh.id/',
      jadwalBerobat: '{tanggal} DATANG JAM 4\n\nTERIMA KASIH',
    );
    expect(info.arahanJadwal('JUMAT 13 NOVEMBER 2026'), ['JUMAT 13 NOVEMBER 2026 DATANG JAM 4', 'TERIMA KASIH']);
    expect(info.poinBiaya, ['Satu', 'Dua']);
    expect(info.websiteNama, 'contoh.id');
  });

  test('API: info klinik dibaca tanpa login, disimpan admin dengan PUT', () async {
    final kiriman = <http.Request>[];
    final repo = ApiRepository(
      baseUrl: 'http://server/api/v1',
      penyimpan: PenyimpanMemori(),
      client: MockClient((req) async {
        kiriman.add(req);
        if (req.method == 'PUT') return http.Response('', 204);
        return http.Response(
          jsonEncode({
            'data': {
              'alamat': 'Subang',
              'maps_url': 'https://maps.app/x',
              'wa_admin': '0812',
              'biaya': 'A\nB',
              'biaya_catatan': '',
              'website_url': '',
              'website_keterangan': '',
              'jadwal_berobat': '{tanggal} PAGI',
              'penanda_tanggal': '{tanggal}',
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
    final info = await repo.infoKlinik();
    expect((info.alamat, info.websiteUrl), ('Subang', ''));
    expect(info.poinBiaya, ['A', 'B']);
    expect(kiriman.single.headers.containsKey('Authorization'), isFalse);

    var diberitahu = 0;
    repo.addListener(() => diberitahu++);
    await repo.simpanInfoKlinik(info);
    expect(kiriman.last.method, 'PUT');
    expect(kiriman.last.url.path, '/api/v1/admin/info-klinik');
    expect(jsonDecode(kiriman.last.body)['jadwal_berobat'], '{tanggal} PAGI');
    expect(diberitahu, 1);
  });

  testWidgets('admin mengubah info klinik di aplikasi', (tester) async {
    final repo = MockRepository();
    await tester.pumpWidget(ChangeNotifierProvider<Repository>.value(
      value: repo,
      child: const MaterialApp(home: InfoKlinikPage()),
    ));
    await tester.pumpAndSettle();
    expect(find.text(JenisGambar.logo.label), findsOneWidget);
    expect(find.text(JenisGambar.foto.label), findsOneWidget);
    expect(find.text('Pakai bawaan'), findsNothing, reason: 'masih gambar bawaan');
    await tester.scrollUntilVisible(find.text(InfoKlinik.bawaan.waAdmin), 300, scrollable: find.byType(Scrollable).first);
    expect(find.text(InfoKlinik.bawaan.waAdmin), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextField, 'Nomor WhatsApp admin'), 'bukan nomor');
    await tester.scrollUntilVisible(find.widgetWithText(TextField, 'Alamat lengkap'), -300, scrollable: find.byType(Scrollable).first);
    await tester.enterText(find.widgetWithText(TextField, 'Alamat lengkap'), 'Jl. Baru No. 1, Subang');
    await tester.scrollUntilVisible(find.text('Simpan'), 300, scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('Simpan'));
    await tester.pump();
    expect(find.text('Ada perubahan belum disimpan.'), findsOneWidget);
    expect((await repo.infoKlinik()).alamat, InfoKlinik.bawaan.alamat, reason: 'nomor salah: belum tersimpan');

    await tester.scrollUntilVisible(find.widgetWithText(TextField, 'Nomor WhatsApp admin'), -300, scrollable: find.byType(Scrollable).first);
    await tester.enterText(find.widgetWithText(TextField, 'Nomor WhatsApp admin'), '0812-1111-2222');
    await tester.scrollUntilVisible(find.text('Simpan'), 300, scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('Simpan'));
    await tester.pump(const Duration(seconds: 5));
    final info = await repo.infoKlinik();
    expect((info.alamat, info.waAdmin), ('Jl. Baru No. 1, Subang', '0812-1111-2222'));
    expect(find.text('Ada perubahan belum disimpan.'), findsNothing);
  });
}
