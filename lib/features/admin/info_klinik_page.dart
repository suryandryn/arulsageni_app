import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../data/repository.dart';
import '../../models/models.dart';
import '../../widgets/kontak.dart';
import '../../widgets/gambar_klinik.dart';
import '../../widgets/ui.dart';

/// Atur info klinik, sama dengan halaman Info Klinik di panel web: alamat, link
/// Google Maps, WA admin, estimasi biaya, website, dan kalimat jadwal berobat.
class InfoKlinikPage extends StatefulWidget {
  const InfoKlinikPage({super.key});

  @override
  State<InfoKlinikPage> createState() => _InfoKlinikPageState();
}

class _InfoKlinikPageState extends State<InfoKlinikPage> {
  late final Repository _repo;
  final _alamat = TextEditingController();
  final _maps = TextEditingController();
  final _wa = TextEditingController();
  final _biaya = TextEditingController();
  final _biayaCatatan = TextEditingController();
  final _web = TextEditingController();
  final _webKet = TextEditingController();
  final _jadwal = TextEditingController();

  List<TextEditingController> get _semua => [_alamat, _maps, _wa, _biaya, _biayaCatatan, _web, _webKet, _jadwal];

  InfoKlinik? _awal;
  Object? _galat;
  bool _menyimpan = false;
  bool _cek = false;

  @override
  void initState() {
    super.initState();
    _repo = context.read<Repository>()..addListener(_muatBilaBersih);
    for (final c in _semua) {
      c.addListener(_ubah);
    }
    _muat();
  }

  @override
  void dispose() {
    _repo.removeListener(_muatBilaBersih);
    for (final c in _semua) {
      c.dispose();
    }
    super.dispose();
  }

  void _ubah() => setState(() {});

  InfoKlinik get _nilai => InfoKlinik(
    alamat: _alamat.text.trim(),
    mapsUrl: _maps.text.trim(),
    waAdmin: _wa.text.trim(),
    biaya: _biaya.text.trim(),
    biayaCatatan: _biayaCatatan.text.trim(),
    websiteUrl: _web.text.trim(),
    websiteKeterangan: _webKet.text.trim(),
    jadwalBerobat: _jadwal.text.trim(),
  );

  bool get _berubah {
    final a = _awal;
    if (a == null) return false;
    final b = _nilai;
    return a.alamat != b.alamat ||
        a.mapsUrl != b.mapsUrl ||
        a.waAdmin != b.waAdmin ||
        a.biaya != b.biaya ||
        a.biayaCatatan != b.biayaCatatan ||
        a.websiteUrl != b.websiteUrl ||
        a.websiteKeterangan != b.websiteKeterangan ||
        a.jadwalBerobat != b.jadwalBerobat;
  }

  /// Ikut perubahan dari panel web selama belum ada isian yang diubah di sini.
  void _muatBilaBersih() {
    if (!_berubah && !_menyimpan) _muat();
  }

  Future<void> _muat() async {
    try {
      final i = await _repo.infoKlinik();
      if (!mounted) return;
      _alamat.text = i.alamat;
      _maps.text = i.mapsUrl;
      _wa.text = i.waAdmin;
      _biaya.text = i.biaya;
      _biayaCatatan.text = i.biayaCatatan;
      _web.text = i.websiteUrl;
      _webKet.text = i.websiteKeterangan;
      _jadwal.text = i.jadwalBerobat;
      setState(() {
        _awal = _nilai;
        _galat = null;
        _cek = false;
      });
    } catch (e) {
      if (mounted && _awal == null) setState(() => _galat = e);
    }
  }

  static final _https = RegExp(r'^https://\S+$');

  String? _wajib(TextEditingController c, String pesan) => _cek && c.text.trim().isEmpty ? pesan : null;

  String? get _galatMaps => !_cek
      ? null
      : _maps.text.trim().isEmpty
      ? 'Isi link Google Maps.'
      : (_https.hasMatch(_maps.text.trim()) ? null : 'Link Google Maps wajib diawali https://');

  String? get _galatWa => _cek && !RegExp(r'^[0-9+\-\s()]{8,30}$').hasMatch(_wa.text.trim())
      ? 'Nomor WhatsApp hanya boleh angka, spasi, +, atau -.'
      : null;

  String? get _galatWeb => _cek && _web.text.trim().isNotEmpty && !_https.hasMatch(_web.text.trim())
      ? 'Alamat website wajib diawali https://'
      : null;

