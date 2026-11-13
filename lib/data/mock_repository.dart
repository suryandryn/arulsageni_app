import '../core/format.dart';
import '../core/klinik.dart';
import '../models/models.dart';
import '../widgets/media.dart' show adalahVideo;
import 'repository.dart';

/// Data contoh di memori, sama dengan isi demo desain. Hilang saat aplikasi ditutup.
///
/// Akun demo:
/// - Pasien : `0812-3456-7890` / `123456`
/// - Admin  : `admin` / `123456`
class MockRepository extends Repository {
  MockRepository({DateTime Function()? now}) : _now = now ?? DateTime.now {
    _seed();
  }

  static const jamAwal = ['08.00', '10.00', '13.00', '15.00'];

  final DateTime Function() _now;
  final _users = <AppUser>[];
  final _sandi = <String, String>{}; // userId -> sandi
  final _daftar = <Pendaftaran>[];
  final _slot = <(DateTime, String), ({int kuota, bool aktif})>{};
  final _pesan = <Pesan>[];
  final _notif = <Notifikasi>[];
  var _medsos = <MediaSosial>[];
  var _info = InfoKlinik.bawaan;
  int _seq = 200;

  /// Urutan waktu dijadwalkan admin per pendaftaran (dasar nomor antrean).
  final _urutJadwal = <String, int>{};
  int _seqJadwal = 0;

  String _id() => '${_seq++}';
  Future<void> _jeda() => Future<void>.delayed(const Duration(milliseconds: 150));
  void _ubah() => notifyListeners();

  DateTime get _hariIni => tanggalSaja(_now());
  DateTime _hr(int n) => DateTime(_hariIni.year, _hariIni.month, _hariIni.day + n);

  /// Hari ke-n dari sekarang, dilewati bila Minggu.
  DateTime _hariPraktik(int n) {
    var d = _hr(n);
    while (d.weekday == DateTime.sunday) {
      d = DateTime(d.year, d.month, d.day + 1);
    }
    return d;
  }

  static String _digit(String s) => s.replaceAll(RegExp(r'\D'), '');

  static String _nhp(String s) {
    final d = s.replaceAll(RegExp(r'\D'), '');
    if (d.startsWith('62')) return d;
    if (d.startsWith('0')) return '62${d.substring(1)}';
    return '62$d';
  }

  // ------------------------------------------------------------------ seed

