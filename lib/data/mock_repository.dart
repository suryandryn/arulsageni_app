import '../core/format.dart';
import '../models/models.dart';
import 'repository.dart';

/// Data contoh di memori. Hilang saat aplikasi ditutup.
///
/// Akun demo:
/// - Admin  : `admin` / `admin123`
/// - Pasien : `081234567890` / `123456`
class MockRepository extends Repository {
  MockRepository({DateTime Function()? now}) : _now = now ?? DateTime.now {
    _seed();
  }

  final DateTime Function() _now;
  final _users = <AppUser>[];
  final _password = <String, String>{}; // userId -> password
  final _pendaftaran = <Pendaftaran>[];
  final _pesan = <Pesan>[];
  final _notif = <Notifikasi>[];
  late KlinikInfo _klinik;
  late PengaturanJadwal _pengaturan;
  int _seq = 1000;

  String _id() => '${_seq++}';
  Future<void> _jeda() => Future<void>.delayed(const Duration(milliseconds: 200));

  void _ubah() => notifyListeners();

  // ---------------------------------------------------------------- seed

  void _seed() {
    _klinik = const KlinikInfo(
      nama: 'Padepokan Arul Sageni',
      pemilik: 'Kang Arul Sageni',
      alamat: 'Kp. Curug Rendeng RT 13 RW 04, Subang, Jawa Barat 41281',
      mapsUrl: 'https://maps.google.com/?q=Curug+Rendeng+Subang',
      waAdmin: '089522033857',
      estimasiBiaya: [
        'Pendaftaran Rp10.000, bayar di tempat.',
        'Pengobatan seikhlasnya untuk Kang Arul Sageni.',
        'Obat & vitamin Rp600.000 untuk segala macam penyakit medis/non-medis (6 produk).',
        'Semua biaya dibayar di tempat saat pengobatan.',
      ],
      mediaSosial: [
        MediaSosial(platform: 'YouTube', nama: 'PAGADEN PROJECT', url: 'https://youtube.com/@pagadenprojects'),
        MediaSosial(platform: 'Facebook', nama: 'PAGADEN PROJECT', url: 'https://www.facebook.com/share/1F7NfuC6So/'),
        MediaSosial(platform: 'TikTok', nama: 'PAGADEN PROJECT', url: 'https://www.tiktok.com/@pagaden_project'),
        MediaSosial(platform: 'TikTok', nama: 'KANG ARUL SAGENI', url: 'https://www.tiktok.com/@kang_arul_sageni'),
        MediaSosial(platform: 'Instagram', nama: 'RULZ_357', url: 'https://www.instagram.com/rulz_357'),
        MediaSosial(platform: 'Snack Video', nama: 'PAGADEN PROJECT', url: 'https://s.snackvideo.com/u/@Pagaden_Project/lvdG7xjf'),
      ],
      website: 'https://pengobatankangarulsageni.com',
    );

    final hariIni = tanggalSaja(_now());
    _pengaturan = PengaturanJadwal(
      kuotaPerHari: 30,
      hariPraktik: {1, 2, 3, 4, 5, 6},
      slotJam: const ['08:00', '09:00', '10:00', '13:00', '14:00', '15:00'],
      periodeAkhir: DateTime(hariIni.year + 2, hariIni.month, hariIni.day),
      tanggalKhusus: {},
    );

    _users.addAll(const [
      AppUser(id: '1', nama: 'Admin Padepokan', noWa: '089522033857', role: Role.admin),
      AppUser(id: '2', nama: 'Budi Santoso', noWa: '081234567890', role: Role.pasien),
      AppUser(id: '3', nama: 'Siti Aminah', noWa: '085711112222', role: Role.pasien),
      AppUser(id: '4', nama: 'Dedi Kurniawan', noWa: '087833334444', role: Role.pasien),
    ]);
    _password.addAll({'1': 'admin123', '2': '123456', '3': '123456', '4': '123456'});

    var tgl = hariIni.add(const Duration(days: 2));
    while (!_pengaturan.hariPraktik.contains(tgl.weekday)) {
      tgl = tgl.add(const Duration(days: 1));
    }
    _pendaftaran.addAll([
      Pendaftaran(
        id: _id(), kode: 'PAS-0001', userId: '2', nama: 'Budi Santoso',
        noWa: '081234567890', kota: 'Subang', keluhan: 'Sakit punggung bawah sejak 3 bulan.',
        mediaKondisi: const [], status: StatusPendaftaran.terjadwal,
        dibuat: hariIni.subtract(const Duration(days: 4)),
        jadwal: gabungJam(tgl, '09:00'), noAntrean: 1,
      ),
      Pendaftaran(
        id: _id(), kode: 'PAS-0002', userId: '3', nama: 'Siti Aminah',
        noWa: '085711112222', kota: 'Karawang', keluhan: 'Sering pusing dan susah tidur.',
        mediaKondisi: const [], status: StatusPendaftaran.menungguVerifikasi,
        dibuat: hariIni.subtract(const Duration(days: 1)),
      ),
      Pendaftaran(
        id: _id(), kode: 'PAS-0003', userId: '4', nama: 'Dedi Kurniawan',
        noWa: '087833334444', kota: 'Purwakarta', keluhan: 'Benjolan di leher.',
        mediaKondisi: const [], status: StatusPendaftaran.perluDilengkapi,
        catatanAdmin: 'Mohon kirim foto benjolan yang lebih jelas.',
        dibuat: hariIni.subtract(const Duration(days: 2)),
      ),
    ]);

    _pesan.addAll([
      Pesan(id: _id(), pasienId: '2', dariAdmin: false, isi: 'Assalamualaikum, apakah perlu puasa sebelum datang?', waktu: _now().subtract(const Duration(hours: 5))),
      Pesan(id: _id(), pasienId: '2', dariAdmin: true, isi: 'Waalaikumsalam, tidak perlu. Datang 15 menit sebelum jadwal ya.', waktu: _now().subtract(const Duration(hours: 4))),
      Pesan(id: _id(), pasienId: '3', dariAdmin: false, isi: 'Kapan pendaftaran saya diperiksa?', waktu: _now().subtract(const Duration(minutes: 30))),
    ]);

    _notif.add(Notifikasi(
      id: _id(), userId: '2', judul: 'Jadwal berobat diberikan',
      isi: 'PAS-0001: ${fmtTanggal(tgl)} pukul 09:00, antrean no. 1.',
      waktu: hariIni.subtract(const Duration(days: 3)),
    ));
  }

