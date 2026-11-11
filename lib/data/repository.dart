import 'package:flutter/foundation.dart';

import '../models/models.dart';

/// Kontrak data aplikasi. UI hanya bergantung pada kelas ini.
///
/// Implementasi:
/// - [MockRepository]: data contoh di memori (pengembangan tampilan).
/// - ApiRepository (menyusul): memanggil API Laravel, lihat docs/API.md.
///
/// Memanggil `notifyListeners()` setiap kali data berubah agar layar memuat ulang.
abstract class Repository extends ChangeNotifier {
  // Auth
  Future<AppUser> login(String identitas, String password);
  Future<AppUser> register({
    required String nama,
    required String noWa,
    required String password,
  });
  Future<void> logout();

  // Info klinik & pengaturan
  Future<KlinikInfo> klinik();
  Future<void> simpanKlinik(KlinikInfo info);
  Future<PengaturanJadwal> pengaturan();
  Future<void> simpanPengaturan(PengaturanJadwal pengaturan);
  Future<void> perpanjangPeriode(int tahun);

  // Pendaftaran (pasien)
  Future<List<Pendaftaran>> pendaftaranSaya(String userId);
  Future<Pendaftaran?> pendaftaran(String id);
  Future<Pendaftaran> daftarBerobat(FormPendaftaran form);
  Future<void> lengkapiData(String id, String keterangan);
  Future<void> ajukanJadwalUlang(String id, String alasan);
  Future<void> batalkan(String id);

  // Pendaftaran (admin)
  Future<List<Pendaftaran>> semuaPendaftaran({StatusPendaftaran? status});
  Future<void> jadwalkan(String id, DateTime waktu);
  Future<void> mintaLengkapi(String id, String catatan);
  Future<void> tolak(String id, String catatan);
  Future<void> tandaiSelesai(String id);
  Future<void> tandaiTidakHadir(String id);
  Future<void> kirimPengingat(String id);

  // Jadwal
  Future<List<Pendaftaran>> jadwalPada(DateTime tanggal);
  Future<int> kuotaPada(DateTime tanggal);

  /// Tanggal (tanpa jam) yang masih bisa dipilih: hari praktik, bukan libur,
  /// di dalam periode, dan kuota belum penuh.
  Future<Set<DateTime>> tanggalTersedia();

  // Chat
  Future<List<Pesan>> pesan(String pasienId);
  Future<void> kirimPesan(String pasienId, String isi, {required bool dariAdmin});
  Future<List<Percakapan>> percakapan();

  // Notifikasi
  Future<List<Notifikasi>> notifikasi(String userId);
  Future<void> tandaiNotifikasiDibaca(String userId);

  // Admin
  Future<RingkasAdmin> ringkas();
}

class RepositoryException implements Exception {
  RepositoryException(this.pesan);
  final String pesan;
  @override
  String toString() => pesan;
}