  void _seed() {
    _users.addAll(const [
      AppUser(id: '1', nama: 'Admin', noHp: 'admin', role: Role.admin),
      AppUser(id: '2', nama: 'Siti Rahmawati', noHp: '0812-3456-7890', role: Role.pasien),
      AppUser(id: '3', nama: 'Hendra Wijaya', noHp: '0813-1122-3344', role: Role.pasien),
      AppUser(id: '4', nama: 'Ibu Marni', noHp: '0857-9988-1200', role: Role.pasien),
      AppUser(id: '5', nama: 'Agus Pratama', noHp: '0821-4455-6677', role: Role.pasien),
      AppUser(id: '6', nama: 'Pak Slamet', noHp: '0852-7766-5544', role: Role.pasien),
    ]);
    for (final u in _users) {
      _sandi[u.id] = '123456';
    }

    _medsos = const [
      MediaSosial(
        platform: 'YouTube',
        nama: 'PAGADEN PROJECT',
        url: 'https://youtube.com/@pagadenprojects?si=cU43qzym_nPpe798',
      ),
      MediaSosial(platform: 'Facebook', nama: 'PAGADEN PROJECT', url: 'https://www.facebook.com/share/1F7NfuC6So/'),
      MediaSosial(
        platform: 'TikTok',
        nama: 'PAGADEN PROJECT',
        url: 'https://www.tiktok.com/@pagaden_project?_r=1&_t=ZS-9B5cEG2Ra7g',
      ),
      MediaSosial(
        platform: 'TikTok',
        nama: 'KANG ARUL SAGENI',
        url: 'https://www.tiktok.com/@kang_arul_sageni?_r=1&_t=ZS-9B5cJNLA78e',
      ),
      MediaSosial(
        platform: 'Instagram',
        nama: 'RULZ_357',
        url: 'https://www.instagram.com/rulz_357?psln=MWNnamxseWN2bTcyZg==',
      ),
      MediaSosial(
        platform: 'Snack Video',
        nama: 'PAGADEN PROJECT',
        url: 'https://s.snackvideo.com/u/@Pagaden_Project/lvdG7xjf',
      ),
    ];

    _isiSlot(_hr(1), _hr(730), {1, 2, 3, 4, 5, 6}, jamAwal, 3);

    const m = ['foto_kondisi.jpg', 'foto_kondisi_2.jpg', 'video_kondisi.mp4'];
    Pendaftaran p(
      String id,
      String uid,
      String nama,
      int umur,
      String alamat,
      String hp,
      String keluhan,
      List<String> kond,
      StatusPendaftaran st,
      int dibuat, {
      DateTime? tgl,
      String? jam,
      String? alasan,
    }) => Pendaftaran(
      id: id,
      userId: uid,
      nama: nama,
      umur: umur,
      alamat: alamat,
      noHp: hp,
      keluhan: keluhan,
      mediaKondisi: kond,
      fotoKtp: 'ktp_${nama.replaceFirst(RegExp(r'^(Ibu|Pak) '), '').split(' ').first.toLowerCase()}.jpg',
      status: st,
      dibuat: _hr(dibuat),
      tanggal: tgl,
      jam: jam,
      alasan: alasan,
    );
    _daftar.addAll([
      p(
        '101',
        '3',
        'Hendra Wijaya',
        47,
        'Kec. Pagaden, Subang',
        '0813-1122-3344',
        'Nyeri punggung bawah sudah 3 bulan, sulit duduk lama.',
        m,
        StatusPendaftaran.menunggu,
        -2,
      ),
      p(
        '102',
        '4',
        'Ibu Marni',
        58,
        'Kab. Garut',
        '0857-9988-1200',
        'Sering pusing dan tensi naik turun.',
        m.sublist(0, 1),
        StatusPendaftaran.menunggu,
        -1,
      ),
      p(
        '103',
        '5',
        'Agus Pratama',
        39,
        'Kota Bandung',
        '0821-4455-6677',
        'Asam urat kambuh, lutut bengkak.',
        m,
        StatusPendaftaran.dijadwalkan,
        -30,
        tgl: _hariPraktik(1),
        jam: '08.00',
      ),
      p(
        '104',
        '5',
        'Ibu Wati (ibu Agus)',
        66,
        'Kota Bandung',
        '0821-4455-6677',
        'Gangguan lambung, mual tiap pagi.',
        m.sublist(1),
        StatusPendaftaran.dijadwalkan,
        -28,
        tgl: _hariPraktik(300),
        jam: '13.00',
      ),
      p(
        '100',
        '2',
        'Siti Rahmawati',
        42,
        'Kec. Jalan Cagak, Subang',
        '0812-3456-7890',
        'Sakit kepala menahun dan sulit tidur.',
        m.sublist(0, 2),
        StatusPendaftaran.dijadwalkan,
        -40,
        tgl: _hariPraktik(14),
        jam: '10.00',
      ),
      p(
        '105',
        '6',
        'Pak Slamet',
        61,
        'Kota Cimahi',
        '0852-7766-5544',
        'Penyakit berat, sudah stadium lanjut.',
        m.sublist(0, 1),
        StatusPendaftaran.ditolak,
        -10,
        alasan: 'Mohon maaf, berdasarkan foto kondisi, keluhan ini belum dapat kami tangani.',
      ),
    ]);
    // Nomor antrean awal: urut tanggal dibuat.
    for (final x
        in _daftar.where((x) => x.status == StatusPendaftaran.dijadwalkan).toList()
          ..sort((a, b) => a.dibuat.compareTo(b.dibuat))) {
      _urutJadwal[x.id] = _seqJadwal++;
    }
    for (final t in _daftar.map((x) => x.tanggal).whereType<DateTime>().toSet()) {
      _susunUlang(t);
    }
    // Contoh pendaftaran yang diminta dilengkapi (akun demo Siti).
    _daftar.add(
      p(
        '106',
        '2',
        'Bapak Ujang (ayah Siti)',
        70,
        'Kec. Jalan Cagak, Subang',
        '0812-3456-7890',
        'Lutut sering nyeri saat berjalan.',
        m.sublist(0, 1),
        StatusPendaftaran.perluDilengkapi,
        -3,
      ).copyWith(catatan: 'Foto kondisi lutut kurang jelas, mohon kirim foto dari dekat.'),
    );
    // Contoh pengajuan jadwal ulang yang menunggu keputusan admin.
    _ajukan(
      _cari('103'),
      JenisPengajuan.jadwalUlang,
      'Ada acara keluarga, mohon dipindah.',
      tanggal: _hariPraktik(7),
      jam: '10.00',
    );

    final awal = DateTime(_hariIni.year, _hariIni.month, _hariIni.day - 10, 9, 12);
    _pesan.addAll([
      Pesan(
        id: _id(),
        pasienId: '3',
        dariAdmin: false,
        isi: 'Assalamualaikum, apakah video kondisi saya sudah diterima?',
        waktu: awal,
      ),
      Pesan(
        id: _id(),
        pasienId: '2',
        dariAdmin: true,
        isi: 'Selamat datang. Silakan tanya di sini, admin akan membalas.',
        waktu: awal,
        dibaca: true,
      ),
    ]);
  }

  (int, int) _isiSlot(DateTime mulai, DateTime sampai, Set<int> hari, List<String> jam, int kuota) {
    var baru = 0, ada = 0;
    for (var d = tanggalSaja(mulai); !d.isAfter(sampai); d = DateTime(d.year, d.month, d.day + 1)) {
      if (!hari.contains(d.weekday % 7)) continue;
      for (final j in jam) {
        if (_slot.containsKey((d, j))) {
          ada++;
        } else {
          _slot[(d, j)] = (kuota: kuota, aktif: true);
          baru++;
        }
      }
    }
    return (baru, ada);
  }