  // ---------------------------------------------------------------- helper

  int _cariIndex(String id) {
    final i = _pendaftaran.indexWhere((p) => p.id == id);
    if (i < 0) throw RepositoryException('Pendaftaran tidak ditemukan.');
    return i;
  }

  void _notifikasi(String userId, String judul, String isi) {
    _notif.insert(0, Notifikasi(id: _id(), userId: userId, judul: judul, isi: isi, waktu: _now()));
  }

  int _kuota(DateTime tanggal) {
    final t = tanggalSaja(tanggal);
    final khusus = _pengaturan.tanggalKhusus[t];
    if (khusus != null) return khusus;
    if (!_pengaturan.hariPraktik.contains(t.weekday)) return 0;
    return _pengaturan.kuotaPerHari;
  }

  List<Pendaftaran> _terjadwalPada(DateTime tanggal) {
    final t = tanggalSaja(tanggal);
    return _pendaftaran
        .where((p) =>
            p.jadwal != null &&
            tanggalSaja(p.jadwal!) == t &&
            (p.status == StatusPendaftaran.terjadwal ||
                p.status == StatusPendaftaran.selesai ||
                p.status == StatusPendaftaran.tidakHadir))
        .toList()
      ..sort((a, b) => (a.noAntrean ?? 0).compareTo(b.noAntrean ?? 0));
  }

  String _normalWa(String wa) => wa.replaceAll(RegExp(r'[^0-9]'), '');

  // ---------------------------------------------------------------- auth

  @override
  Future<AppUser> login(String identitas, String password) async {
    await _jeda();
    final id = identitas.trim().toLowerCase();
    final user = _users.where((u) {
      if (u.isAdmin && id == 'admin') return true;
      return _normalWa(u.noWa) == _normalWa(id) && id.isNotEmpty;
    }).firstOrNull;
    if (user == null || _password[user.id] != password) {
      throw RepositoryException('Nomor WhatsApp atau kata sandi salah.');
    }
    return user;
  }

  @override
  Future<AppUser> register({required String nama, required String noWa, required String password}) async {
    await _jeda();
    if (_users.any((u) => _normalWa(u.noWa) == _normalWa(noWa))) {
      throw RepositoryException('Nomor WhatsApp sudah terdaftar. Silakan masuk.');
    }
    final user = AppUser(id: _id(), nama: nama.trim(), noWa: _normalWa(noWa), role: Role.pasien);
    _users.add(user);
    _password[user.id] = password;
    _ubah();
    return user;
  }

  @override
  Future<void> logout() async => _jeda();

  // ---------------------------------------------------------------- klinik

  @override
  Future<KlinikInfo> klinik() async => _klinik;

  @override
  Future<void> simpanKlinik(KlinikInfo info) async {
    await _jeda();
    _klinik = info;
    _ubah();
  }

  @override
  Future<PengaturanJadwal> pengaturan() async => _pengaturan;

