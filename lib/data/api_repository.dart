import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../core/format.dart';
import '../models/models.dart';
import 'penyimpan_sesi.dart';
import 'repository.dart';

/// Implementasi [Repository] yang memanggil API Laravel (docs/API.md).
class ApiRepository extends Repository {
  ApiRepository({
    required String baseUrl,
    http.Client? client,
    PenyimpanSesi penyimpan = const PenyimpanAman(),
    DateTime Function()? now,
  })  : _base = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl,
        _http = client ?? http.Client(),
        _simpan = penyimpan,
        _now = now ?? DateTime.now;

  static const _kToken = 'token';
  static const _kUser = 'user';
  static const _batasWaktu = Duration(seconds: 20);
  static const _batasUnggah = Duration(minutes: 5);

  final String _base;
  final http.Client _http;
  final PenyimpanSesi _simpan;
  final DateTime Function() _now;

  String? _token;
  AppUser? _user;

  /// id pesan terakhir yang sudah dimuat, per pasien (untuk polling chat).
  final _pesanTerakhir = <String, int>{};

  /// id pesan milik sendiri terbesar yang sudah dibaca lawan, per pasien.
  final _dibacaHingga = <String, int>{};

  /// URL media → id media (untuk `pertahankan[]` saat melengkapi pendaftaran).
  final _idMedia = <String, String>{};

  bool get _admin => _user?.isAdmin ?? false;

  // ================================================================== HTTP

  Uri _uri(String path, [Map<String, Object?>? query]) {
    final q = <String, String>{
      for (final e in (query ?? const {}).entries)
        if (e.value != null && '${e.value}'.isNotEmpty) e.key: '${e.value}',
    };
    return Uri.parse('$_base/$path').replace(queryParameters: q.isEmpty ? null : q);
  }