  // ------------------------------------------------------------------ helper

  int _cari(String id) {
    final i = _daftar.indexWhere((p) => p.id == id);
    if (i < 0) throw RepositoryException('Pendaftaran tidak ditemukan.');
    return i;
  }

  int _terisi(DateTime t, [String? jam]) => _daftar
      .where((p) => p.status == StatusPendaftaran.dijadwalkan && p.tanggal == t && (jam == null || p.jam == jam))
      .length;

  void _kirimNotif(String userId, String judul, String isi) {
    _notif.insert(0, Notifikasi(id: _id(), userId: userId, judul: judul, isi: isi, waktu: _now()));
  }

  /// Catatan/alasan admin tanpa titik di akhir, agar tidak dobel saat disambung kalimat.
  static String _tanpaTitik(String s) => s.trim().replaceFirst(RegExp(r'\.+$'), '');

  AppUser _user(String id) => _users.firstWhere((u) => u.id == id);

  // ------------------------------------------------------------------ auth

  @override
  Future<AppUser> loginPasien(String noHp, String sandi) async {
    await _jeda();
    final u = _users.where((u) => !u.isAdmin && _nhp(u.noHp) == _nhp(noHp)).firstOrNull;
    if (u == null || _sandi[u.id] != sandi) throw RepositoryException('Nomor HP atau sandi salah.');
    if (!u.aktif) throw RepositoryException('Akun nonaktif. Hubungi admin lewat WhatsApp.');
    return u;
  }

  @override
  Future<AppUser> loginAdmin(String username, String sandi) async {
    await _jeda();
    final u = _users.firstWhere((u) => u.isAdmin);
    if (username.trim() != 'admin' || _sandi[u.id] != sandi) {
      throw RepositoryException('Nama pengguna atau sandi salah.');
    }
    return u;
  }

  @override
  Future<AppUser> daftarAkun({required String nama, required String noHp, required String sandi}) async {
    await _jeda();
    if (_nhp(noHp).length < 10) throw RepositoryException('Nomor HP tidak valid. Periksa kembali nomor HP.');
    if (_users.any((u) => !u.isAdmin && _nhp(u.noHp) == _nhp(noHp))) {
      throw RepositoryException('Nomor sudah terdaftar. Silakan masuk dengan nomor ini.');
    }
    final u = AppUser(id: _id(), nama: nama.trim(), noHp: noHp.trim(), role: Role.pasien);
    _users.add(u);
    _sandi[u.id] = sandi;
    _ubah();
    return u;
  }

  @override
  Future<void> logout() async {}

  @override
  Future<void> ubahSandi(String userId, String sandiBaru, {String? sandiLama}) async {
    await _jeda();
    if (_user(userId).isAdmin && _sandi[userId] != sandiLama) throw RepositoryException('Kata sandi lama salah.');
    if (sandiBaru.length < 6) throw RepositoryException('Kata sandi minimal 6 karakter.');
    _sandi[userId] = sandiBaru;
  }

  @override
  Future<AppUser> ubahProfilAdmin({required String nama, required String email}) async {
    await _jeda();
    if (nama.trim().isEmpty) throw RepositoryException('Isi nama.');
    final e = email.trim();
    if (e.isNotEmpty && !RegExp(r'^\S+@\S+\.\S+$').hasMatch(e)) throw RepositoryException('Format email tidak valid.');
    final i = _users.indexWhere((u) => u.isAdmin);
    _users[i] = AppUser(
      id: _users[i].id,
      nama: nama.trim(),
      noHp: _users[i].noHp,
      role: Role.admin,
      email: e.isEmpty ? null : e,
    );
    return _users[i];
  }

  // ------------------------------------------------------------------ pendaftaran

  List<Pendaftaran> _urut(Iterable<Pendaftaran> it) =>
      it.toList()..sort((a, b) => int.parse(b.id).compareTo(int.parse(a.id)));

  @override
  Future<List<Pendaftaran>> pendaftaranSaya(String userId) async => _urut(_daftar.where((p) => p.userId == userId));

  @override
  Future<Pendaftaran?> pendaftaran(String id) async {
    final p = _daftar.where((p) => p.id == id).firstOrNull;
    return p?.copyWith(namaAkun: _users.where((u) => u.id == p.userId).firstOrNull?.nama);
  }

  static void _cekMedia(List<String> kondisi) {
    final video = kondisi.where(adalahVideo).length;
    final foto = kondisi.length - video;
    if (kondisi.isEmpty) throw RepositoryException('Unggah minimal 1 foto/video kondisi.');
    if (foto > 5 || video > 1) throw RepositoryException('Maks. 5 foto dan 1 video.');
  }

  @override
  Future<void> lengkapiPendaftaran(String id, FormPendaftaran f) async {
    await _jeda();
    final i = _cari(id);
    if (!_daftar[i].bisaDilengkapi) throw RepositoryException('Pendaftaran ini tidak sedang diminta dilengkapi.');
    _cekMedia(f.mediaKondisi);
    _daftar[i] = _daftar[i].copyWith(
      nama: f.nama.trim(),
      umur: f.umur,
      alamat: f.alamat.trim(),
      noHp: f.noHp.trim(),
      keluhan: f.keluhan.trim(),
      mediaKondisi: List.of(f.mediaKondisi),
      fotoKtp: f.fotoKtp,
      status: StatusPendaftaran.menunggu,
      dilengkapi: _now(),
    );
    _ubah();
  }

