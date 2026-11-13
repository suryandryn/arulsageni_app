import 'package:arulsageni/app.dart';
import 'package:arulsageni/features/pasien/daftar_berobat_page.dart';
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

  /// Isi akun demo (data contoh mock), lalu ketuk Masuk.
  Future<void> masukPasien(WidgetTester t, {String sandi = '123456'}) async {
    await t.enterText(find.byType(TextField).at(0), '0812-3456-7890');
    await t.enterText(find.byType(TextField).at(1), sandi);
    await t.tap(find.widgetWithText(FilledButton, 'Masuk'));
  }

  Future<void> masukAdmin(WidgetTester t) async {
    await t.tap(find.text('Admin'));
    await t.pump();
    await t.enterText(find.byType(TextField).at(0), 'admin');
    await t.enterText(find.byType(TextField).at(1), '123456');
    await t.tap(find.widgetWithText(FilledButton, 'Masuk Admin'));
  }

  testWidgets('pasien demo masuk, melihat jadwal, lalu membuka Info', (tester) async {
    await tester.pumpWidget(const PadepokanApp());
    expect(find.text('Padepokan Arul Sageni'), findsOneWidget);
    // Kolom masuk kosong saat pertama dibuka; hanya placeholder yang tampil.
    expect(find.text('08xxxxxxxxxx'), findsOneWidget);
    expect(find.text('0812-3456-7890'), findsNothing);

    await masukPasien(tester);
    await tunggu(tester);

    expect(find.text('Halo, Siti'), findsOneWidget);
    expect(find.text('Jadwal berobat - Siti Rahmawati'), findsOneWidget);
    expect(find.text('JADWAL BEROBAT (SITI RAHMAWATI)'), findsOneWidget);
    expect(find.text('Nomor antrean '), findsOneWidget); // kartu jadwal menampilkan nomor antrean

    await tester.tap(nav('Info'));
    await tunggu(tester);
    expect(find.text('Buka Google Maps'), findsOneWidget);
  });

  testWidgets('sandi salah menampilkan pemberitahuan', (tester) async {
    await tester.pumpWidget(const PadepokanApp());
    await masukPasien(tester, sandi: 'salah');
    await tunggu(tester);

    expect(find.text('Gagal masuk'), findsOneWidget);
    expect(find.text('Nomor HP atau sandi salah.'), findsOneWidget);
    await habiskanToast(tester);
  });

  testWidgets('admin masuk ke Beranda Admin dan membuka Pendaftaran', (tester) async {
    await tester.pumpWidget(const PadepokanApp());
    await masukAdmin(tester);
    await tunggu(tester);

    // Beranda sama dengan panel web: 4 angka + daftar menunggu + pasien hari berikutnya.
    expect(find.text('Beranda Admin'), findsOneWidget);
    expect(find.text('Pendaftaran menunggu'), findsOneWidget);
    expect(find.text('Sisa kuota 30 hari'), findsOneWidget);
    await tester.drag(find.text('Sisa kuota 30 hari'), const Offset(0, -300));
    await tester.pump();
    expect(find.text('Menunggu dinilai'), findsOneWidget);
    expect(find.textContaining('Hendra Wijaya'), findsWidgets);

    await tester.drag(find.text('Menunggu dinilai'), const Offset(0, 300));
    await tester.pump();
    // Kotak "Pendaftaran menunggu" membuka tab Pendaftaran dengan filter Menunggu.
    await tester.tap(find.text('Pendaftaran menunggu'));
    await tunggu(tester);
    expect(find.text('Hendra Wijaya'), findsOneWidget);
    expect(find.text('Ibu Marni'), findsOneWidget);

    // Filter status = Semua + 6 status (seperti web), satu baris yang bisa digeser.
    await tester.tap(find.text('Semua'));
    await tunggu(tester);
    expect(find.text('Pak Slamet'), findsOneWidget);
    expect(find.text('Tidak hadir'), findsOneWidget);
    expect(find.text('Batal'), findsOneWidget);

    // Detail: tombol kembali berupa chevron di kiri.
    await tester.tap(find.text('Pak Slamet'));
    await tunggu(tester);
    expect(find.text('Detail Pendaftaran'), findsOneWidget);
    await tester.tap(find.byTooltip('Kembali'));
    await tunggu(tester);
    expect(find.text('Detail Pendaftaran'), findsNothing);
  });

  testWidgets('pasien mengajukan pembatalan dari detail pendaftaran', (tester) async {
    await tester.pumpWidget(const PadepokanApp());
    await masukPasien(tester);
    await tunggu(tester);
    await tester.tap(nav('Daftar'));
    await tunggu(tester);
    await tester.tap(find.text('Siti Rahmawati'));
    await tunggu(tester);

    await tester.scrollUntilVisible(find.text('Ajukan pembatalan'), 300, scrollable: find.byType(Scrollable).last);
    expect(find.text('Ajukan jadwal ulang'), findsOneWidget);
    await tester.tap(find.text('Ajukan pembatalan'));
    await tunggu(tester);
    await tester.enterText(find.byType(TextField), 'Sudah membaik');
    await tester.tap(find.text('Kirim pengajuan'));
    await tunggu(tester);

    expect(find.text('Pengajuan terkirim'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Tarik pengajuan'), 300, scrollable: find.byType(Scrollable).last);
    expect(find.text('Menunggu keputusan admin'), findsOneWidget);
    expect(find.text('Sudah membaik'), findsOneWidget);
    expect(find.text('Ajukan pembatalan'), findsNothing);
    await habiskanToast(tester);
  });

  testWidgets('pasien melengkapi pendaftaran yang perlu dilengkapi, catatan tetap tampil', (tester) async {
    await tester.pumpWidget(const PadepokanApp());
    await masukPasien(tester);
    await tunggu(tester);
    await tester.tap(nav('Daftar'));
    await tunggu(tester);
    await tester.tap(find.text('Bapak Ujang (ayah Siti)'));
    await tunggu(tester);

    expect(find.text('Pendaftaran perlu dilengkapi'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Lengkapi Pendaftaran'));
    await tunggu(tester);
    expect(find.text('Lengkapi Pendaftaran'), findsOneWidget);
    expect(find.textContaining('Foto kondisi lutut kurang jelas'), findsOneWidget);
    expect(find.text('Lutut sering nyeri saat berjalan.'), findsOneWidget); // isian lama terisi
    await tester.enterText(find.widgetWithText(TextField, 'Lutut sering nyeri saat berjalan.'), 'Lutut kanan nyeri, sudah 2 bulan.');

    final kirim = find.widgetWithText(FilledButton, 'Kirim Perbaikan');
    await tester.scrollUntilVisible(kirim, 300,
        scrollable: find.descendant(of: find.byType(DaftarBerobatPage), matching: find.byType(Scrollable)).first);
    await tester.tap(kirim);
    await tunggu(tester);

    expect(find.text('Pendaftaran terkirim'), findsOneWidget);
    expect(find.text('Catatan perlu dilengkapi'), findsOneWidget);
    expect(find.textContaining('Sudah dilengkapi'), findsOneWidget);
    expect(find.text('Lutut kanan nyeri, sudah 2 bulan.'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Lengkapi Pendaftaran'), findsNothing);
    await habiskanToast(tester);
  });

  testWidgets('admin meminta pendaftaran dilengkapi dengan catatan', (tester) async {
    await tester.pumpWidget(const PadepokanApp());
    await masukAdmin(tester);
    await tunggu(tester);
    await tester.tap(find.text('Pendaftaran menunggu'));
    await tunggu(tester);
    await tester.tap(find.text('Hendra Wijaya'));
    await tunggu(tester);

    final minta = find.widgetWithText(FilledButton, 'Minta Dilengkapi');
    await tester.dragUntilVisible(minta, find.byType(ListView).first, const Offset(0, -300));
    await tester.tap(minta);
    await tunggu(tester);
    // Tombol kirim nonaktif sampai catatan diisi.
    expect(tester.widget<TextButton>(find.widgetWithText(TextButton, 'Kirim ke pasien')).onPressed, isNull);
    await tester.enterText(find.byType(TextField).last, 'Mohon kirim foto punggung dari samping');
    await tester.pump();
    await tester.tap(find.text('Kirim ke pasien'));
    await tunggu(tester);

    expect(find.text('Terkirim'), findsOneWidget);
    await tester.drag(find.byType(ListView).first, const Offset(0, 3000));
    await tester.pump();
    expect(find.text('Pendaftaran perlu dilengkapi'), findsOneWidget);
    expect(find.text('Mohon kirim foto punggung dari samping'), findsOneWidget);
    expect(find.text('Menunggu pasien melengkapi.'), findsOneWidget);
    await habiskanToast(tester);
  });

  testWidgets('admin menyetujui pengajuan jadwal ulang dari banner Beranda', (tester) async {
    await tester.pumpWidget(const PadepokanApp());
    await masukAdmin(tester);
    await tunggu(tester);

    await tester.tap(find.textContaining('1 pengajuan jadwal ulang / pembatalan'));
    await tunggu(tester);
    expect(find.text('Agus Pratama'), findsOneWidget);
    expect(find.textContaining('Minta jadwal ulang ke'), findsOneWidget);

    await tester.tap(find.text('Agus Pratama'));
    await tunggu(tester);
    expect(find.text('Pengajuan jadwal ulang dari pasien'), findsOneWidget);
    expect(find.text('Ada acara keluarga, mohon dipindah.'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Setujui'));
    await tunggu(tester);
    await tester.tap(find.text('Ya'));
    await tunggu(tester);

    expect(find.text('Pengajuan disetujui'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Setujui'), findsNothing);
    await habiskanToast(tester);
  });
}
