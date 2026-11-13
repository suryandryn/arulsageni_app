import 'package:flutter/foundation.dart';

import '../models/models.dart';

/// Kontrak data aplikasi. UI hanya bergantung pada kelas ini.
///
/// Implementasi:
/// - [MockRepository]: data contoh di memori (pengembangan tampilan).
/// - [ApiRepository]: memanggil API Laravel, lihat docs/API.md.
///
/// Memanggil `notifyListeners()` setiap kali data berubah agar layar memuat ulang.
/// Metode baca (GET) tidak boleh memanggil `notifyListeners()`, karena layar
/// memuat ulang setiap kali ada pemberitahuan.
abstract class Repository extends ChangeNotifier {
  // ---- Sesi
  /// Dipanggil bila server menolak token (keluar paksa, akun dinonaktifkan).
  VoidCallback? onSesiBerakhir;

  /// Pengguna dari sesi tersimpan (aplikasi dibuka lagi), atau null.
  Future<AppUser?> pulihkanSesi() async => null;

  /// Muat ulang semua layar yang terbuka (data bisa diubah dari panel web / perangkat lain).
  /// Dipanggil saat aplikasi kembali dibuka, pindah tab, tarik-untuk-segarkan, dan berkala.
  void segarkan() => notifyListeners();

  /// Header untuk memuat media dari server (gambar/video berkas pasien).
  Map<String, String> get headerMedia => const {};

  /// Cek pesan baru (dipanggil berkala saat layar chat terbuka); memanggil
  /// `notifyListeners()` hanya bila ada pesan baru atau pesan sendiri baru dibaca
  /// lawan (centang dua). Juga memperbarui [lawanMengetik].
  Future<void> periksaPesanBaru(String pasienId) async {}

  final _lawanMengetik = <String, ValueNotifier<bool>>{};

  /// `true` selama pihak lawan (admin bagi pasien, pasien bagi admin) sedang mengetik.
  /// Terpisah dari `notifyListeners()` agar daftar pesan tidak dimuat ulang.
  ValueNotifier<bool> lawanMengetik(String pasienId) =>
      _lawanMengetik.putIfAbsent(pasienId, () => ValueNotifier(false));

  /// Hapus semua status mengetik (mis. saat keluar akun).
  @protected
  void resetMengetik() {
    for (final n in _lawanMengetik.values) {
      n.value = false;
    }
  }

  /// Beri tahu lawan bahwa pengguna sedang mengetik (`aktif: false` saat kolom dikosongkan).
  /// Dipanggil paling sering tiap 3 detik selama mengetik.
  Future<void> kirimMengetik(String pasienId, {required bool aktif}) async {}

  // ---- Auth & akun
  Future<AppUser> loginPasien(String noHp, String sandi);
  Future<AppUser> loginAdmin(String username, String sandi);
  Future<AppUser> daftarAkun({required String nama, required String noHp, required String sandi});
  Future<void> logout();
  /// [sandiLama] wajib untuk admin (diperiksa server), tidak dipakai pasien.
  Future<void> ubahSandi(String userId, String sandiBaru, {String? sandiLama});

  /// Admin: ubah nama & email akun sendiri; mengembalikan data akun terbaru.
  Future<AppUser> ubahProfilAdmin({required String nama, required String email});

  /// Daftarkan token push FCM HP ini ke akun yang sedang masuk (lihat `core/push.dart`).
  Future<void> kirimTokenPerangkat(String token) async {}

  // ---- Pendaftaran (pasien)
  Future<List<Pendaftaran>> pendaftaranSaya(String userId);
  Future<Pendaftaran?> pendaftaran(String id);
  Future<Pendaftaran> daftarBerobat(FormPendaftaran form);

  /// Pasien melengkapi pendaftaran berstatus Perlu dilengkapi; status kembali Menunggu
  /// (catatan admin tetap). Di [form], `mediaKondisi` / `fotoKtp` berisi URL lama yang
  /// dipertahankan dan/atau path berkas baru di HP.
  Future<void> lengkapiPendaftaran(String id, FormPendaftaran form);