  @override
  Future<void> mintaDilengkapi(String id, String catatan) async {
    await _jeda();
    if (catatan.trim().isEmpty) throw RepositoryException('Tulis apa yang perlu dilengkapi pasien.');
    final i = _cari(id);
    final x = _daftar[i];
    if (x.status != StatusPendaftaran.menunggu && x.status != StatusPendaftaran.perluDilengkapi) {
      throw RepositoryException('Hanya pendaftaran yang menunggu yang bisa diminta dilengkapi.');
    }
    _daftar[i] = x.copyWith(status: StatusPendaftaran.perluDilengkapi, catatan: catatan.trim());
    _kirimNotif(
      x.userId,
      'Mohon lengkapi data pendaftaran',
      'Pendaftaran a.n. ${x.nama} memerlukan kelengkapan: ${_tanpaTitik(catatan)}. '
          'Silakan perbarui melalui menu Pendaftaran.',
    );
    _ubah();
  }

  @override
  Future<Pendaftaran> daftarBerobat(FormPendaftaran f) async {
    await _jeda();
    _cekMedia(f.mediaKondisi);
    final p = Pendaftaran(
      id: _id(),
      userId: f.userId,
      nama: f.nama.trim(),
      umur: f.umur,
      alamat: f.alamat.trim(),
      noHp: f.noHp.trim(),
      keluhan: f.keluhan.trim(),
      mediaKondisi: f.mediaKondisi,
      fotoKtp: f.fotoKtp,
      status: StatusPendaftaran.menunggu,
      dibuat: _hariIni,
    );
    _daftar.add(p);
    _ubah();
    return p;
  }

  @override
  Future<List<Pendaftaran>> semuaPendaftaran({
    StatusPendaftaran? status,
    String cari = '',
    bool hanyaPengajuan = false,
  }) async {
    final q = cari.trim().toLowerCase();
    return _urut(
      _daftar.where(
        (p) =>
            (hanyaPengajuan ? p.pengajuanMenunggu != null : (status == null || p.status == status)) &&
            (q.isEmpty || '${p.nama} ${p.noHp}'.toLowerCase().contains(q)),
      ),
    );
  }

  @override
  Future<Map<StatusPendaftaran, int>> jumlahPendaftaran() async => {
    for (final s in StatusPendaftaran.values) s: _daftar.where((p) => p.status == s).length,
  };

  @override
  Future<void> jadwalkan(String id, DateTime tanggal, String jam) async {
    await _jeda();
    _jadwalkan(_cari(id), tanggal, jam);
    _ubah();
  }

  void _jadwalkan(int i, DateTime tanggal, String jam, {bool jadwalUlang = false}) {
    final t = tanggalSaja(tanggal);
    final x = _daftar[i];
    final s = _slot[(t, jam)];
    final sama = x.status == StatusPendaftaran.dijadwalkan && x.tanggal == t && x.jam == jam;
    if (s == null || !s.aktif || (!sama && s.kuota - _terisi(t, jam) < 1)) {
      throw RepositoryException('Kuota penuh. Pilih jam lain.');
    }
    final pindah = x.status == StatusPendaftaran.dijadwalkan;
    final tanggalLama = pindah ? x.tanggal : null;
    // Pindah jam di tanggal yang sama tetap di posisinya; selain itu masuk paling belakang.
    if (tanggalLama != t) _urutJadwal[x.id] = _seqJadwal++;
    _daftar[i] = x.copyWith(
      status: StatusPendaftaran.dijadwalkan,
      tanggal: t,
      jam: jam,
      nomorAntrean: tanggalLama == t ? x.nomorAntrean : null,
    );
    _susunUlang(t, kecuali: x.id);
    if (tanggalLama != null && tanggalLama != t) _susunUlang(tanggalLama);
    final tgl = fmtTanggal(t);
    final antrean = 'Nomor antrean ${_daftar[i].nomorAntrean}.';
    final (judul, isi) = jadwalUlang
        ? ('Pengajuan jadwal ulang disetujui', 'Jadwal baru a.n. ${x.nama}: $tgl, pukul $jam WIB. $antrean')
        : pindah
        ? ('Jadwal berobat diperbarui', 'Jadwal berobat a.n. ${x.nama} dipindahkan ke $tgl, pukul $jam WIB. $antrean')
        : (
            'Jadwal berobat sudah ditetapkan',
            'Jadwal berobat a.n. ${x.nama}: $tgl, pukul $jam WIB di ${Klinik.nama}. $antrean',
          );
    _kirimNotif(x.userId, judul, isi);
  }

  static const _statusAntrean = {
    StatusPendaftaran.dijadwalkan,
    StatusPendaftaran.selesai,
    StatusPendaftaran.tidakHadir,
  };

