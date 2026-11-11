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
    expect((await repo.notifikasi('3')).map((n) => n.judul), ['Jadwal berobat diubah', 'Jadwal berobat Anda']);
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
    expect((await repo.notifikasi('3')).first.isi, 'Belum dapat kami tangani.');
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
}