  Future<void> _simpan() async {
    setState(() => _cek = true);
    final galat = [
      _wajib(_alamat, 'x'),
      _galatMaps,
      _galatWa,
      _wajib(_biaya, 'x'),
      _galatWeb,
      _wajib(_jadwal, 'x'),
    ].nonNulls;
    if (galat.isNotEmpty) return toast(context, 'Periksa isian', 'Ada isian yang belum benar.');

    setState(() => _menyimpan = true);
    try {
      final baru = _nilai;
      await _repo.simpanInfoKlinik(baru);
      if (!mounted) return;
      setState(() {
        _awal = baru;
        _cek = false;
      });
      toast(context, 'Info klinik disimpan.', 'Langsung tampil di aplikasi pasien dan panel web.');
    } catch (e) {
      if (mounted) toast(context, 'Gagal menyimpan', '$e');
    } finally {
      if (mounted) setState(() => _menyimpan = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_berubah,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final nav = Navigator.of(context);
        if (await konfirmasi(context, 'Perubahan belum disimpan. Tetap keluar?')) nav.pop();
      },
      child: Scaffold(
        appBar: headerApp('Info Klinik', kembali: true),
        body: _awal == null
            ? Center(
                child: _galat == null
                    ? const CircularProgressIndicator()
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Gagal memuat data.\n$_galat', textAlign: TextAlign.center),
                          TextButton(onPressed: _muat, child: const Text('Coba lagi')),
                        ],
                      ),
              )
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: Text('Tampil di menu Info aplikasi pasien dan di kartu jadwal pada Beranda.', style: tsMut),
                  ),
                  const _KartuGambar(JenisGambar.logo, tampilDi: 'halaman Masuk dan Daftar Akun'),
                  const _KartuGambar(JenisGambar.foto, tampilDi: 'menu Info pasien'),
                  Kartu(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const JudulKartu('Lokasi'),
                        _isian(_alamat, 'Alamat lengkap', baris: 3, galat: _wajib(_alamat, 'Isi alamat.')),
                        _isian(
                          _maps,
                          'Link Google Maps',
                          jenis: TextInputType.url,
                          galat: _galatMaps,
                          coba: () => bukaUrl(context, _maps.text.trim()),
                        ),
                      ],
                    ),
                  ),
                  Kartu(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const JudulKartu('Admin resmi'),
                        _isian(
                          _wa,
                          'Nomor WhatsApp admin',
                          jenis: TextInputType.phone,
                          galat: _galatWa,
                          coba: () => bukaWhatsApp(context, _wa.text.trim()),
                        ),
                      ],
                    ),
                  ),
                  Kartu(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const JudulKartu('Estimasi biaya'),
                        _isian(
                          _biaya,
                          'Rincian (satu baris = satu poin)',
                          baris: 5,
                          galat: _wajib(_biaya, 'Isi rincian biaya.'),
                        ),
                        _isian(_biayaCatatan, 'Catatan penutup (tebal, boleh kosong)', baris: 2),
                      ],
                    ),
                  ),
                  Kartu(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const JudulKartu('Website'),
                        _isian(
                          _web,
                          'Alamat website (kosongkan untuk menyembunyikan)',
                          jenis: TextInputType.url,
                          galat: _galatWeb,
                        ),
                        _isian(_webKet, 'Keterangan', petunjuk: 'Website resmi'),
                      ],
                    ),
                  ),
                  Kartu(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const JudulKartu('Kalimat jadwal berobat'),
                        const Text(
                          'Tampil di bawah kartu jadwal pasien. Satu baris = satu paragraf. '
                          'Tulis ${InfoKlinik.penandaTanggal} untuk tanggal berobat pasien.',
                          style: tsCap,
                        ),
                        _isian(_jadwal, 'Kalimat jadwal', baris: 8, galat: _wajib(_jadwal, 'Isi kalimat jadwal.')),
                        _pratinjauJadwal(),
                      ],
                    ),
                  ),
                  Tombol('Simpan', memuat: _menyimpan, onPressed: _berubah ? _simpan : null),
                  if (_berubah)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text('Ada perubahan belum disimpan.', style: TextStyle(color: AppColors.wtx)),
                    ),
                ],
              ),
      ),
    );
  }

  /// Contoh tampilan di aplikasi pasien (sama dengan panel web): penanda diganti tanggal besok.
  Widget _pratinjauJadwal() {
    final h = DateTime.now();
    final tgl = fmtTanggal(DateTime(h.year, h.month, h.day + 1)).toUpperCase().replaceFirst(',', '');
    final paragraf = _nilai.arahanJadwal(tgl);
    if (paragraf.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: AppColors.bg,
        border: Border(left: BorderSide(color: AppColors.gold, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Contoh di aplikasi:', style: tsCap),
          const Text('JADWAL BEROBAT (NAMA PASIEN)', style: TextStyle(fontWeight: FontWeight.w700)),
          for (final p in paragraf) Padding(padding: const EdgeInsets.only(top: 8), child: Text(p)),
        ],
      ),
    );
  }

  Widget _isian(
    TextEditingController c,
    String label, {
    int baris = 1,
    TextInputType? jenis,
    String? galat,
    String? petunjuk,
    VoidCallback? coba,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: TextField(
        controller: c,
        minLines: baris,
        maxLines: baris == 1 ? 1 : baris + 4,
        keyboardType: baris > 1 ? TextInputType.multiline : jenis,
        decoration: InputDecoration(
          labelText: label,
          hintText: petunjuk,
          errorText: galat,
          errorMaxLines: 2,
          alignLabelWithHint: baris > 1,
          suffixIcon: coba == null
              ? null
              : IconButton(tooltip: 'Coba buka', icon: const Icon(Icons.open_in_new), onPressed: coba),
        ),
      ),
    );
  }
}