  /// Susun ulang nomor antrean satu tanggal (sama dengan AntreanService di server);
  /// pasien terjadwal yang nomornya berubah diberi notifikasi.
  void _susunUlang(DateTime t, {String? kecuali}) {
    final ids = _daftar.where((x) => x.tanggal == t && _statusAntrean.contains(x.status)).map((x) => x.id).toList()
      ..sort((a, b) => (_urutJadwal[a] ?? 1 << 30).compareTo(_urutJadwal[b] ?? 1 << 30));
    for (var n = 0; n < ids.length; n++) {
      final i = _cari(ids[n]);
      final x = _daftar[i];
      final lama = x.nomorAntrean;
      if (lama == n + 1) continue;
      _daftar[i] = x.copyWith(nomorAntrean: n + 1);
      if (lama != null && x.status == StatusPendaftaran.dijadwalkan && x.id != kecuali) {
        _kirimNotif(
          x.userId,
          'Nomor antrean diperbarui',
          'Nomor antrean a.n. ${x.nama} untuk ${fmtTanggal(t)} pukul ${x.jam} WIB kini ${n + 1} '
              '(sebelumnya $lama). Jadwal Anda tidak berubah.',
        );
      }
    }
  }

  /// Lepas nomor bila pendaftaran keluar dari antrean (batal / ditolak), lalu susun ulang.
  void _perbaruiAntrean(int i) {
    final x = _daftar[i];
    if (_statusAntrean.contains(x.status) || x.nomorAntrean == null) return;
    _daftar[i] = x.copyWith(nomorAntrean: null);
    if (x.tanggal != null) _susunUlang(x.tanggal!);
  }

  @override
  Future<void> tolak(String id, String alasan) async {
    await _jeda();
    if (alasan.trim().isEmpty) throw RepositoryException('Tulis alasan penolakan untuk pasien.');
    final i = _cari(id);
    _daftar[i] = _tutupPengajuan(_daftar[i].copyWith(status: StatusPendaftaran.ditolak, alasan: alasan.trim()));
    _perbaruiAntrean(i);
    _kirimNotif(
      _daftar[i].userId,
      'Pendaftaran belum dapat diproses',
      'Mohon maaf, pendaftaran a.n. ${_daftar[i].nama} belum dapat kami proses. Alasan: ${_tanpaTitik(alasan)}. '
          'Silakan hubungi admin melalui Chat bila ada pertanyaan.',
    );
    _ubah();
  }

  @override
  Future<void> ubahStatus(String id, StatusPendaftaran status) async {
    await _jeda();
    final i = _cari(id);
    _daftar[i] = _tutupPengajuan(_daftar[i].copyWith(status: status));
    _perbaruiAntrean(i);
    _ubah();
  }

  // ------------------------------------------------------------------ pengajuan

  /// Pengajuan menunggu ditutup bila admin mengubah status lewat tindakan lain (sama dengan server).
  Pendaftaran _tutupPengajuan(Pendaftaran p) {
    final a = p.pengajuanMenunggu;
    if (a == null) return p;
    return p.copyWith(
      pengajuan: a.copyWith(
        status: StatusPengajuan.ditolak,
        alasanTolak: 'Status pendaftaran sudah diubah admin (${p.status.label}).',
      ),
    );
  }

  int _cariPengajuan(String pengajuanId) {
    final i = _daftar.indexWhere((p) => p.pengajuan?.id == pengajuanId);
    if (i < 0) throw RepositoryException('Pengajuan tidak ditemukan.');
    if (_daftar[i].pengajuanMenunggu == null) {
      throw RepositoryException('Pengajuan sudah ${_daftar[i].pengajuan!.status.label.toLowerCase()}.');
    }
    return i;
  }

  void _ajukan(int i, JenisPengajuan jenis, String alasan, {DateTime? tanggal, String? jam}) {
    _daftar[i] = _daftar[i].copyWith(
      pengajuan: Pengajuan(
        id: _id(),
        jenis: jenis,
        status: StatusPengajuan.menunggu,
        dibuat: _now(),
        tanggal: tanggal,
        jam: jam,
        alasan: alasan.trim().isEmpty ? null : alasan.trim(),
      ),
    );
  }

  @override
  Future<void> ajukanJadwalUlang(String pendaftaranId, DateTime tanggal, String jam, {String alasan = ''}) async {
    await _jeda();
    final i = _cari(pendaftaranId);
    final x = _daftar[i];
    if (x.pengajuanMenunggu != null) throw RepositoryException('Masih ada pengajuan yang menunggu persetujuan admin.');
    if (x.status != StatusPendaftaran.dijadwalkan) {
      throw RepositoryException('Jadwal ulang hanya untuk pendaftaran yang sudah dijadwalkan.');
    }
    final t = tanggalSaja(tanggal);
    if (!t.isAfter(_hariIni)) throw RepositoryException('Tanggal baru harus setelah hari ini.');
    if (x.tanggal == t && x.jam == jam) throw RepositoryException('Pilih jadwal yang berbeda dari jadwal sekarang.');
    final s = _slot[(t, jam)];
    if (s == null || !s.aktif || s.kuota - _terisi(t, jam) < 1) {
      throw RepositoryException('Kuota penuh. Pilih jam lain.');
    }
    _ajukan(i, JenisPengajuan.jadwalUlang, alasan, tanggal: t, jam: jam);
    _ubah();
  }