  Map<String, String> get _header => {
        'Accept': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  Future<dynamic> _kirim(String method, String path, {Map<String, Object?>? query, Object? body}) async {
    final req = http.Request(method, _uri(path, query))..headers.addAll(_header);
    if (body != null) {
      req.headers['Content-Type'] = 'application/json';
      req.body = jsonEncode(body);
    }
    return _jalankan(req, _batasWaktu);
  }

  Future<dynamic> _get(String path, [Map<String, Object?>? query]) => _kirim('GET', path, query: query);
  Future<dynamic> _post(String path, [Object? body]) => _kirim('POST', path, body: body ?? const {});

  Future<dynamic> _jalankan(http.BaseRequest req, Duration batas) async {
    final http.Response res;
    try {
      res = await http.Response.fromStream(await _http.send(req).timeout(batas));
    } on TimeoutException {
      throw RepositoryException('Server tidak merespons. Coba lagi.');
    } on SocketException {
      throw RepositoryException('Tidak dapat terhubung ke server. Periksa koneksi internet.');
    } on http.ClientException {
      throw RepositoryException('Tidak dapat terhubung ke server. Periksa koneksi internet.');
    }

    dynamic json;
    if (res.body.isNotEmpty) {
      try {
        json = jsonDecode(utf8.decode(res.bodyBytes));
      } on FormatException {
        json = null;
      }
    }
    if (res.statusCode >= 200 && res.statusCode < 300) return json;

    // Pesan error dari server sudah berbahasa Indonesia.
    String? pesan;
    if (json is Map) {
      final errors = json['errors'];
      if (errors is Map && errors.isNotEmpty) {
        final pertama = errors.values.first;
        pesan = pertama is List && pertama.isNotEmpty ? '${pertama.first}' : '$pertama';
      }
      pesan ??= json['message'] as String?;
    }

    if (res.statusCode == 401 && _token != null) {
      await _hapusSesi();
      onSesiBerakhir?.call();
    }
    throw RepositoryException(kode: res.statusCode, switch (res.statusCode) {
      401 => pesan ?? 'Sesi berakhir. Silakan masuk lagi.',
      403 when json == null => 'Akses ditolak server.', // mis. halaman challenge Cloudflare
      413 => 'Berkas terlalu besar untuk server.',
      429 => 'Terlalu banyak percobaan. Tunggu sebentar lalu coba lagi.',
      >= 500 => 'Terjadi kesalahan di server. Coba lagi nanti.',
      _ => pesan ?? 'Permintaan gagal (${res.statusCode}).',
    });
  }

  /// Ambil semua halaman dari endpoint berhalaman Laravel.
  Future<List<Map<String, dynamic>>> _semuaHalaman(String path, [Map<String, Object?>? query]) async {
    final hasil = <Map<String, dynamic>>[];
    for (var hal = 1; hal <= 50; hal++) {
      final j = await _get(path, {...?query, 'per_page': 100, 'page': hal}) as Map<String, dynamic>;
      hasil.addAll(_daftar(j['data']));
      final meta = j['meta'] as Map<String, dynamic>?;
      if (meta == null || hal >= (meta['last_page'] as num? ?? 1)) break;
    }
    return hasil;
  }

  static List<Map<String, dynamic>> _daftar(dynamic v) => [for (final e in (v as List? ?? const [])) e as Map<String, dynamic>];

  /// Angka dari JSON; menerima juga "30" (MySQL kadang mengirim angka sebagai teks).
  static int _int(Object? v) => v is num ? v.toInt() : int.tryParse('$v') ?? 0;

  static Map<String, dynamic> _data(dynamic j) => (j as Map<String, dynamic>)['data'] as Map<String, dynamic>;

  // ================================================================== konversi JSON

  static String _tgl(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// "2026-11-20" → tanggal lokal tanpa jam.
  static DateTime? _bacaTgl(Object? s) {
    if (s is! String || s.isEmpty) return null;
    final d = DateTime.parse(s.length > 10 ? s.substring(0, 10) : s);
    return DateTime(d.year, d.month, d.day);
  }

  DateTime _bacaWaktu(Object? s) => s is String ? DateTime.parse(s).toLocal() : _now();

  static const _status = {
    'menunggu': StatusPendaftaran.menunggu,
    'perlu_dilengkapi': StatusPendaftaran.perluDilengkapi,
    'dijadwalkan': StatusPendaftaran.dijadwalkan,
    'ditolak': StatusPendaftaran.ditolak,
    'selesai': StatusPendaftaran.selesai,
    'tidak_hadir': StatusPendaftaran.tidakHadir,
    'batal': StatusPendaftaran.batal,
  };

  static String _kodeStatus(StatusPendaftaran s) => _status.entries.firstWhere((e) => e.value == s).key;

  static AppUser _keUser(Map<String, dynamic> j) => AppUser(
        id: '${j['id']}',
        nama: j['nama'] as String? ?? '',
        noHp: (j['no_hp'] ?? j['username'] ?? '') as String,
        role: j['role'] == 'admin' ? Role.admin : Role.pasien,
        aktif: j['aktif'] as bool? ?? true,
        email: j['email'] as String?,
        dibuat: j['dibuat'] is String ? DateTime.tryParse(j['dibuat'] as String)?.toLocal() : null,
        jumlahPendaftaran: j['jumlah_pendaftaran'] == null ? null : _int(j['jumlah_pendaftaran']),
      );

  Pendaftaran _kePendaftaran(Map<String, dynamic> j) {
    final media = _daftar(j['media']);
    for (final m in media) {
      if (m['id'] != null) _idMedia[m['url'] as String] = '${m['id']}';
    }
    return Pendaftaran(
      id: '${j['id']}',
      userId: '${j['user_id']}',
      nama: j['nama'] as String,
      umur: _int(j['umur']),
      alamat: j['alamat'] as String? ?? '',
      noHp: j['no_hp'] as String? ?? '',
      keluhan: j['keluhan'] as String? ?? '',
      mediaKondisi: [for (final m in media) if (m['jenis'] == 'kondisi') m['url'] as String],
      fotoKtp: media.where((m) => m['jenis'] == 'ktp').map((m) => m['url'] as String).firstOrNull ?? '',
      status: _status[j['status']] ?? StatusPendaftaran.menunggu,
      dibuat: _bacaWaktu(j['dibuat']),
      tanggal: _bacaTgl(j['tanggal']),
      jam: j['jam'] as String?,
      nomorAntrean: j['nomor_antrean'] == null ? null : _int(j['nomor_antrean']),
      alasan: j['alasan'] as String?,
      catatan: j['catatan'] as String?,
      dilengkapi: j['dilengkapi'] is String ? _bacaWaktu(j['dilengkapi']) : null,
      pengajuan: j['pengajuan'] is Map<String, dynamic> ? _kePengajuan(j['pengajuan'] as Map<String, dynamic>) : null,
      namaAkun: j['akun'] is Map<String, dynamic> ? (j['akun'] as Map<String, dynamic>)['nama'] as String? : null,
    );
  }

  Pengajuan _kePengajuan(Map<String, dynamic> j) => Pengajuan(
        id: '${j['id']}',
        jenis: j['jenis'] == 'batal' ? JenisPengajuan.batal : JenisPengajuan.jadwalUlang,
        status: switch (j['status']) {
          'disetujui' => StatusPengajuan.disetujui,
          'ditolak' => StatusPengajuan.ditolak,
          _ => StatusPengajuan.menunggu,
        },
        dibuat: _bacaWaktu(j['dibuat']),
        tanggal: _bacaTgl(j['tanggal']),
        jam: j['jam'] as String?,
        alasan: j['alasan'] as String?,
        alasanTolak: j['alasan_tolak'] as String?,
      );

  Pesan _kePesan(Map<String, dynamic> j) => Pesan(
        id: '${j['id']}',
        pasienId: '${j['pasien_id']}',
        dariAdmin: j['dari_admin'] as bool,
        isi: j['isi'] as String,
        waktu: _bacaWaktu(j['waktu']),
        dibaca: j['dibaca'] as bool? ?? false,
      );

  // ================================================================== sesi

  @override
  Map<String, String> get headerMedia => {if (_token != null) 'Authorization': 'Bearer $_token'};

  @override
  Future<AppUser?> pulihkanSesi() async {
    try {
      final token = await _simpan.baca(_kToken);
      final user = await _simpan.baca(_kUser);
      if (token == null || user == null) return null;
      _token = token;
      _user = _keUser(jsonDecode(user) as Map<String, dynamic>);
    } catch (_) {
      // Penyimpanan rusak (mis. setelah pulihkan cadangan HP): mulai dari layar Masuk.
      await _hapusSesi();
      return null;
    }
    // Perbarui data akun di latar; token yang sudah dicabut akan memicu onSesiBerakhir.
    unawaited(() async {
      try {
        final j = await _get('me');
        if (_token != null) await _simpanSesi(_token!, _data(j));
      } catch (_) {
        // Offline: tetap pakai data tersimpan.
      }
    }());
    return _user;
  }

  Future<AppUser> _simpanSesi(String token, Map<String, dynamic> user) async {
    _token = token;
    _user = _keUser(user);
    await _simpan.tulis(_kToken, token);
    await _simpan.tulis(_kUser, jsonEncode(user));
    return _user!;
  }

  Future<void> _hapusSesi() async {
    _token = null;
    _user = null;
    _pesanTerakhir.clear();
    _dibacaHingga.clear();
    _idMedia.clear();
    resetMengetik();
    await _simpan.hapusSemua();
  }

  Future<AppUser> _masuk(String path, Map<String, Object?> body) async {
    final j = await _post(path, body) as Map<String, dynamic>;
    return _simpanSesi(j['token'] as String, j['user'] as Map<String, dynamic>);
  }

  // ================================================================== auth & akun

  @override
  Future<AppUser> loginPasien(String noHp, String sandi) => _masuk('auth/masuk', {'no_hp': noHp.trim(), 'sandi': sandi});

  @override
  Future<AppUser> loginAdmin(String username, String sandi) =>
      _masuk('auth/masuk-admin', {'username': username.trim(), 'sandi': sandi});

  @override
  Future<AppUser> daftarAkun({required String nama, required String noHp, required String sandi}) =>
      _masuk('auth/daftar', {'nama': nama.trim(), 'no_hp': noHp.trim(), 'sandi': sandi});

  @override
  Future<void> logout() async {
    try {
      if (_token != null) await _post('auth/keluar');
    } on RepositoryException {
      // Tetap keluar di HP walau server tidak terjangkau.
    }
    await _hapusSesi();
  }

  @override
  Future<void> ubahSandi(String userId, String sandiBaru, {String? sandiLama}) async {
    await _kirim('PUT', 'me/sandi', body: {'sandi_baru': sandiBaru, 'sandi_lama': ?sandiLama});
  }

  @override
  Future<AppUser> ubahProfilAdmin({required String nama, required String email}) async {
    final j = _data(await _kirim('PATCH', 'me', body: {'nama': nama.trim(), 'email': email.trim()}));
    return _token == null ? _keUser(j) : _simpanSesi(_token!, j);
  }

  @override
  Future<void> kirimTokenPerangkat(String token) async {
    if (_token != null) await _post('me/device-token', {'token': token});
  }

  // ================================================================== pendaftaran (pasien)

  @override
  Future<List<Pendaftaran>> pendaftaranSaya(String userId) async =>
      _daftar((await _get('pendaftaran'))['data']).map(_kePendaftaran).toList();

  @override
  Future<Pendaftaran?> pendaftaran(String id) async {
    try {
      return _kePendaftaran(_data(await _get(_admin ? 'admin/pendaftaran/$id' : 'pendaftaran/$id')));
    } on RepositoryException catch (e) {
      if (e.kode == 404) return null;
      rethrow;
    }
  }

  static MediaType _mime(String path) {
    final ext = path.split('.').last.toLowerCase();
    return switch (ext) {
      'png' => MediaType('image', 'png'),
      'webp' => MediaType('image', 'webp'),
      'mp4' => MediaType('video', 'mp4'),
      _ => MediaType('image', 'jpeg'),
    };
  }

  @override
  Future<Pendaftaran> daftarBerobat(FormPendaftaran f) async {
    final req = http.MultipartRequest('POST', _uri('pendaftaran'))
      ..headers.addAll(_header)
      ..fields.addAll({
        'nama': f.nama.trim(),
        'umur': '${f.umur}',
        'no_hp': f.noHp.trim(),
        'alamat': f.alamat.trim(),
        'keluhan': f.keluhan.trim(),
      });
    try {
      for (final p in f.mediaKondisi) {
        req.files.add(await http.MultipartFile.fromPath('kondisi[]', p, contentType: _mime(p)));
      }
      req.files.add(await http.MultipartFile.fromPath('ktp', f.fotoKtp, contentType: _mime(f.fotoKtp)));
    } on FileSystemException {
      throw RepositoryException('Berkas foto/video tidak dapat dibaca. Pilih ulang berkasnya.');
    }
    final p = _kePendaftaran(_data(await _jalankan(req, _batasUnggah)));
    notifyListeners();
    return p;
  }

  static bool _dariServer(String s) => s.startsWith('http');

  @override
  Future<void> lengkapiPendaftaran(String id, FormPendaftaran f) async {
    // Media lama (URL server) dikirim sebagai id di `pertahankan[i]`; yang tidak disebut dihapus server.
    final pertahankan = [for (final m in f.mediaKondisi.where(_dariServer)) ?_idMedia[m]];
    final req = http.MultipartRequest('POST', _uri('pendaftaran/$id/lengkapi'))
      ..headers.addAll(_header)
      ..fields.addAll({
        'nama': f.nama.trim(),
        'umur': '${f.umur}',
        'no_hp': f.noHp.trim(),
        'alamat': f.alamat.trim(),
        'keluhan': f.keluhan.trim(),
        for (var i = 0; i < pertahankan.length; i++) 'pertahankan[$i]': pertahankan[i],
      });
    try {
      for (final p in f.mediaKondisi.where((m) => !_dariServer(m))) {
        req.files.add(await http.MultipartFile.fromPath('kondisi[]', p, contentType: _mime(p)));
      }
      if (!_dariServer(f.fotoKtp)) {
        req.files.add(await http.MultipartFile.fromPath('ktp', f.fotoKtp, contentType: _mime(f.fotoKtp)));
      }
    } on FileSystemException {
      throw RepositoryException('Berkas foto/video tidak dapat dibaca. Pilih ulang berkasnya.');
    }
    _kePendaftaran(_data(await _jalankan(req, _batasUnggah)));
    notifyListeners();
  }

  // ================================================================== pengajuan (pasien)

  Future<void> _ajukan(String id, Map<String, Object?> body) async {
    await _post('pendaftaran/$id/pengajuan', body);
    notifyListeners();
  }

  @override
  Future<void> ajukanJadwalUlang(String pendaftaranId, DateTime tanggal, String jam, {String alasan = ''}) =>
      _ajukan(pendaftaranId, {'jenis': 'jadwal_ulang', 'tanggal': _tgl(tanggal), 'jam': jam, 'alasan': alasan.trim()});

  @override
  Future<void> ajukanBatal(String pendaftaranId, {String alasan = ''}) =>
      _ajukan(pendaftaranId, {'jenis': 'batal', 'alasan': alasan.trim()});

  @override
  Future<void> tarikPengajuan(String pendaftaranId) async {
    await _kirim('DELETE', 'pendaftaran/$pendaftaranId/pengajuan');
    notifyListeners();
  }

  // ================================================================== pendaftaran (admin)

  @override
  Future<List<Pendaftaran>> semuaPendaftaran({
    StatusPendaftaran? status,
    String cari = '',
    bool hanyaPengajuan = false,
  }) async =>
      (await _semuaHalaman('admin/pendaftaran', {
        'status': status == null || hanyaPengajuan ? null : _kodeStatus(status),
        'pengajuan': hanyaPengajuan ? 1 : null,
        'q': cari.trim(),
      }))
          .map(_kePendaftaran)
          .toList();

  @override
  Future<int> jumlahPengajuanMenunggu() async =>
      _int((await _get('admin/pendaftaran', {'per_page': 1}) as Map<String, dynamic>)['pengajuan_menunggu']);

  @override
  Future<void> setujuiPengajuan(String pengajuanId) async {
    await _post('admin/pengajuan/$pengajuanId/setujui');
    notifyListeners();
  }

  @override
  Future<void> tolakPengajuan(String pengajuanId, String alasan) async {
    await _post('admin/pengajuan/$pengajuanId/tolak', {'alasan': alasan.trim()});
    notifyListeners();
  }

  Future<void> _ubahPendaftaran(String id, String aksi, [Map<String, Object?>? body]) async {
    await _post('admin/pendaftaran/$id/$aksi', body);
    notifyListeners();
  }

  @override
  Future<void> jadwalkan(String id, DateTime tanggal, String jam) =>
      _ubahPendaftaran(id, 'jadwalkan', {'tanggal': _tgl(tanggal), 'jam': jam});

  @override
  Future<void> tolak(String id, String alasan) => _ubahPendaftaran(id, 'tolak', {'alasan': alasan.trim()});

  @override
  Future<void> mintaDilengkapi(String id, String catatan) =>
      _ubahPendaftaran(id, 'perlu-dilengkapi', {'catatan': catatan.trim()});

  @override
  Future<void> ubahStatus(String id, StatusPendaftaran status) =>
      _ubahPendaftaran(id, 'status', {'status': _kodeStatus(status)});

  @override
  Future<void> kirimPengingat(String id) => _ubahPendaftaran(id, 'ingatkan');

  // ================================================================== slot

  @override
  Future<Map<DateTime, int>> sisaKuotaPerTanggal() async {
    final hariIni = tanggalSaja(_now());
    // Pasien memakai /kalender & /slot (hanya slot aktif) untuk memilih jadwal ulang.
    final j = await _get(_admin ? 'admin/kalender' : 'kalender', {
      'dari': _tgl(hariIni),
      'sampai': _tgl(DateTime(hariIni.year, hariIni.month, hariIni.day + 730)),
    }) as Map<String, dynamic>;
    return {
      for (final e in (j['data'] as Map<String, dynamic>).entries) _bacaTgl(e.key)!: _int(e.value),
    };
  }

  @override
  Future<List<Slot>> slotPada(DateTime tanggal) async {
    final t = tanggalSaja(tanggal);
    return [
      for (final s in _daftar((await _get(_admin ? 'admin/slot' : 'slot', {'tanggal': _tgl(t)}))['data']))
        Slot(
          tanggal: t,
          jam: s['jam'] as String,
          kuota: _int(s['kuota']),
          aktif: s['aktif'] as bool,
          terisi: _int(s['terisi']),
        ),
    ];
  }

  Future<void> _ubahSlot(String method, Map<String, Object?> body) async {
    if (method == 'DELETE') {
      await _kirim(method, 'admin/slot', query: body);
    } else {
      await _kirim(method, 'admin/slot', body: body);
    }
    notifyListeners();
  }

  @override
  Future<void> tambahSlot(DateTime tanggal, String jam, int kuota) =>
      _ubahSlot('POST', {'tanggal': _tgl(tanggal), 'jam': jam, 'kuota': kuota});

  @override
  Future<void> ubahKuotaSlot(DateTime tanggal, String jam, int kuota) =>
      _ubahSlot('PATCH', {'tanggal': _tgl(tanggal), 'jam': jam, 'kuota': kuota});

  @override
  Future<void> aturSlotAktif(DateTime tanggal, String jam, bool aktif) =>
      _ubahSlot('PATCH', {'tanggal': _tgl(tanggal), 'jam': jam, 'aktif': aktif});

  @override
  Future<void> hapusSlot(DateTime tanggal, String jam) => _ubahSlot('DELETE', {'tanggal': _tgl(tanggal), 'jam': jam});

  @override
  Future<(int, int)> buatSlotMassal({
    required DateTime mulai,
    required DateTime sampai,
    required Set<int> hari,
    required List<String> jam,
    required int kuota,
  }) async {
    final j = await _post('admin/slot/massal', {
      'mulai': _tgl(mulai),
      'sampai': _tgl(sampai),
      'hari': hari.toList()..sort(),
      'jam': jam,
      'kuota': kuota,
    }) as Map<String, dynamic>;
    notifyListeners();
    return ((j['baru'] as num).toInt(), (j['sudah_ada'] as num).toInt());
  }

  // ================================================================== chat

  String _jalurChat(String pasienId) => _admin ? 'admin/chat/$pasienId' : 'chat';

  /// Simpan status percakapan dari balasan GET chat; `true` bila centang dibaca berubah.
  bool _bacaStatusChat(String pasienId, Map<String, dynamic> j) {
    lawanMengetik(pasienId).value = j['mengetik'] as bool? ?? false;
    final hingga = _int(j['dibaca_hingga']);
    final berubah = _dibacaHingga.containsKey(pasienId) && _dibacaHingga[pasienId] != hingga;
    _dibacaHingga[pasienId] = hingga;
    return berubah;
  }

  @override
  Future<List<Pesan>> pesan(String pasienId) async {
    final j = await _get(_jalurChat(pasienId)) as Map<String, dynamic>;
    final list = _daftar(j['data']).map(_kePesan).toList();
    if (list.isNotEmpty) _pesanTerakhir[pasienId] = int.parse(list.last.id);
    _bacaStatusChat(pasienId, j);
    return list;
  }

  @override
  Future<void> periksaPesanBaru(String pasienId) async {
    final j = await _get(_jalurChat(pasienId), {'after': _pesanTerakhir[pasienId] ?? 0}) as Map<String, dynamic>;
    final dibacaBerubah = _bacaStatusChat(pasienId, j);
    final baru = _daftar(j['data']);
    if (baru.isNotEmpty) _pesanTerakhir[pasienId] = (baru.last['id'] as num).toInt();
    if (baru.isNotEmpty || dibacaBerubah) notifyListeners();
  }

  @override
  Future<void> kirimMengetik(String pasienId, {required bool aktif}) async {
    await _post('${_jalurChat(pasienId)}/mengetik', {'aktif': aktif});
  }

  @override
  Future<void> kirimPesan(String pasienId, String isi, {required bool dariAdmin}) async {
    final t = isi.trim();
    if (t.isEmpty) return;
    await _post(_jalurChat(pasienId), {'isi': t});
    notifyListeners();
  }

  @override
  Future<void> tandaiChatDibaca(String pasienId, {required bool olehAdmin}) async {
    await _post('${_jalurChat(pasienId)}/dibaca');
    notifyListeners();
  }

  /// Nilai `after` yang melewati semua pesan: hanya `belum_dibaca` yang diambil.
  static const _lewatiSemua = 1 << 31;

  @override
  Future<int> chatBelumDibaca({required bool olehAdmin, String? pasienId}) async {
    if (olehAdmin && pasienId == null) {
      return (await percakapan()).fold<int>(0, (n, c) => n + c.belumDibaca);
    }
    final j = await _get(olehAdmin ? 'admin/chat/$pasienId' : 'chat', {'after': _lewatiSemua}) as Map<String, dynamic>;
    return (j['belum_dibaca'] as num).toInt();
  }

  @override
  Future<List<Percakapan>> percakapan() async => [
        for (final c in _daftar((await _get('admin/chat'))['data']))
          Percakapan(
            pasien: _keUser(c['pasien'] as Map<String, dynamic>),
            terakhir: _kePesan(c['terakhir'] as Map<String, dynamic>),
            belumDibaca: (c['belum_dibaca'] as num).toInt(),
          ),
      ];

  // ================================================================== notifikasi

  @override
  Future<List<Notifikasi>> notifikasi(String userId) async => [
        for (final n in _daftar((await _get('notifikasi'))['data']))
          Notifikasi(
            id: '${n['id']}',
            userId: userId,
            judul: n['judul'] as String,
            isi: n['isi'] as String,
            waktu: _bacaWaktu(n['waktu']),
            dibaca: n['dibaca'] as bool? ?? false,
          ),
      ];

  @override
  Future<int> notifikasiBelumDibaca(String userId) async =>
      ((await _get('notifikasi') as Map<String, dynamic>)['belum_dibaca'] as num).toInt();

  @override
  Future<void> tandaiNotifikasiDibaca(String userId) async {
    await _post('notifikasi/dibaca');
    notifyListeners();
  }

  // ================================================================== admin: ringkas, pasien, media sosial

  @override
  Future<RingkasAdmin> ringkas() async {
    final j = _data(await _get('admin/ringkas'));
    return RingkasAdmin(
      menunggu: (j['menunggu'] as num).toInt(),
      hariBerikut: _bacaTgl(j['hari_berikut']),
      jadwalHariBerikut: (j['jadwal_hari_berikut'] as List).length,
      sisaKuota30Hari: (j['sisa_kuota_30_hari'] as num).toInt(),
      chatBelumDibaca: (j['chat_belum_dibaca'] as num).toInt(),
      pengajuanMenunggu: _int(j['pengajuan_menunggu']),
      pasienHariBerikut: [
        for (final p in _daftar(j['jadwal_hari_berikut']))
          (
            id: '${p['id']}',
            nama: p['nama'] as String,
            jam: p['jam'] as String? ?? '',
            nomor: p['nomor_antrean'] == null ? null : _int(p['nomor_antrean']),
          ),
      ],
      terbaru: _daftar(j['terbaru']).map(_kePendaftaran).toList(),
    );
  }

  @override
  Future<Map<StatusPendaftaran, int>> jumlahPendaftaran() async {
    final j = await _get('admin/pendaftaran', {'per_page': 1}) as Map<String, dynamic>;
    final jumlah = j['jumlah'];
    return {
      for (final s in StatusPendaftaran.values)
        s: jumlah is Map ? _int(jumlah[_kodeStatus(s)]) : 0,
    };
  }

  @override
  Future<List<AppUser>> akunPasien({String cari = ''}) async =>
      (await _semuaHalaman('admin/pasien', {if (cari.trim().isNotEmpty) 'q': cari.trim()})).map(_keUser).toList();

  @override
  Future<String> resetSandi(String userId) async =>
      (await _post('admin/pasien/$userId/reset-sandi') as Map<String, dynamic>)['sandi'] as String;

  @override
  Future<void> aturAkunAktif(String userId, bool aktif) async {
    await _kirim('PATCH', 'admin/pasien/$userId', body: {'aktif': aktif});
    notifyListeners();
  }

  @override
  Future<List<MediaSosial>> mediaSosial() async => [
        for (final m in _daftar((await _get(_admin ? 'admin/media-sosial' : 'media-sosial'))['data']))
          MediaSosial(
            platform: m['platform'] as String,
            nama: m['nama'] as String,
            url: m['url'] as String,
            aktif: m['aktif'] as bool? ?? true,
          ),
      ];

  @override
  Future<void> simpanMediaSosial(List<MediaSosial> daftar) async {
    await _kirim('PUT', 'admin/media-sosial', body: {
      'data': [
        for (final m in daftar) {'platform': m.platform, 'nama': m.nama, 'url': m.url, 'aktif': m.aktif},
      ],
    });
    notifyListeners();
  }

  // ================================================================== info klinik

  @override
  Future<InfoKlinik> infoKlinik() async {
    final j = _data(await _get('info-klinik'));
    String s(String k) => j[k] as String? ?? '';
    return InfoKlinik(
      alamat: s('alamat'),
      mapsUrl: s('maps_url'),
      waAdmin: s('wa_admin'),
      biaya: s('biaya'),
      biayaCatatan: s('biaya_catatan'),
      websiteUrl: s('website_url'),
      websiteKeterangan: s('website_keterangan'),
      jadwalBerobat: s('jadwal_berobat'),
      logoUrl: s('logo_url'),
      fotoUrl: s('foto_url'),
    );
  }

  @override
  Future<void> gantiGambar(JenisGambar jenis, String path) async {
    final req = http.MultipartRequest('POST', _uri('admin/gambar/${jenis.kunci}'))..headers.addAll(_header);
    try {
      req.files.add(await http.MultipartFile.fromPath('gambar', path, contentType: _mime(path)));
    } on FileSystemException {
      throw RepositoryException('Berkas gambar tidak dapat dibaca. Pilih ulang gambarnya.');
    }
    await _jalankan(req, _batasUnggah);
    notifyListeners();
  }

  @override
  Future<void> hapusGambar(JenisGambar jenis) async {
    await _kirim('DELETE', 'admin/gambar/${jenis.kunci}');
    notifyListeners();
  }

  @override
  Future<void> simpanInfoKlinik(InfoKlinik info) async {
    await _kirim('PUT', 'admin/info-klinik', body: {
      'alamat': info.alamat,
      'maps_url': info.mapsUrl,
      'wa_admin': info.waAdmin,
      'biaya': info.biaya,
      'biaya_catatan': info.biayaCatatan,
      'website_url': info.websiteUrl,
      'website_keterangan': info.websiteKeterangan,
      'jadwal_berobat': info.jadwalBerobat,
    });
    notifyListeners();
  }
}
