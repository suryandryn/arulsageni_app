// Uji integrasi ke server Laravel sungguhan (data contoh ContohSeeder).
// Dilewati kecuali alamat API diberikan:
//
//   flutter test test/api_lokal_test.dart --dart-define=API_LOKAL=http://127.0.0.1:8000/api/v1
//
// Membuat data baru (akun & pendaftaran uji) di database server tersebut;
// jangan arahkan ke produksi.
import 'dart:convert';
import 'dart:io';

import 'package:arulsageni/data/api_repository.dart';
import 'package:arulsageni/data/penyimpan_sesi.dart';
import 'package:arulsageni/data/repository.dart';
import 'package:arulsageni/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

const _api = String.fromEnvironment('API_LOKAL');

/// PNG 1×1 yang valid (server memeriksa isi berkas, bukan hanya ekstensinya).
final _png = base64Decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==');

void main() {
  final lewati = _api.isEmpty ? 'set --dart-define=API_LOKAL=... untuk menjalankan' : null;

  ApiRepository repo() => ApiRepository(baseUrl: _api, penyimpan: PenyimpanMemori());

  test('pasien baru: daftar, kirim pendaftaran dengan foto, chat; admin menjadwalkan', () async {
    final noHp = '0899${DateTime.now().millisecondsSinceEpoch % 100000000}';
    final pasien = repo();
    final u = await pasien.daftarAkun(nama: 'Uji Integrasi', noHp: noHp, sandi: '123456');
    expect(u.role, Role.pasien);

    final dir = await Directory.systemTemp.createTemp('arul');
    final foto = File('${dir.path}/kondisi.png')..writeAsBytesSync(_png);
    final ktp = File('${dir.path}/ktp.png')..writeAsBytesSync(_png);
    final p = await pasien.daftarBerobat(FormPendaftaran(
      userId: u.id, nama: 'Uji Integrasi', umur: 30, noHp: noHp, alamat: 'Subang', keluhan: 'Uji',
      mediaKondisi: [foto.path], fotoKtp: ktp.path,
    ));
    expect(p.status, StatusPendaftaran.menunggu);
    expect(p.mediaKondisi, hasLength(1));
    expect(p.fotoKtp, isEmpty, reason: 'pasien tidak menerima URL KTP');

    // Media bisa diunduh dengan token pasien.
    final c = HttpClient();
    final req = await c.getUrl(Uri.parse(p.mediaKondisi.single));
    pasien.headerMedia.forEach(req.headers.set);
    final res = await req.close();
    expect(res.statusCode, 200);
    expect(res.headers.contentType?.mimeType, 'image/png');
    await res.drain<void>();
    c.close();

    await pasien.kirimPesan(u.id, 'Halo dari uji integrasi', dariAdmin: false);
    expect((await pasien.pesan(u.id)).last.isi, 'Halo dari uji integrasi');

    final admin = repo();
    await admin.loginAdmin('admin', '123456');
    expect((await admin.semuaPendaftaran(cari: noHp)).single.id, p.id);
    expect((await admin.pendaftaran(p.id))!.fotoKtp, isNotEmpty);
    expect(await admin.chatBelumDibaca(olehAdmin: true, pasienId: u.id), 1);

    // Jadwalkan ke slot pertama yang masih bersisa.
    final kalender = await admin.sisaKuotaPerTanggal();
    final tgl = (kalender.entries.where((e) => e.value > 0).map((e) => e.key).toList()..sort()).first;
    final slot = (await admin.slotPada(tgl)).firstWhere((s) => s.aktif && s.sisa > 0);
    await admin.jadwalkan(p.id, tgl, slot.jam);
    expect((await admin.pendaftaran(p.id))!.status, StatusPendaftaran.dijadwalkan);

    expect(await pasien.notifikasiBelumDibaca(u.id), greaterThan(0));
    expect((await admin.ringkas()).sisaKuota30Hari, greaterThanOrEqualTo(0));

    // Admin menonaktifkan akun → sesi pasien berakhir.
    var berakhir = false;
    pasien.onSesiBerakhir = () => berakhir = true;
    await admin.aturAkunAktif(u.id, false);
    await expectLater(pasien.pendaftaranSaya(u.id), throwsA(isA<RepositoryException>()));
    expect(berakhir, isTrue);

    await admin.logout();
    await dir.delete(recursive: true);
  }, skip: lewati, timeout: const Timeout(Duration(minutes: 2)));
}