  @override
  Future<void> ajukanBatal(String pendaftaranId, {String alasan = ''}) async {
    await _jeda();
    final i = _cari(pendaftaranId);
    if (!_daftar[i].bisaAjukanBatal) {
      throw RepositoryException(
        _daftar[i].pengajuanMenunggu != null
            ? 'Masih ada pengajuan yang menunggu persetujuan admin.'
            : 'Pendaftaran sudah ${_daftar[i].status.label}.',
      );
    }
    _ajukan(i, JenisPengajuan.batal, alasan);
    _ubah();
  }

  @override
  Future<void> tarikPengajuan(String pendaftaranId) async {
    await _jeda();
    final i = _cari(pendaftaranId);
    if (_daftar[i].pengajuanMenunggu == null) throw RepositoryException('Tidak ada pengajuan yang menunggu.');
    _daftar[i] = _daftar[i].copyWith(pengajuan: null);
    _ubah();
  }

  @override
  Future<int> jumlahPengajuanMenunggu() async => _daftar.where((p) => p.pengajuanMenunggu != null).length;

  @override
  Future<void> setujuiPengajuan(String pengajuanId) async {
    await _jeda();
    final i = _cariPengajuan(pengajuanId);
    final x = _daftar[i];
    final a = x.pengajuan!;
    if (a.jenis == JenisPengajuan.jadwalUlang) {
      if (x.status != StatusPendaftaran.dijadwalkan) throw RepositoryException('Pendaftaran sudah ${x.status.label}.');
      _jadwalkan(i, a.tanggal!, a.jam!, jadwalUlang: true);
    } else {
      if (x.status == StatusPendaftaran.ditolak ||
          x.status == StatusPendaftaran.selesai ||
          x.status == StatusPendaftaran.tidakHadir ||
          x.status == StatusPendaftaran.batal) {
        throw RepositoryException('Pendaftaran sudah ${x.status.label}.');
      }
      _daftar[i] = x.copyWith(status: StatusPendaftaran.batal);
      _perbaruiAntrean(i);
      _kirimNotif(
        x.userId,
        'Pembatalan disetujui',
        'Pendaftaran berobat a.n. ${x.nama} telah dibatalkan sesuai pengajuan Anda.',
      );
    }
    _daftar[i] = _daftar[i].copyWith(pengajuan: a.copyWith(status: StatusPengajuan.disetujui));
    _ubah();
  }

  @override
  Future<void> tolakPengajuan(String pengajuanId, String alasan) async {
    await _jeda();
    if (alasan.trim().isEmpty) throw RepositoryException('Tulis alasan penolakan untuk pasien.');
    final i = _cariPengajuan(pengajuanId);
    final x = _daftar[i];
    final a = x.pengajuan!;
    _daftar[i] = x.copyWith(
      pengajuan: a.copyWith(status: StatusPengajuan.ditolak, alasanTolak: alasan.trim()),
    );
    final ulang = a.jenis == JenisPengajuan.jadwalUlang;
    _kirimNotif(
      x.userId,
      ulang ? 'Pengajuan jadwal ulang tidak disetujui' : 'Pengajuan pembatalan tidak disetujui',
      'Mohon maaf, pengajuan ${ulang ? 'jadwal ulang' : 'pembatalan'} a.n. ${x.nama} tidak dapat disetujui. '
      'Alasan: ${_tanpaTitik(alasan)}. ${ulang ? 'Jadwal sebelumnya tetap berlaku.' : 'Pendaftaran Anda tetap berlaku.'}',
    );
    _ubah();
  }

  @override
  Future<void> kirimPengingat(String id) async {
    final x = _daftar[_cari(id)];
    if (x.tanggal == null) return;
    _kirimNotif(
      x.userId,
      'Pengingat jadwal berobat',
      'Kami mengingatkan jadwal berobat a.n. ${x.nama} pada ${fmtTanggal(x.tanggal!)}, pukul ${x.jam} WIB '
          'di ${Klinik.nama}. Nomor antrean ${x.nomorAntrean}.',
    );
    _ubah();
  }

  // ------------------------------------------------------------------ slot

  @override
  Future<Map<DateTime, int>> sisaKuotaPerTanggal() async {
    final m = <DateTime, int>{};
    _slot.forEach((k, s) {
      if (s.aktif) m[k.$1] = (m[k.$1] ?? 0) + s.kuota;
    });
    for (final p in _daftar) {
      if (p.status == StatusPendaftaran.dijadwalkan && m.containsKey(p.tanggal)) {
        m[p.tanggal!] = m[p.tanggal!]! - 1;
      }
    }
    return m;
  }

  @override
  Future<List<Slot>> slotPada(DateTime tanggal) async {
    final t = tanggalSaja(tanggal);
    final list = [
      for (final e in _slot.entries)
        if (e.key.$1 == t)
          Slot(tanggal: t, jam: e.key.$2, kuota: e.value.kuota, aktif: e.value.aktif, terisi: _terisi(t, e.key.$2)),
    ];
    return list..sort((a, b) => a.jam.compareTo(b.jam));
  }

