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
  // ---- Auth & akun
  Future<AppUser> loginPasien(String noHp, String sandi);
  Future<AppUser> loginAdmin(String username, String sandi);
  Future<AppUser> daftarAkun({required String nama, required String noHp, required String sandi});
  Future<void> logout();
  Future<void> ubahSandi(String userId, String sandiBaru);

  // ---- Pendaftaran (pasien)
  Future<List<Pendaftaran>> pendaftaranSaya(String userId);
  Future<Pendaftaran?> pendaftaran(String id);
  Future<Pendaftaran> daftarBerobat(FormPendaftaran form);

  // ---- Pendaftaran (admin)
  Future<List<Pendaftaran>> semuaPendaftaran({StatusPendaftaran? status, String cari = ''});

  /// Beri atau pindah jadwal; kirim notifikasi ke pasien.
  Future<void> jadwalkan(String id, DateTime tanggal, String jam);

  /// Tolak dengan alasan (wajib, dikirim ke pasien).
  Future<void> tolak(String id, String alasan);

  /// Selesai / Tidak hadir / Batal untuk pendaftaran yang dijadwalkan.
  Future<void> ubahStatus(String id, StatusPendaftaran status);
  Future<void> kirimPengingat(String id);

  // ---- Slot jadwal
  /// Sisa kuota per tanggal (hanya tanggal yang punya slot aktif).
  Future<Map<DateTime, int>> sisaKuotaPerTanggal();
  Future<List<Slot>> slotPada(DateTime tanggal);
  Future<void> tambahSlot(DateTime tanggal, String jam, int kuota);
  Future<void> ubahKuotaSlot(DateTime tanggal, String jam, int kuota);
  Future<void> aturSlotAktif(DateTime tanggal, String jam, bool aktif);
  Future<void> hapusSlot(DateTime tanggal, String jam);

  /// Buat slot untuk rentang tanggal; slot yang sudah ada dilewati.
  /// Mengembalikan (jumlah baru, jumlah sudah ada).
  Future<(int, int)> buatSlotMassal({
    required DateTime mulai,
    required DateTime sampai,
    required Set<int> hari, // DateTime.weekday % 7 (Minggu = 0)
    required List<String> jam,
    required int kuota,
  });

  // ---- Chat
  Future<List<Pesan>> pesan(String pasienId);
  Future<void> kirimPesan(String pasienId, String isi, {required bool dariAdmin});
  Future<void> tandaiChatDibaca(String pasienId, {required bool olehAdmin});
  Future<int> chatBelumDibaca({required bool olehAdmin, String? pasienId});
  Future<List<Percakapan>> percakapan();

  // ---- Notifikasi
  Future<List<Notifikasi>> notifikasi(String userId);
  Future<int> notifikasiBelumDibaca(String userId);
  Future<void> tandaiNotifikasiDibaca(String userId);

  // ---- Admin: data pasien & media sosial
  Future<RingkasAdmin> ringkas();
  Future<List<AppUser>> akunPasien();
  Future<void> resetSandi(String userId);
  Future<void> aturAkunAktif(String userId, bool aktif);
  Future<List<MediaSosial>> mediaSosial();
  Future<void> simpanMediaSosial(List<MediaSosial> daftar);
}

class RepositoryException implements Exception {
  RepositoryException(this.pesan);
  final String pesan;
  @override
  String toString() => pesan;
}