/// Kartu ganti gambar (logo / foto profil). Tersimpan langsung, terpisah dari tombol Simpan.
class _KartuGambar extends StatefulWidget {
  const _KartuGambar(this.jenis, {required this.tampilDi});

  final JenisGambar jenis;
  final String tampilDi;

  @override
  State<_KartuGambar> createState() => _KartuGambarState();
}

class _KartuGambarState extends State<_KartuGambar> {
  late final Repository _repo;
  String _sumber = '';
  bool _proses = false;

  @override
  void initState() {
    super.initState();
    _repo = context.read<Repository>()..addListener(_muat);
    _muat();
  }

  @override
  void dispose() {
    _repo.removeListener(_muat);
    super.dispose();
  }

  Future<void> _muat() async {
    try {
      final s = (await _repo.infoKlinik()).gambar(widget.jenis);
      if (mounted && s != _sumber) setState(() => _sumber = s);
    } catch (_) {}
  }

  Future<void> _ganti() async {
    final f = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 800, imageQuality: 85);
    if (f == null || !mounted) return;
    if (await File(f.path).length() > 2 * 1000 * 1000) {
      if (mounted) toast(context, 'Berkas terlalu besar', 'Gambar maks. 2 MB.');
      return;
    }
    await _jalankan(() => _repo.gantiGambar(widget.jenis, f.path), 'Gambar diganti.');
  }

  Future<void> _bawaan() async {
    if (!await konfirmasi(context, 'Kembalikan ke gambar bawaan?')) return;
    await _jalankan(() => _repo.hapusGambar(widget.jenis), 'Gambar bawaan dipakai lagi.');
  }

  Future<void> _jalankan(Future<void> Function() aksi, String pesan) async {
    setState(() => _proses = true);
    try {
      await aksi();
      await _muat();
      if (mounted) toast(context, pesan, 'Langsung tampil di ${widget.tampilDi}.');
    } catch (e) {
      if (mounted) toast(context, 'Gagal menyimpan gambar', '$e');
    } finally {
      if (mounted) setState(() => _proses = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Kartu(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          JudulKartu(widget.jenis.label),
          const SizedBox(height: 10),
          Row(
            children: [
              GambarBulat(_sumber, ukuran: 72),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  _sumber.isEmpty
                      ? 'Memakai gambar bawaan. Gunakan gambar persegi (jpg/png, maks. 2 MB); tampil dalam lingkaran.'
                      : 'Memakai gambar yang diunggah admin. Tersimpan langsung, tanpa tombol Simpan.',
                  style: tsCap,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: Tombol('Ganti gambar', kecil: true, memuat: _proses, onPressed: _proses ? null : _ganti),
              ),
              if (_sumber.isNotEmpty) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: Tombol(
                    'Pakai bawaan',
                    kecil: true,
                    varian: Varian.garis,
                    onPressed: _proses ? null : _bawaan,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