  @override
  Future<void> tambahSlot(DateTime tanggal, String jam, int kuota) async {
    final j = normalJam(jam);
    if (j == null || kuota < 1) throw RepositoryException('Isi jam seperti 09.00 dan kuota minimal 1.');
    final k = (tanggalSaja(tanggal), j);
    if (_slot.containsKey(k)) throw RepositoryException('Jam $j sudah ada di tanggal ini.');
    _slot[k] = (kuota: kuota, aktif: true);
    _ubah();
  }

  @override
  Future<void> ubahKuotaSlot(DateTime tanggal, String jam, int kuota) async {
    final t = tanggalSaja(tanggal);
    final s = _slot[(t, jam)];
    if (s == null) return;
    final min = _terisi(t, jam).clamp(1, 1 << 30);
    if (kuota < min) throw RepositoryException('Kuota tidak boleh di bawah jumlah pasien terjadwal.');
    _slot[(t, jam)] = (kuota: kuota, aktif: s.aktif);
    _ubah();
  }

  @override
  Future<void> aturSlotAktif(DateTime tanggal, String jam, bool aktif) async {
    final k = (tanggalSaja(tanggal), jam);
    final s = _slot[k];
    if (s == null) return;
    _slot[k] = (kuota: s.kuota, aktif: aktif);
    _ubah();
  }

  @override
  Future<void> hapusSlot(DateTime tanggal, String jam) async {
    final t = tanggalSaja(tanggal);
    if (_terisi(t, jam) > 0) throw RepositoryException('Slot berisi pasien, nonaktifkan saja.');
    _slot.remove((t, jam));
    _ubah();
  }

  @override
  Future<(int, int)> buatSlotMassal({
    required DateTime mulai,
    required DateTime sampai,
    required Set<int> hari,
    required List<String> jam,
    required int kuota,
  }) async {
    await _jeda();
    final a = tanggalSaja(mulai), b = tanggalSaja(sampai);
    if (b.isBefore(a)) throw RepositoryException('Periksa tanggal mulai dan sampai.');
    if (b.isAfter(DateTime(a.year, a.month, a.day + 730))) {
      throw RepositoryException('Maksimal 24 bulan per sekali buat, ulangi untuk periode berikutnya.');
    }
    final j = jam.map(normalJam).whereType<String>().toList();
    if (hari.isEmpty || j.isEmpty || kuota < 1) {
      throw RepositoryException('Pilih hari, isi jam (contoh 08.00), dan kuota.');
    }
    final hasil = _isiSlot(a, b, hari, j, kuota);
    _ubah();
    return hasil;
  }

  // ------------------------------------------------------------------ chat

  @override
  Future<List<Pesan>> pesan(String pasienId) async =>
      _pesan.where((m) => m.pasienId == pasienId).toList()..sort((a, b) => a.waktu.compareTo(b.waktu));

  @override
  Future<void> kirimPesan(String pasienId, String isi, {required bool dariAdmin}) async {
    final t = isi.trim();
    if (t.isEmpty) return;
    _pesan.add(Pesan(id: _id(), pasienId: pasienId, dariAdmin: dariAdmin, isi: t, waktu: _now()));
    if (dariAdmin) _kirimNotif(pasienId, 'Pesan baru dari admin', t.length > 120 ? t.substring(0, 120) : t);
    _ubah();
  }

  @override
  Future<void> tandaiChatDibaca(String pasienId, {required bool olehAdmin}) async {
    var ubah = false;
    for (var i = 0; i < _pesan.length; i++) {
      final m = _pesan[i];
      // Pesan dari pihak lain yang belum dibaca.
      if (m.pasienId == pasienId && m.dariAdmin != olehAdmin && !m.dibaca) {
        _pesan[i] = Pesan(
          id: m.id,
          pasienId: m.pasienId,
          dariAdmin: m.dariAdmin,
          isi: m.isi,
          waktu: m.waktu,
          dibaca: true,
        );
        ubah = true;
      }
    }
    if (ubah) _ubah();
  }

  @override
  Future<int> chatBelumDibaca({required bool olehAdmin, String? pasienId}) async =>
      _pesan.where((m) => !m.dibaca && m.dariAdmin != olehAdmin && (pasienId == null || m.pasienId == pasienId)).length;

  @override
  Future<List<Percakapan>> percakapan() async {
    final terakhir = <String, Pesan>{};
    for (final m in _pesan) {
      final a = terakhir[m.pasienId];
      if (a == null || !m.waktu.isBefore(a.waktu)) terakhir[m.pasienId] = m;
    }
    return [
      for (final e in terakhir.entries)
        Percakapan(
          pasien: _user(e.key),
          terakhir: e.value,
          belumDibaca: _pesan.where((m) => m.pasienId == e.key && !m.dariAdmin && !m.dibaca).length,
        ),
    ]..sort((a, b) => b.terakhir.waktu.compareTo(a.terakhir.waktu));
  }