  @override
  Future<void> simpanPengaturan(PengaturanJadwal pengaturan) async {
    await _jeda();
    _pengaturan = pengaturan;
    _ubah();
  }

  @override
  Future<void> perpanjangPeriode(int tahun) async {
    final a = _pengaturan.periodeAkhir;
    await simpanPengaturan(_pengaturan.copyWith(periodeAkhir: DateTime(a.year + tahun, a.month, a.day)));
  }

  // ---------------------------------------------------------------- pasien

  @override
  Future<List<Pendaftaran>> pendaftaranSaya(String userId) async {
    await _jeda();
    return _pendaftaran.where((p) => p.userId == userId).toList()
      ..sort((a, b) => b.dibuat.compareTo(a.dibuat));
  }

  @override
  Future<Pendaftaran?> pendaftaran(String id) async =>
      _pendaftaran.where((p) => p.id == id).firstOrNull;

  @override
  Future<Pendaftaran> daftarBerobat(FormPendaftaran form) async {
    await _jeda();
    if (form.mediaKondisi.isEmpty) {
      throw RepositoryException('Foto atau video kondisi pasien wajib dilampirkan.');
    }
    final p = Pendaftaran(
      id: _id(),
      kode: 'PAS-${(_pendaftaran.length + 1).toString().padLeft(4, '0')}',
      userId: form.userId,
      nama: form.nama,
      noWa: _normalWa(form.noWa),
      kota: form.kota,
      keluhan: form.keluhan,
      mediaKondisi: form.mediaKondisi,
      fotoKtp: form.fotoKtp,
      status: StatusPendaftaran.menungguVerifikasi,
      dibuat: _now(),
    );
    _pendaftaran.add(p);
    _notifikasi(form.userId, 'Pendaftaran diterima', '${p.kode} sedang menunggu verifikasi admin.');
    _ubah();
    return p;
  }

  @override
  Future<void> lengkapiData(String id, String keterangan) async {
    await _jeda();
    final i = _cariIndex(id);
    _pendaftaran[i] = _pendaftaran[i].copyWith(
      status: StatusPendaftaran.menungguVerifikasi,
      catatanAdmin: 'Pasien melengkapi: $keterangan',
    );
    _ubah();
  }

  @override
  Future<void> ajukanJadwalUlang(String id, String alasan) async {
    await _jeda();
    final i = _cariIndex(id);
    _pendaftaran[i] = _pendaftaran[i].copyWith(
      status: StatusPendaftaran.menungguVerifikasi,
      catatanAdmin: 'Pasien mengajukan jadwal ulang: $alasan',
      hapusJadwal: true,
    );
    _ubah();
  }

  @override
  Future<void> batalkan(String id) async {
    await _jeda();
    final i = _cariIndex(id);
    _pendaftaran[i] = _pendaftaran[i].copyWith(status: StatusPendaftaran.dibatalkan, hapusJadwal: true);
    _ubah();
  }

  // ---------------------------------------------------------------- admin

  @override
  Future<List<Pendaftaran>> semuaPendaftaran({StatusPendaftaran? status}) async {
    await _jeda();
    return _pendaftaran.where((p) => status == null || p.status == status).toList()
      ..sort((a, b) => b.dibuat.compareTo(a.dibuat));
  }

  @override
  Future<void> jadwalkan(String id, DateTime waktu) async {
    await _jeda();
    final terisi = _terjadwalPada(waktu).where((p) => p.id != id).toList();
    if (terisi.length >= _kuota(waktu)) {
      throw RepositoryException('Kuota tanggal ${fmtTanggalPendek(waktu)} sudah penuh.');
    }
    final antrean = terisi.fold<int>(0, (m, p) => (p.noAntrean ?? 0) > m ? p.noAntrean! : m) + 1;
    final i = _cariIndex(id);
    final p = _pendaftaran[i].copyWith(status: StatusPendaftaran.terjadwal, jadwal: waktu, noAntrean: antrean);
    _pendaftaran[i] = p;
    _notifikasi(p.userId, 'Jadwal berobat diberikan',
        '${p.kode}: ${fmtTanggal(waktu)} pukul ${fmtJam(waktu)}, antrean no. $antrean.');
    _ubah();
  }

  @override
  Future<void> mintaLengkapi(String id, String catatan) async {
    await _jeda();
    final i = _cariIndex(id);
    final p = _pendaftaran[i].copyWith(status: StatusPendaftaran.perluDilengkapi, catatanAdmin: catatan);
    _pendaftaran[i] = p;
    _notifikasi(p.userId, 'Data perlu dilengkapi', '${p.kode}: $catatan');
    _ubah();
  }

