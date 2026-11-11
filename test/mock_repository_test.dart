import 'package:arulsageni/core/format.dart';
import 'package:arulsageni/data/mock_repository.dart';
import 'package:arulsageni/data/repository.dart';
import 'package:arulsageni/models/models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() => initializeDateFormatting('id_ID'));

  // Rabu, 11 November 2026 pukul 08.00.
  final sekarang = DateTime(2026, 11, 11, 8);
  late MockRepository repo;

  setUp(() => repo = MockRepository(now: () => sekarang));

  Future<Pendaftaran> daftar(String userId) => repo.daftarBerobat(FormPendaftaran(
        userId: userId,
        nama: 'Pasien $userId',
        noWa: '0811000$userId',
        kota: 'Subang',
        keluhan: 'Uji',
        mediaKondisi: const ['/tmp/foto.jpg'],
      ));

  test('pendaftaran tanpa foto/video kondisi ditolak', () async {
    expect(
      () => repo.daftarBerobat(const FormPendaftaran(
          userId: '2', nama: 'A', noWa: '08', kota: 'B', keluhan: 'C', mediaKondisi: [])),
      throwsA(isA<RepositoryException>()),
    );
  });

  test('nomor antrean bertambah per tanggal dan kuota penuh ditolak', () async {
    final kamis = DateTime(2026, 11, 12);
    await repo.simpanPengaturan((await repo.pengaturan()).copyWith(kuotaPerHari: 2));

    final a = await daftar('3');
    final b = await daftar('4');
    final c = await daftar('2');
    await repo.jadwalkan(a.id, gabungJam(kamis, '08:00'));
    await repo.jadwalkan(b.id, gabungJam(kamis, '09:00'));

    expect((await repo.pendaftaran(a.id))!.noAntrean, 1);
    expect((await repo.pendaftaran(b.id))!.noAntrean, 2);
    expect((await repo.pendaftaran(b.id))!.status, StatusPendaftaran.terjadwal);
    expect(() => repo.jadwalkan(c.id, gabungJam(kamis, '10:00')), throwsA(isA<RepositoryException>()));
    expect((await repo.tanggalTersedia()).contains(kamis), isFalse);
  });

  test('tanggal libur, hari non-praktik, dan di luar periode tidak tersedia', () async {
    final p = await repo.pengaturan();
    final jumat = DateTime(2026, 11, 13);
    await repo.simpanPengaturan(p.copyWith(
      tanggalKhusus: {jumat: 0},
      periodeAkhir: DateTime(2026, 12, 31),
    ));
    final tersedia = await repo.tanggalTersedia();

    expect(tersedia.contains(jumat), isFalse); // libur
    expect(tersedia.contains(DateTime(2026, 11, 15)), isFalse); // Minggu
    expect(tersedia.contains(DateTime(2026, 11, 14)), isTrue); // Sabtu
    expect(tersedia.contains(DateTime(2027, 1, 4)), isFalse); // di luar periode

    await repo.perpanjangPeriode(1);
    expect((await repo.pengaturan()).periodeAkhir, DateTime(2027, 12, 31));
  });

  test('jadwal memicu notifikasi ke pasien; jadwal ulang menghapus jadwal', () async {
    final a = await daftar('3');
    await repo.jadwalkan(a.id, gabungJam(DateTime(2026, 11, 12), '13:00'));
    final notif = await repo.notifikasi('3');
    expect(notif.first.judul, 'Jadwal berobat diberikan');

    await repo.ajukanJadwalUlang(a.id, 'Ada acara keluarga');
    final p = (await repo.pendaftaran(a.id))!;
    expect(p.status, StatusPendaftaran.menungguVerifikasi);
    expect(p.jadwal, isNull);
    expect(p.noAntrean, isNull);
  });

  test('login dengan nomor berformat berbeda tetap dikenali', () async {
    final u = await repo.login('0812-3456-7890', '123456');
    expect(u.nama, 'Budi Santoso');
  });
}