  // ------------------------------------------------------------------ notifikasi

  @override
  Future<List<Notifikasi>> notifikasi(String userId) async => _notif.where((n) => n.userId == userId).toList();

  @override
  Future<int> notifikasiBelumDibaca(String userId) async => _notif.where((n) => n.userId == userId && !n.dibaca).length;

  @override
  Future<void> tandaiNotifikasiDibaca(String userId) async {
    var ubah = false;
    for (var i = 0; i < _notif.length; i++) {
      final n = _notif[i];
      if (n.userId == userId && !n.dibaca) {
        _notif[i] = Notifikasi(id: n.id, userId: n.userId, judul: n.judul, isi: n.isi, waktu: n.waktu, dibaca: true);
        ubah = true;
      }
    }
    if (ubah) _ubah();
  }

  // ------------------------------------------------------------------ admin

  @override
  Future<RingkasAdmin> ringkas() async {
    final sisa = await sisaKuotaPerTanggal();
    final besok = _hariPraktik(1);
    var s30 = 0;
    for (var i = 1; i <= 30; i++) {
      final v = sisa[_hr(i)] ?? 0;
      if (v > 0) s30 += v;
    }
    return RingkasAdmin(
      menunggu: _daftar.where((p) => p.status == StatusPendaftaran.menunggu).length,
      hariBerikut: besok,
      jadwalHariBerikut: _terisi(besok),
      sisaKuota30Hari: s30,
      chatBelumDibaca: await chatBelumDibaca(olehAdmin: true),
      pengajuanMenunggu: await jumlahPengajuanMenunggu(),
      pasienHariBerikut: [
        for (final p
            in _daftar.where((p) => p.status == StatusPendaftaran.dijadwalkan && p.tanggal == besok).toList()
              ..sort((a, b) => (a.nomorAntrean ?? 0).compareTo(b.nomorAntrean ?? 0)))
          (id: p.id, nama: p.nama, jam: p.jam!, nomor: p.nomorAntrean),
      ],
      terbaru:
          (_daftar.where((p) => p.status == StatusPendaftaran.menunggu).toList()
                ..sort((a, b) => b.dibuat.compareTo(a.dibuat)))
              .take(5)
              .toList(),
    );
  }

  @override
  Future<List<AppUser>> akunPasien({String cari = ''}) async {
    final q = cari.trim().toLowerCase();
    return [
      for (final u in _users.reversed)
        if (!u.isAdmin &&
            (q.isEmpty || u.nama.toLowerCase().contains(q) || (_digit(q).isNotEmpty && _digit(u.noHp).contains(_digit(q)))))
          AppUser(
            id: u.id,
            nama: u.nama,
            noHp: u.noHp,
            role: u.role,
            aktif: u.aktif,
            dibuat: _now().subtract(Duration(days: int.parse(u.id) * 7)),
            jumlahPendaftaran: _daftar.where((p) => p.userId == u.id).length,
          ),
    ];
  }

  @override
  Future<String> resetSandi(String userId) async {
    _sandi[userId] = '123456';
    return '123456';
  }

  @override
  Future<void> aturAkunAktif(String userId, bool aktif) async {
    final i = _users.indexWhere((u) => u.id == userId);
    if (i >= 0) _users[i] = _users[i].copyWith(aktif: aktif);
    _ubah();
  }

  @override
  Future<List<MediaSosial>> mediaSosial() async => List.of(_medsos);

  @override
  Future<void> simpanMediaSosial(List<MediaSosial> daftar) async {
    for (final s in daftar) {
      if (!RegExp(r'^https://\S+$').hasMatch(s.url)) throw RepositoryException('URL wajib diawali https://');
    }
    _medsos = List.of(daftar);
    _ubah();
  }

  @override
  Future<InfoKlinik> infoKlinik() async =>
      _info.denganGambar(logo: _gambar[JenisGambar.logo] ?? '', foto: _gambar[JenisGambar.foto] ?? '');

  /// Path berkas gambar di HP (mode demo); tidak ada = gambar bawaan.
  final _gambar = <JenisGambar, String>{};

  @override
  Future<void> gantiGambar(JenisGambar jenis, String path) async {
    await _jeda();
    _gambar[jenis] = path;
    _ubah();
  }

  @override
  Future<void> hapusGambar(JenisGambar jenis) async {
    _gambar.remove(jenis);
    _ubah();
  }

  @override
  Future<void> simpanInfoKlinik(InfoKlinik info) async {
    final https = RegExp(r'^https://\S+$');
    if (!https.hasMatch(info.mapsUrl)) throw RepositoryException('Link Google Maps wajib diawali https://');
    if (info.websiteUrl.isNotEmpty && !https.hasMatch(info.websiteUrl)) {
      throw RepositoryException('Alamat website wajib diawali https://');
    }
    if (!RegExp(r'^[0-9+\-\s()]{8,30}$').hasMatch(info.waAdmin)) {
      throw RepositoryException('Nomor WhatsApp hanya boleh angka, spasi, +, atau -.');
    }
    _info = info;
    _ubah();
  }
}