  // ---- Pengajuan (pasien): diputuskan admin, satu pengajuan menunggu per pendaftaran
  /// Minta pindah ke [tanggal] + [jam] (slot harus bersisa); hanya untuk yang dijadwalkan.
  Future<void> ajukanJadwalUlang(String pendaftaranId, DateTime tanggal, String jam, {String alasan = ''});

  /// Minta pembatalan; untuk pendaftaran menunggu / dijadwalkan.
  Future<void> ajukanBatal(String pendaftaranId, {String alasan = ''});

  /// Tarik pengajuan yang belum diputuskan admin.
  Future<void> tarikPengajuan(String pendaftaranId);

  // ---- Pendaftaran (admin)
  /// [hanyaPengajuan]: hanya pendaftaran yang punya pengajuan menunggu (status diabaikan).
  Future<List<Pendaftaran>> semuaPendaftaran({StatusPendaftaran? status, String cari = '', bool hanyaPengajuan = false});

  /// Jumlah pendaftaran per status (angka di filter, sama dengan panel web).
  Future<Map<StatusPendaftaran, int>> jumlahPendaftaran();

  /// Jumlah pengajuan jadwal ulang / pembatalan yang menunggu keputusan.
  Future<int> jumlahPengajuanMenunggu();

  /// Setujui: jadwal ulang → jadwal dipindah (cek kuota lagi); pembatalan → status Batal.
  Future<void> setujuiPengajuan(String pengajuanId);

  /// Tolak dengan alasan (wajib, dikirim ke pasien); pendaftaran tidak berubah.
  Future<void> tolakPengajuan(String pengajuanId, String alasan);

  /// Beri atau pindah jadwal; kirim notifikasi ke pasien.
  Future<void> jadwalkan(String id, DateTime tanggal, String jam);

  /// Tolak dengan alasan (wajib, dikirim ke pasien).
  Future<void> tolak(String id, String alasan);

  /// Minta pasien melengkapi (dari Menunggu / Perlu dilengkapi); catatan wajib, dikirim ke pasien.
  Future<void> mintaDilengkapi(String id, String catatan);

  /// Selesai / Tidak hadir / Batal untuk pendaftaran yang dijadwalkan.
  Future<void> ubahStatus(String id, StatusPendaftaran status);
  Future<void> kirimPengingat(String id);

  // ---- Slot jadwal
  // sisaKuotaPerTanggal & slotPada juga dipakai pasien untuk memilih jadwal ulang
  // (pasien hanya menerima slot aktif).
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
  /// Akun pasien terbaru dulu; [cari] mencocokkan nama atau nomor HP.
  Future<List<AppUser>> akunPasien({String cari = ''});
  /// Mengembalikan sandi sementara untuk dikirim admin ke pasien.
  Future<String> resetSandi(String userId);
  Future<void> aturAkunAktif(String userId, bool aktif);
  Future<List<MediaSosial>> mediaSosial();
  Future<void> simpanMediaSosial(List<MediaSosial> daftar);

  // ---- Info klinik (alamat, Maps, WA admin, biaya, website, kalimat jadwal)
  Future<InfoKlinik> infoKlinik();

  /// Hanya admin.
  Future<void> simpanInfoKlinik(InfoKlinik info);

  // ---- Gambar Info klinik: logo halaman Masuk & Daftar Akun, foto profil menu Info
  // (lihat [InfoKlinik.gambar]); hanya admin.
  /// Ganti gambar dengan berkas di [path] (jpg/png/webp, maks. 2 MB).
  Future<void> gantiGambar(JenisGambar jenis, String path);

  /// Kembali ke gambar bawaan aplikasi.
  Future<void> hapusGambar(JenisGambar jenis);
}

class RepositoryException implements Exception {
  RepositoryException(this.pesan, {this.kode});
  final String pesan;

  /// Kode status HTTP bila berasal dari server (mis. 404).
  final int? kode;
  @override
  String toString() => pesan;
}