  @override
  Future<void> tolak(String id, String catatan) async {
    await _jeda();
    final i = _cariIndex(id);
    final p = _pendaftaran[i].copyWith(
        status: StatusPendaftaran.tidakDapatDitangani, catatanAdmin: catatan, hapusJadwal: true);
    _pendaftaran[i] = p;
    _notifikasi(p.userId, 'Pendaftaran tidak dapat ditangani', '${p.kode}: $catatan');
    _ubah();
  }

  @override
  Future<void> tandaiSelesai(String id) async {
    await _jeda();
    final i = _cariIndex(id);
    _pendaftaran[i] = _pendaftaran[i].copyWith(status: StatusPendaftaran.selesai);
    _ubah();
  }

  @override
  Future<void> tandaiTidakHadir(String id) async {
    await _jeda();
    final i = _cariIndex(id);
    _pendaftaran[i] = _pendaftaran[i].copyWith(status: StatusPendaftaran.tidakHadir);
    _ubah();
  }

  @override
  Future<void> kirimPengingat(String id) async {
    await _jeda();
    final p = _pendaftaran[_cariIndex(id)];
    if (p.jadwal == null) return;
    _notifikasi(p.userId, 'Pengingat jadwal berobat',
        '${fmtTanggal(p.jadwal!)} pukul ${fmtJam(p.jadwal!)}, antrean no. ${p.noAntrean}.');
    _ubah();
  }

  // ---------------------------------------------------------------- jadwal

  @override
  Future<List<Pendaftaran>> jadwalPada(DateTime tanggal) async {
    await _jeda();
    return _terjadwalPada(tanggal);
  }

  @override
  Future<int> kuotaPada(DateTime tanggal) async => _kuota(tanggal);

  @override
  Future<Set<DateTime>> tanggalTersedia() async {
    final hasil = <DateTime>{};
    var t = tanggalSaja(_now());
    final akhir = tanggalSaja(_pengaturan.periodeAkhir);
    while (!t.isAfter(akhir)) {
      final kuota = _kuota(t);
      if (kuota > 0 && _terjadwalPada(t).length < kuota) hasil.add(t);
      t = DateTime(t.year, t.month, t.day + 1);
    }
    return hasil;
  }

  // ---------------------------------------------------------------- chat

  @override
  Future<List<Pesan>> pesan(String pasienId) async =>
      _pesan.where((m) => m.pasienId == pasienId).toList()
        ..sort((a, b) => a.waktu.compareTo(b.waktu));

  @override
  Future<void> kirimPesan(String pasienId, String isi, {required bool dariAdmin}) async {
    _pesan.add(Pesan(id: _id(), pasienId: pasienId, dariAdmin: dariAdmin, isi: isi.trim(), waktu: _now()));
    if (dariAdmin) _notifikasi(pasienId, 'Pesan dari admin', isi.trim());
    _ubah();
  }

  @override
  Future<List<Percakapan>> percakapan() async {
    final terakhir = <String, Pesan>{};
    for (final m in _pesan) {
      final ada = terakhir[m.pasienId];
      if (ada == null || m.waktu.isAfter(ada.waktu)) terakhir[m.pasienId] = m;
    }
    final hasil = terakhir.entries
        .map((e) => Percakapan(pasien: _users.firstWhere((u) => u.id == e.key), terakhir: e.value))
        .toList()
      ..sort((a, b) => b.terakhir.waktu.compareTo(a.terakhir.waktu));
    return hasil;
  }

  // ---------------------------------------------------------------- notifikasi

  @override
  Future<List<Notifikasi>> notifikasi(String userId) async =>
      _notif.where((n) => n.userId == userId).toList();

  @override
  Future<void> tandaiNotifikasiDibaca(String userId) async {
    var berubah = false;
    for (var i = 0; i < _notif.length; i++) {
      final n = _notif[i];
      if (n.userId == userId && !n.dibaca) {
        _notif[i] = Notifikasi(id: n.id, userId: n.userId, judul: n.judul, isi: n.isi, waktu: n.waktu, dibaca: true);
        berubah = true;
      }
    }
    if (berubah) _ubah();
  }

  // ---------------------------------------------------------------- ringkas

  @override
  Future<RingkasAdmin> ringkas() async {
    final besok = tanggalSaja(_now()).add(const Duration(days: 1));
    return RingkasAdmin(
      menunggu: _pendaftaran.where((p) => p.status == StatusPendaftaran.menungguVerifikasi).length,
      jadwalBesok: _terjadwalPada(besok).where((p) => p.status == StatusPendaftaran.terjadwal).length,
      totalTerdaftar: _users.where((u) => u.role == Role.pasien).length,
      chatTerbaru: (await percakapan()).take(5).toList(),
    );
  }
}
