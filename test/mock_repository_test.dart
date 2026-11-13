import 'package:arulsageni/data/mock_repository.dart';
import 'package:arulsageni/data/repository.dart';
import 'package:arulsageni/models/models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() => initializeDateFormatting('id_ID'));

  // Rabu, 11 November 2026 pukul 08.00. Slot contoh: Sen–Sab, 08/10/13/15, kuota 3,
  // mulai Kamis 12 Nov. Agus Pratama sudah dijadwalkan Kamis 12 Nov 08.00.
  final sekarang = DateTime(2026, 11, 11, 8);
  final kamis = DateTime(2026, 11, 12);
  final minggu = DateTime(2026, 11, 15);
  late MockRepository repo;

  setUp(() => repo = MockRepository(now: () => sekarang));

  Future<Pendaftaran> daftar(String userId, {List<String> media = const ['foto.jpg']}) =>
      repo.daftarBerobat(FormPendaftaran(
        userId: userId,
        nama: 'Pasien $userId',
        umur: 40,
        noHp: '0811000$userId',
        alamat: 'Subang',
        keluhan: 'Uji',
        mediaKondisi: media,
        fotoKtp: 'ktp.jpg',
      ));

  test('pendaftaran wajib foto/video, maks. 5 foto dan 1 video', () async {
    expect(() => daftar('2', media: []), throwsA(isA<RepositoryException>()));
    expect(() => daftar('2', media: List.filled(6, 'a.jpg')), throwsA(isA<RepositoryException>()));
    expect(() => daftar('2', media: ['a.mp4', 'b.mp4']), throwsA(isA<RepositoryException>()));
    final p = await daftar('2', media: ['a.jpg', 'b.mp4']);
    expect(p.status, StatusPendaftaran.menunggu);
  });

  test('kuota per slot jam: penuh ditolak, sisa kuota per tanggal berkurang', () async {
    expect((await repo.sisaKuotaPerTanggal())[kamis], 4 * 3 - 1);

    final a = await daftar('3');
    final b = await daftar('4');
    final c = await daftar('2');
    await repo.jadwalkan(a.id, kamis, '08.00');
    await repo.jadwalkan(b.id, kamis, '08.00');
    expect(() => repo.jadwalkan(c.id, kamis, '08.00'), throwsA(isA<RepositoryException>()));

    // Menyimpan ulang jadwal yang sama tetap boleh walau slot penuh.
    await repo.jadwalkan(a.id, kamis, '08.00');

    final slot = (await repo.slotPada(kamis)).firstWhere((s) => s.jam == '08.00');
    expect(slot.terisi, 3);
    expect(slot.sisa, 0);
    expect((await repo.sisaKuotaPerTanggal())[kamis], 4 * 3 - 3);
    // Notifikasi terbaru di depan: jadwal pertama lalu simpan ulang (diubah).
    expect((await repo.notifikasi('3')).map((n) => n.judul), ['Jadwal berobat diperbarui', 'Jadwal berobat sudah ditetapkan']);
  });

  test('slot nonaktif tidak dihitung; slot berisi tidak bisa dihapus atau dikurangi', () async {
    await repo.aturSlotAktif(kamis, '15.00', false);
    expect((await repo.sisaKuotaPerTanggal())[kamis], 3 * 3 - 1);

    expect(() => repo.hapusSlot(kamis, '08.00'), throwsA(isA<RepositoryException>()));
    expect(() => repo.ubahKuotaSlot(kamis, '08.00', 0), throwsA(isA<RepositoryException>()));
    await repo.hapusSlot(kamis, '10.00');
    expect((await repo.slotPada(kamis)).map((s) => s.jam), ['08.00', '13.00', '15.00']);
  });

  test('buat slot massal melewati slot yang sudah ada dan dibatasi 24 bulan', () async {
    expect(await repo.slotPada(minggu), isEmpty);
    final (baru, ada) =
        await repo.buatSlotMassal(mulai: minggu, sampai: minggu, hari: {0}, jam: ['08.00', '09:00'], kuota: 2);
    expect((baru, ada), (2, 0));
    expect((await repo.slotPada(minggu)).map((s) => s.jam), ['08.00', '09.00']);

    final ulang = await repo.buatSlotMassal(mulai: minggu, sampai: minggu, hari: {0}, jam: ['08.00'], kuota: 2);
    expect(ulang, (0, 1));

    expect(
      () => repo.buatSlotMassal(mulai: kamis, sampai: DateTime(2029, 1, 1), hari: {1}, jam: ['08.00'], kuota: 1),
      throwsA(isA<RepositoryException>()),
    );
  });

  test('tolak wajib alasan dan mengirim notifikasi ke pasien', () async {
    expect(() => repo.tolak('101', '  '), throwsA(isA<RepositoryException>()));
    await repo.tolak('101', 'Belum dapat kami tangani.');
    expect((await repo.pendaftaran('101'))!.status, StatusPendaftaran.ditolak);
    final n = (await repo.notifikasi('3')).first;
    expect(n.judul, 'Pendaftaran belum dapat diproses');
    // Titik di akhir alasan tidak dobel.
    expect(n.isi, contains('Alasan: Belum dapat kami tangani. Silakan hubungi admin'));
  });

  test('chat belum dibaca dihitung per pihak', () async {
    expect(await repo.chatBelumDibaca(olehAdmin: true), 1); // pesan Hendra
    await repo.tandaiChatDibaca('3', olehAdmin: true);
    expect(await repo.chatBelumDibaca(olehAdmin: true), 0);

    await repo.kirimPesan('2', 'Halo Bu Siti', dariAdmin: true);
    expect(await repo.chatBelumDibaca(olehAdmin: false, pasienId: '2'), 1);
    expect(await repo.notifikasiBelumDibaca('2'), 1);
  });

  test('masuk dengan format nomor berbeda; akun nonaktif ditolak', () async {
    expect((await repo.loginPasien('+62 812 3456 7890', '123456')).nama, 'Siti Rahmawati');
    await repo.aturAkunAktif('2', false);
    expect(() => repo.loginPasien('081234567890', '123456'), throwsA(isA<RepositoryException>()));
    expect((await repo.loginAdmin('admin', '123456')).isAdmin, isTrue);
  });

  group('pengajuan jadwal ulang / pembatalan', () {
    // Siti (100) dijadwalkan Rabu 25 Nov 10.00. Data contoh: Agus (103) minta jadwal ulang.
    final jumat = DateTime(2026, 11, 13);

    test('jadwal ulang: validasi, satu pengajuan menunggu, disetujui memindah jadwal', () async {
      expect(await repo.jumlahPengajuanMenunggu(), 1);
      await expectLater(() => repo.ajukanJadwalUlang('100', DateTime(2026, 11, 25), '10.00'), throwsA(isA<RepositoryException>()));
      await expectLater(() => repo.ajukanJadwalUlang('100', minggu, '08.00'), throwsA(isA<RepositoryException>()));
      await expectLater(() => repo.ajukanJadwalUlang('101', jumat, '08.00'), throwsA(isA<RepositoryException>())); // masih menunggu

      await repo.ajukanJadwalUlang('100', jumat, '13.00', alasan: ' Ada acara ');
      var p = (await repo.pendaftaran('100'))!;
      expect((p.pengajuanMenunggu?.jenis, p.pengajuan?.alasan, p.bisaAjukanBatal), (JenisPengajuan.jadwalUlang, 'Ada acara', false));
      await expectLater(() => repo.ajukanBatal('100'), throwsA(isA<RepositoryException>()));
      expect((await repo.semuaPendaftaran(hanyaPengajuan: true)).map((p) => p.id), containsAll(['100', '103']));
      expect((await repo.ringkas()).pengajuanMenunggu, 2);

      await repo.setujuiPengajuan(p.pengajuan!.id);
      p = (await repo.pendaftaran('100'))!;
      expect((p.tanggal, p.jam, p.pengajuan!.status), (jumat, '13.00', StatusPengajuan.disetujui));
      expect((await repo.notifikasi('2')).first.judul, 'Pengajuan jadwal ulang disetujui');
      await expectLater(() => repo.setujuiPengajuan(p.pengajuan!.id), throwsA(isA<RepositoryException>()));
    });

    test('setujui gagal bila slot yang diminta sudah penuh', () async {
      await repo.ajukanJadwalUlang('100', kamis, '10.00');
      for (final id in ['101', '102', '104']) {
        await repo.jadwalkan(id, kamis, '10.00');
      }
      final a = (await repo.pendaftaran('100'))!.pengajuan!;
      await expectLater(() => repo.setujuiPengajuan(a.id), throwsA(isA<RepositoryException>()));
      final p = (await repo.pendaftaran('100'))!;
      expect((p.tanggal, p.pengajuanMenunggu?.id), (DateTime(2026, 11, 25), a.id));
    });

    test('pembatalan ditolak dengan alasan, ditarik, lalu disetujui', () async {
      await repo.ajukanBatal('101');
      final a = (await repo.pendaftaran('101'))!.pengajuan!;
      await expectLater(() => repo.tolakPengajuan(a.id, ' '), throwsA(isA<RepositoryException>()));
      await repo.tolakPengajuan(a.id, 'Hubungi admin dulu');
      var p = (await repo.pendaftaran('101'))!;
      expect((p.status, p.pengajuan!.status, p.pengajuan!.alasanTolak), (StatusPendaftaran.menunggu, StatusPengajuan.ditolak, 'Hubungi admin dulu'));
      expect((await repo.notifikasi('3')).first.judul, 'Pengajuan pembatalan tidak disetujui');

      await repo.ajukanBatal('101');
      await repo.tarikPengajuan('101');
      expect((await repo.pendaftaran('101'))!.pengajuan, isNull);

      await repo.ajukanBatal('101', alasan: 'Sudah sembuh');
      await repo.setujuiPengajuan((await repo.pendaftaran('101'))!.pengajuan!.id);
      p = (await repo.pendaftaran('101'))!;
      expect((p.status, p.bisaAjukanBatal), (StatusPendaftaran.batal, false));
    });

    test('pengajuan menunggu ditutup bila admin mengubah status', () async {
      await repo.ubahStatus('103', StatusPendaftaran.selesai);
      expect((await repo.pendaftaran('103'))!.pengajuan!.status, StatusPengajuan.ditolak);
      expect(await repo.jumlahPengajuanMenunggu(), 0);
    });
  });

  group('perlu dilengkapi', () {
    FormPendaftaran form(Pendaftaran p, {List<String>? media, String keluhan = 'Lutut kanan nyeri'}) => FormPendaftaran(
          userId: p.userId,
          nama: p.nama,
          umur: p.umur,
          noHp: p.noHp,
          alamat: p.alamat,
          keluhan: keluhan,
          mediaKondisi: media ?? p.mediaKondisi,
          fotoKtp: p.fotoKtp,
        );

    test('admin minta dilengkapi hanya dari menunggu, catatan wajib, pasien diberi tahu', () async {
      await expectLater(() => repo.mintaDilengkapi('101', ' '), throwsA(isA<RepositoryException>()));
      await expectLater(() => repo.mintaDilengkapi('100', 'x'), throwsA(isA<RepositoryException>())); // dijadwalkan
      await repo.mintaDilengkapi('101', 'Video kurang jelas');
      final p = (await repo.pendaftaran('101'))!;
      expect((p.status, p.catatan, p.bisaDilengkapi), (StatusPendaftaran.perluDilengkapi, 'Video kurang jelas', true));
      expect((await repo.notifikasi('3')).first.judul, 'Mohon lengkapi data pendaftaran');
      expect((await repo.jumlahPendaftaran())[StatusPendaftaran.perluDilengkapi], 2);
    });

    test('pasien melengkapi: status kembali menunggu, catatan tetap, data & berkas diperbarui', () async {
      final siti = (await repo.pendaftaran('100'))!;
      await expectLater(() => repo.lengkapiPendaftaran('100', form(siti)), throwsA(isA<RepositoryException>()));

      final p = (await repo.pendaftaran('106'))!;
      await expectLater(() => repo.lengkapiPendaftaran('106', form(p, media: [])), throwsA(isA<RepositoryException>()));
      await repo.lengkapiPendaftaran('106', form(p, media: ['lutut_dekat.jpg']));

      final q = (await repo.pendaftaran('106'))!;
      expect((q.status, q.keluhan, q.catatan), (StatusPendaftaran.menunggu, 'Lutut kanan nyeri', p.catatan));
      expect(q.mediaKondisi, ['lutut_dekat.jpg']);
      expect(q.dilengkapi, sekarang);
      await expectLater(() => repo.lengkapiPendaftaran('106', form(q)), throwsA(isA<RepositoryException>()));
    });

    test('pembatalan boleh diajukan saat perlu dilengkapi', () async {
      expect((await repo.pendaftaran('106'))!.bisaAjukanBatal, isTrue);
      await repo.ajukanBatal('106');
      await repo.setujuiPengajuan((await repo.pendaftaran('106'))!.pengajuan!.id);
      expect((await repo.pendaftaran('106'))!.status, StatusPendaftaran.batal);
    });
  });

  test('nomor antrean per tanggal: urut dijadwalkan, disusun ulang saat batal/pindah, pasien diberi tahu', () async {
    // Kamis 12 Nov: Agus (103) sudah dijadwalkan 08.00 → nomor 1.
    final jumat = DateTime(2026, 11, 13);
    Future<int?> nomor(String id) async => (await repo.pendaftaran(id))!.nomorAntrean;
    Future<Notifikasi> notif(String uid) async => (await repo.notifikasi(uid)).first;

    expect(await nomor('103'), 1);
    await repo.jadwalkan('101', kamis, '10.00'); // Hendra
    await repo.jadwalkan('102', kamis, '08.00'); // Ibu Marni
    expect([await nomor('103'), await nomor('101'), await nomor('102')], [1, 2, 3]);
    expect((await notif('4')).isi, contains('Nomor antrean 3'));
    expect((await repo.ringkas()).pasienHariBerikut.map((p) => '${p.nomor} ${p.nama}'),
        ['1 Agus Pratama', '2 Hendra Wijaya', '3 Ibu Marni']);

    await repo.jadwalkan('101', kamis, '13.00'); // pindah jam, tanggal sama
    expect(await nomor('101'), 2);

    await repo.ubahStatus('103', StatusPendaftaran.batal);
    expect([await nomor('103'), await nomor('101'), await nomor('102')], [null, 1, 2]);
    expect((await notif('3')).judul, 'Nomor antrean diperbarui');
    expect((await notif('3')).isi, contains('kini 1 (sebelumnya 2)'));
    expect((await notif('4')).judul, 'Nomor antrean diperbarui');

    await repo.jadwalkan('101', jumat, '08.00'); // pindah tanggal
    expect([await nomor('101'), await nomor('102')], [1, 1]);
    expect((await notif('3')).judul, 'Jadwal berobat diperbarui');

    await repo.ubahStatus('102', StatusPendaftaran.selesai);
    expect(await nomor('102'), 1);
  });

  test('gambar: logo & foto terpisah, tidak hilang saat info disimpan, bisa kembali ke bawaan', () async {
    expect((await repo.infoKlinik()).logoUrl, '');
    await repo.gantiGambar(JenisGambar.logo, '/tmp/logo.png');
    await repo.gantiGambar(JenisGambar.foto, '/tmp/foto.png');
    await repo.simpanInfoKlinik(await repo.infoKlinik());
    var info = await repo.infoKlinik();
    expect((info.logoUrl, info.fotoUrl), ('/tmp/logo.png', '/tmp/foto.png'));

    await repo.hapusGambar(JenisGambar.foto);
    info = await repo.infoKlinik();
    expect((info.logoUrl, info.fotoUrl), ('/tmp/logo.png', ''));
  });

  test('admin: data pasien bisa dicari, berisi jumlah pendaftaran; nama akun pendaftar tampil', () async {
    final semua = await repo.akunPasien();
    expect(semua.every((u) => u.jumlahPendaftaran != null && u.dibuat != null), isTrue);
    final siti = await repo.akunPasien(cari: 'siti');
    expect(siti.map((u) => u.nama), ['Siti Rahmawati']);
    expect((await repo.akunPasien(cari: '0813')).map((u) => u.nama), ['Hendra Wijaya']);
    expect(await repo.akunPasien(cari: 'tidak ada'), isEmpty);

    final p = (await repo.semuaPendaftaran()).first;
    expect((await repo.pendaftaran(p.id))!.namaAkun, isNotNull);
  });

  test('admin: ubah sandi wajib sandi lama; ubah profil', () async {
    expect(() => repo.ubahSandi('1', 'baru123', sandiLama: 'salah'), throwsA(isA<RepositoryException>()));
    await repo.ubahSandi('1', 'baru123', sandiLama: '123456');
    expect((await repo.loginAdmin('admin', 'baru123')).nama, 'Admin');

    final u = await repo.ubahProfilAdmin(nama: ' Admin Klinik ', email: 'admin@contoh.id');
    expect((u.nama, u.email), ('Admin Klinik', 'admin@contoh.id'));
    expect(() => repo.ubahProfilAdmin(nama: 'A', email: 'bukan-email'), throwsA(isA<RepositoryException>()));
  });
}
