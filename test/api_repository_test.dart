import 'dart:convert';
import 'dart:io';

import 'package:arulsageni/data/api_repository.dart';
import 'package:arulsageni/data/penyimpan_sesi.dart';
import 'package:arulsageni/data/repository.dart';
import 'package:arulsageni/models/models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Server tiruan: daftar (method path) → (status, body JSON).
typedef Rute = Map<String, (int, Object?)>;

void main() {
  const base = 'http://server/api/v1';
  final sekarang = DateTime(2026, 11, 11, 8);
  late List<http.Request> terkirim;
  late PenyimpanMemori simpan;

  ApiRepository buat(Rute rute) {
    terkirim = [];
    return ApiRepository(
      baseUrl: base,
      penyimpan: simpan,
      now: () => sekarang,
      client: MockClient((req) async {
        terkirim.add(req);
        final kunci = '${req.method} ${req.url.path.replaceFirst('/api/v1/', '')}';
        final r = rute[kunci];
        if (r == null) return http.Response(jsonEncode({'message': 'Data tidak ditemukan.'}), 404);
        return http.Response(r.$2 == null ? '' : jsonEncode(r.$2), r.$1, headers: {'content-type': 'application/json'});
      }),
    );
  }

  setUp(() => simpan = PenyimpanMemori());

  const userPasien = {'id': 2, 'nama': 'Siti', 'no_hp': '081234567890', 'role': 'pasien', 'aktif': true};
  const userAdmin = {'id': 1, 'nama': 'Admin', 'no_hp': null, 'username': 'admin', 'role': 'admin', 'aktif': true};

  Map<String, Object?> pendaftaranJson({String status = 'dijadwalkan'}) => {
        'id': 7, 'user_id': 2, 'nama': 'Siti', 'umur': 42, 'alamat': 'Subang', 'no_hp': '0812', 'keluhan': 'Pusing',
        'status': status, 'tanggal': '2026-11-20', 'jam': '08.00', 'nomor_antrean': 4, 'alasan': null, 'dibuat': '2026-11-10T01:00:00+00:00',
        'media': [
          {'id': 1, 'jenis': 'kondisi', 'url': '$base/media/1/kondisi-1.jpg'},
          {'id': 2, 'jenis': 'kondisi', 'url': '$base/media/2/kondisi-2.mp4'},
          {'id': 3, 'jenis': 'ktp', 'url': '$base/media/3/ktp-3.jpg'},
        ],
      };

  test('masuk menyimpan token, mengirim header, dan sesi bisa dipulihkan', () async {
    final repo = buat({
      'POST auth/masuk': (200, {'token': 'T1', 'user': userPasien}),
      'GET pendaftaran': (200, {'data': []}),
    });
    final u = await repo.loginPasien(' 0812-3456-7890 ', '123456');
    expect(u.nama, 'Siti');
    expect(u.role, Role.pasien);
    expect(jsonDecode(terkirim.single.body), {'no_hp': '0812-3456-7890', 'sandi': '123456'});
    expect(simpan.data['token'], 'T1');

    await repo.pendaftaranSaya(u.id);
    expect(terkirim.last.headers['Authorization'], 'Bearer T1');
    expect(repo.headerMedia, {'Authorization': 'Bearer T1'});

    // Aplikasi dibuka lagi: sesi dibaca dari penyimpanan.
    final lagi = buat({'GET me': (200, {'data': userPasien})});
    expect((await lagi.pulihkanSesi())?.id, '2');
  });

  test('pesan validasi server ditampilkan apa adanya', () async {
    final repo = buat({
      'POST auth/masuk': (422, {'message': 'x', 'errors': {'no_hp': ['Nomor HP atau sandi salah.']}}),
    });
    expect(() => repo.loginPasien('0812', 'salah'),
        throwsA(isA<RepositoryException>().having((e) => e.pesan, 'pesan', 'Nomor HP atau sandi salah.')));
  });

  test('401 menghapus sesi dan memanggil onSesiBerakhir', () async {
    final repo = buat({
      'POST auth/masuk': (200, {'token': 'T1', 'user': userPasien}),
      'GET notifikasi': (401, {'message': 'Sesi berakhir. Silakan masuk lagi.'}),
    });
    var berakhir = 0;
    repo.onSesiBerakhir = () => berakhir++;
    await repo.loginPasien('0812', '123456');

    await expectLater(repo.notifikasi('2'), throwsA(isA<RepositoryException>()));
    expect(berakhir, 1);
    expect(simpan.data, isEmpty);
    expect(repo.headerMedia, isEmpty);
  });

  test('JSON pendaftaran diubah ke model (media, status, tanggal)', () async {
    final repo = buat({
      'POST auth/masuk-admin': (200, {'token': 'A', 'user': userAdmin}),
      'GET admin/pendaftaran/7': (200, {'data': pendaftaranJson(status: 'tidak_hadir')}),
    });
    await repo.loginAdmin('admin', '123456');
    final p = (await repo.pendaftaran('7'))!;
    expect(p.status, StatusPendaftaran.tidakHadir);
    expect(p.tanggal, DateTime(2026, 11, 20));
    expect(p.mediaKondisi, ['$base/media/1/kondisi-1.jpg', '$base/media/2/kondisi-2.mp4']);
    expect(p.fotoKtp, '$base/media/3/ktp-3.jpg');
    expect(p.nomorAntrean, 4);
    expect(await repo.pendaftaran('99'), isNull);
  });

  test('admin: daftar berhalaman diambil semua, jadwalkan memberi tahu layar', () async {
    var hal = 0;
    final repo = ApiRepository(
      baseUrl: base,
      penyimpan: simpan,
      client: MockClient((req) async {
        if (req.url.path.endsWith('masuk-admin')) {
          return http.Response(jsonEncode({'token': 'A', 'user': userAdmin}), 200);
        }
        if (req.url.path.endsWith('jadwalkan')) {
          expect(jsonDecode(req.body), {'tanggal': '2026-11-20', 'jam': '08.00'});
          return http.Response(jsonEncode({'data': pendaftaranJson()}), 200);
        }
        hal++;
        expect(req.url.queryParameters['status'], 'menunggu');
        expect(req.url.queryParameters['page'], '$hal');
        return http.Response(
            jsonEncode({'data': [pendaftaranJson(status: 'menunggu')], 'meta': {'last_page': 2}}), 200);
      }),
    );
    await repo.loginAdmin('admin', '123456');
    expect(await repo.semuaPendaftaran(status: StatusPendaftaran.menunggu), hasLength(2));

    var diberitahu = 0;
    repo.addListener(() => diberitahu++);
    await repo.jadwalkan('7', DateTime(2026, 11, 20, 15, 30), '08.00');
    expect(diberitahu, 1);
  });

  test('kalender, slot massal, ringkas, reset sandi', () async {
    final repo = buat({
      'POST auth/masuk-admin': (200, {'token': 'A', 'user': userAdmin}),
      'GET admin/kalender': (200, {'data': {'2026-11-12': 9, '2026-11-13': 0}}),
      'POST admin/slot/massal': (200, {'baru': 3, 'sudah_ada': 1}),
      'GET admin/ringkas': (200, {'data': {
        'menunggu': 2, 'hari_berikut': '2026-11-12', 'jadwal_hari_berikut': [{'id': 1, 'nama': 'Agus', 'jam': '08.00', 'nomor_antrean': 1}, {'id': 2, 'nama': 'Siti', 'jam': '10.00', 'nomor_antrean': 2}],
        'sisa_kuota_30_hari': 300, 'chat_belum_dibaca': 1, 'terbaru': [pendaftaranJson(status: 'menunggu')],
      }}),
      'POST admin/pasien/5/reset-sandi': (200, {'sandi': '482913'}),
      'GET admin/pendaftaran': (200, {'data': [], 'jumlah': {'menunggu': 2, 'tidak_hadir': 1}}),
    });
    await repo.loginAdmin('admin', '123456');

    expect(await repo.sisaKuotaPerTanggal(), {DateTime(2026, 11, 12): 9, DateTime(2026, 11, 13): 0});
    expect(terkirim.last.url.queryParameters, {'dari': '2026-11-11', 'sampai': '2028-11-10'});

    final (baru, ada) = await repo.buatSlotMassal(
        mulai: DateTime(2026, 11, 16), sampai: DateTime(2026, 11, 22), hari: {2, 1}, jam: ['08.00'], kuota: 2);
    expect((baru, ada), (3, 1));
    expect(jsonDecode(terkirim.last.body)['hari'], [1, 2]);

    final r = await repo.ringkas();
    expect((r.menunggu, r.jadwalHariBerikut, r.hariBerikut), (2, 2, DateTime(2026, 11, 12)));
    expect(r.pasienHariBerikut.map((p) => '${p.nomor} ${p.nama} ${p.jam}'), ['1 Agus 08.00', '2 Siti 10.00']);
    expect(r.terbaru.single.status, StatusPendaftaran.menunggu);

    final jumlah = await repo.jumlahPendaftaran();
    expect((jumlah[StatusPendaftaran.menunggu], jumlah[StatusPendaftaran.tidakHadir], jumlah[StatusPendaftaran.batal]), (2, 1, 0));
    expect(await repo.resetSandi('5'), '482913');
  });

  test('chat: pesan baru hanya memicu muat ulang bila ada', () async {
    var adaBaru = false;
    final repo = ApiRepository(
      baseUrl: base,
      penyimpan: simpan,
      client: MockClient((req) async {
        if (req.url.path.endsWith('auth/masuk')) return http.Response(jsonEncode({'token': 'T', 'user': userPasien}), 200);
        final after = req.url.queryParameters['after'];
        final pesan = {'id': 11, 'pasien_id': 2, 'dari_admin': true, 'isi': 'Halo', 'waktu': '2026-11-11T01:00:00Z', 'dibaca': false};
        if (after == null) {
          return http.Response(jsonEncode({'data': [{...pesan, 'id': 10}], 'belum_dibaca': 0}), 200);
        }
        expect(after, '10');
        return http.Response(jsonEncode({'data': adaBaru ? [pesan] : [], 'belum_dibaca': adaBaru ? 1 : 0}), 200);
      }),
    );
    await repo.loginPasien('0812', '123456');
    expect((await repo.pesan('2')).single.waktu, DateTime.utc(2026, 11, 11, 1).toLocal());

    var diberitahu = 0;
    repo.addListener(() => diberitahu++);
    await repo.periksaPesanBaru('2');
    expect(diberitahu, 0);
    adaBaru = true;
    await repo.periksaPesanBaru('2');
    expect(diberitahu, 1);
  });

  test('chat: status mengetik & centang dibaca dari polling, sinyal mengetik dikirim', () async {
    var mengetik = false;
    var dibacaHingga = 0;
    final kiriman = <String>[];
    final repo = ApiRepository(
      baseUrl: base,
      penyimpan: simpan,
      client: MockClient((req) async {
        if (req.url.path.endsWith('auth/masuk')) return http.Response(jsonEncode({'token': 'T', 'user': userPasien}), 200);
        if (req.method == 'POST') {
          kiriman.add('${req.url.path.split('/v1/').last} ${req.body}');
          return http.Response('', 204);
        }
        return http.Response(
            jsonEncode({'data': [], 'belum_dibaca': 0, 'mengetik': mengetik, 'dibaca_hingga': dibacaHingga}), 200);
      }),
    );
    await repo.loginPasien('0812', '123456');
    await repo.pesan('2');
    final status = repo.lawanMengetik('2');
    var diberitahu = 0;
    repo.addListener(() => diberitahu++);

    mengetik = true;
    await repo.periksaPesanBaru('2');
    expect(status.value, isTrue);
    expect(diberitahu, 0, reason: 'status mengetik tidak memuat ulang daftar pesan');

    mengetik = false;
    dibacaHingga = 12;
    await repo.periksaPesanBaru('2');
    expect(status.value, isFalse);
    expect(diberitahu, 1, reason: 'pesan sendiri baru dibaca → muat ulang untuk centang dua');
    await repo.periksaPesanBaru('2');
    expect(diberitahu, 1);

    await repo.kirimMengetik('2', aktif: true);
    await repo.kirimMengetik('2', aktif: false);
    expect(kiriman, ['chat/mengetik {"aktif":true}', 'chat/mengetik {"aktif":false}']);
  });

  test('pasien: pengajuan dibaca dari JSON, ajukan/tarik, kalender & slot pasien', () async {
    final pengajuan = {
      'id': 9, 'jenis': 'jadwal_ulang', 'status': 'ditolak', 'tanggal': '2026-11-25', 'jam': '10.00',
      'alasan': 'Ada acara', 'alasan_tolak': 'Penuh', 'dibuat': '2026-11-11T01:00:00+00:00',
    };
    final repo = buat({
      'POST auth/masuk': (200, {'token': 'T', 'user': userPasien}),
      'GET pendaftaran/7': (200, {'data': {...pendaftaranJson(), 'pengajuan': pengajuan}}),
      'POST pendaftaran/7/pengajuan': (201, {'data': pendaftaranJson()}),
      'DELETE pendaftaran/7/pengajuan': (200, {'data': pendaftaranJson()}),
      'GET kalender': (200, {'data': {'2026-11-25': 2}}),
      'GET slot': (200, {'data': [{'jam': '10.00', 'kuota': 3, 'aktif': true, 'terisi': 1, 'sisa': 2}]}),
    });
    await repo.loginPasien('0812', '123456');
    final a = (await repo.pendaftaran('7'))!.pengajuan!;
    expect((a.id, a.jenis, a.status, a.tanggal, a.jam, a.alasanTolak),
        ('9', JenisPengajuan.jadwalUlang, StatusPengajuan.ditolak, DateTime(2026, 11, 25), '10.00', 'Penuh'));

    var diberitahu = 0;
    repo.addListener(() => diberitahu++);
    await repo.ajukanJadwalUlang('7', DateTime(2026, 11, 25, 9), '10.00', alasan: ' Ada acara ');
    expect(jsonDecode(terkirim.last.body), {'jenis': 'jadwal_ulang', 'tanggal': '2026-11-25', 'jam': '10.00', 'alasan': 'Ada acara'});
    await repo.ajukanBatal('7');
    expect(jsonDecode(terkirim.last.body), {'jenis': 'batal', 'alasan': ''});
    await repo.tarikPengajuan('7');
    expect(diberitahu, 3);

    expect(await repo.sisaKuotaPerTanggal(), {DateTime(2026, 11, 25): 2});
    expect((await repo.slotPada(DateTime(2026, 11, 25))).single.sisa, 2);
  });

  test('perlu dilengkapi: status & catatan dibaca, lengkapi kirim media lama sebagai id + berkas baru', () async {
    final baru = File('${Directory.systemTemp.createTempSync('lengkapi').path}/baru.jpg')..writeAsBytesSync([1, 2, 3]);
    final repo = buat({
      'POST auth/masuk': (200, {'token': 'T', 'user': userPasien}),
      'GET pendaftaran/7': (200, {'data': {...pendaftaranJson(status: 'perlu_dilengkapi'), 'catatan': 'Foto buram', 'dilengkapi': null}}),
      'POST pendaftaran/7/lengkapi': (200, {'data': {...pendaftaranJson(status: 'menunggu'), 'catatan': 'Foto buram', 'dilengkapi': '2026-11-11T02:00:00+00:00'}}),
    });
    await repo.loginPasien('0812', '123456');
    final p = (await repo.pendaftaran('7'))!;
    expect((p.status, p.catatan, p.dilengkapi), (StatusPendaftaran.perluDilengkapi, 'Foto buram', null));

    var diberitahu = 0;
    repo.addListener(() => diberitahu++);
    await repo.lengkapiPendaftaran('7', FormPendaftaran(
      userId: '2', nama: 'Siti', umur: 42, noHp: '0812', alamat: 'Subang', keluhan: 'Pusing berat',
      // Pertahankan foto id 1, buang video id 2, tambah 1 foto baru; KTP lama tetap.
      mediaKondisi: [p.mediaKondisi.first, baru.path],
      fotoKtp: p.fotoKtp,
    ));
    expect(diberitahu, 1);
    final body = terkirim.last.body;
    expect(body, contains('name="pertahankan[0]"\r\n\r\n1\r\n'));
    expect(body, isNot(contains('pertahankan[1]')));
    expect(body, contains('name="kondisi[]"; filename="baru.jpg"'));
    expect(body, isNot(contains('name="ktp"')));
    expect(body, contains('name="keluhan"\r\n\r\nPusing berat'));
  });

  test('admin: minta dilengkapi mengirim catatan', () async {
    final repo = buat({
      'POST auth/masuk-admin': (200, {'token': 'A', 'user': userAdmin}),
      'POST admin/pendaftaran/7/perlu-dilengkapi': (200, {'data': pendaftaranJson(status: 'perlu_dilengkapi')}),
    });
    await repo.loginAdmin('admin', '123456');
    await repo.mintaDilengkapi('7', ' Foto buram ');
    expect(jsonDecode(terkirim.last.body), {'catatan': 'Foto buram'});
  });

  test('admin: filter pengajuan, jumlah, setujui & tolak', () async {
    final repo = buat({
      'POST auth/masuk-admin': (200, {'token': 'A', 'user': userAdmin}),
      'GET admin/pendaftaran': (200, {'data': [pendaftaranJson()], 'jumlah': {}, 'pengajuan_menunggu': 4}),
      'POST admin/pengajuan/9/setujui': (200, {'data': pendaftaranJson()}),
      'POST admin/pengajuan/9/tolak': (200, {'data': pendaftaranJson()}),
    });
    await repo.loginAdmin('admin', '123456');
    await repo.semuaPendaftaran(status: StatusPendaftaran.menunggu, hanyaPengajuan: true);
    expect(terkirim.last.url.queryParameters['pengajuan'], '1');
    expect(terkirim.last.url.queryParameters.containsKey('status'), isFalse);
    expect(await repo.jumlahPengajuanMenunggu(), 4);

    await repo.setujuiPengajuan('9');
    await repo.tolakPengajuan('9', ' Penuh ');
    expect(jsonDecode(terkirim.last.body), {'alasan': 'Penuh'});
  });

  test('gambar: logo_url & foto_url dibaca dari info-klinik, ganti (multipart) & hapus', () async {
    final berkas = File('${Directory.systemTemp.path}/logo_uji.png')..writeAsBytesSync([1, 2, 3]);
    addTearDown(() => berkas.existsSync() ? berkas.deleteSync() : null);
    final repo = buat({
      'GET info-klinik': (200, {'data': {'alamat': 'A', 'logo_url': '$base/gambar/logo?v=5', 'foto_url': null}}),
      'POST admin/gambar/foto': (200, {'data': {'url': '$base/gambar/foto?v=6'}}),
      'DELETE admin/gambar/foto': (204, null),
    });
    final info = await repo.infoKlinik();
    expect(info.logoUrl, '$base/gambar/logo?v=5');
    expect(info.fotoUrl, '');

    var diberitahu = 0;
    repo.addListener(() => diberitahu++);
    await repo.gantiGambar(JenisGambar.foto, berkas.path);
    await repo.hapusGambar(JenisGambar.foto);
    expect(diberitahu, 2);
    expect(terkirim.map((r) => '${r.method} ${r.url.path}'), contains('DELETE /api/v1/admin/gambar/foto'));
  });

  test('akun admin: ubah sandi mengirim sandi lama, ubah profil memperbarui sesi; data pasien dicari', () async {
    final repo = buat({
      'POST auth/masuk-admin': (200, {'token': 'T', 'user': userAdmin}),
      'PUT me/sandi': (204, null),
      'PATCH me': (200, {'data': {...userAdmin, 'nama': 'Admin Baru', 'email': 'a@b.id'}}),
      'GET admin/pasien': (200, {
        'data': [{...userPasien, 'dibuat': '2026-11-01T01:00:00+00:00', 'jumlah_pendaftaran': 3}],
        'meta': {'last_page': 1},
      }),
    });
    await repo.loginAdmin('admin', 'x');
    await repo.ubahSandi('1', 'baru123', sandiLama: 'lama');
    expect(jsonDecode(terkirim.last.body), {'sandi_baru': 'baru123', 'sandi_lama': 'lama'});

    final u = await repo.ubahProfilAdmin(nama: 'Admin Baru', email: 'a@b.id');
    expect((u.nama, u.email), ('Admin Baru', 'a@b.id'));
    expect(jsonDecode((await simpan.baca('user'))!)['nama'], 'Admin Baru', reason: 'sesi tersimpan ikut diperbarui');

    final pasien = await repo.akunPasien(cari: 'siti');
    expect(terkirim.last.url.queryParameters['q'], 'siti');
    expect((pasien.single.jumlahPendaftaran, pasien.single.dibuat?.toUtc()), (3, DateTime.utc(2026, 11, 1, 1)));
  });
}
