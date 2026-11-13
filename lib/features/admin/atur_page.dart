import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../core/klinik.dart';
import '../../core/theme.dart';
import '../../data/repository.dart';
import '../../models/models.dart';
import '../../state/session.dart';
import '../../widgets/async_view.dart';
import '../../widgets/ui.dart';
import 'admin_shell.dart';
import 'chat_admin_page.dart';
import 'info_klinik_page.dart';

class AturPage extends StatelessWidget {
  const AturPage({super.key});

  @override
  Widget build(BuildContext context) {
    void buka(Widget w) => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => w));
    return Scaffold(
      appBar: headerApp('Atur'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Kartu(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                _ItemMenu('Data pasien', () => buka(const DataPasienPage())),
                _ItemMenu('Media sosial', () => buka(const MediaSosialPage())),
                _ItemMenu('Info klinik', () => buka(const InfoKlinikPage())),
                _ItemMenu('Kalender & slot jadwal', () => tabAdmin.value = 2, terakhir: true),
              ],
            ),
          ),
          Kartu(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Builder(
              builder: (context) {
                final u = context.watch<Session>().user!;
                return _ItemMenu('Akun admin: ${u.nama}', () => buka(const AkunAdminPage()), terakhir: true);
              },
            ),
          ),
          const Text(
            'Alamat, Google Maps, WA admin, biaya, website, dan kalimat jadwal diatur di Info klinik.',
            style: tsCap,
          ),
          Tombol('Keluar', varian: Varian.merah, onPressed: context.read<Session>().keluar),
        ],
      ),
    );
  }
}

/// Baris menu (.mlist a).
class _ItemMenu extends StatelessWidget {
  const _ItemMenu(this.label, this.onTap, {this.terakhir = false});
  final String label;
  final VoidCallback onTap;
  final bool terakhir;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          border: terakhir ? null : const Border(bottom: BorderSide(color: AppColors.bd)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
            const Text('›', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

// ======================================================================= data pasien

class DataPasienPage extends StatefulWidget {
  const DataPasienPage({super.key});

  @override
  State<DataPasienPage> createState() => _DataPasienPageState();
}

class _DataPasienPageState extends State<DataPasienPage> {
  String _q = '';
  Timer? _tunda;

  @override
  void dispose() {
    _tunda?.cancel();
    super.dispose();
  }

  // Cari saat mengetik, ditunda sebentar agar tidak memanggil server tiap huruf.
  void _ketik(String v) {
    _tunda?.cancel();
    _tunda = Timer(const Duration(milliseconds: 400), () {
      if (mounted) setState(() => _q = v.trim());
    });
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.read<Repository>();
    return Scaffold(
      appBar: headerApp('Data Pasien', kembali: true),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: TextField(
              decoration: const InputDecoration(hintText: 'Cari nama atau nomor HP', prefixIcon: Icon(Icons.search)),
              onChanged: _ketik,
            ),
          ),
          AsyncView(
            key: ValueKey(_q),
            load: (repo) => repo.akunPasien(cari: _q),
            builder: (context, list) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (list.isEmpty) TeksKosong(_q.isEmpty ? 'Belum ada akun pasien.' : 'Tidak ada pasien yang cocok.'),
                for (final a in list)
                  Kartu(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Baris(
                          kiri: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(a.nama, style: const TextStyle(fontWeight: FontWeight.w700)),
                              Text(a.noHp, style: tsMut),
                              if (a.dibuat != null) Text('Terdaftar ${fmtPendek(a.dibuat!)}', style: tsCap),
                            ],
                          ),
                          kanan: Tag.aktif(a.aktif),
                        ),
                        if (a.jumlahPendaftaran != null)
                          InkWell(
                            onTap: a.jumlahPendaftaran! > 0
                                ? () => bukaPendaftaranAdmin(context, null, cari: a.noHp)
                                : null,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Text(
                                '${a.jumlahPendaftaran} pendaftaran${a.jumlahPendaftaran! > 0 ? ' ›' : ''}',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: a.jumlahPendaftaran! > 0 ? AppColors.pri : AppColors.mut,
                                ),
                              ),
                            ),
                          ),
                        DeretPil(
                          children: [
                            Pil('Chat', onTap: () => bukaChatAdmin(context, a.id)),
                            Pil(
                              'Reset sandi',
                              onTap: () async {
                                if (!await konfirmasi(context, 'Buat sandi baru untuk ${a.nama}?')) return;
                                final String sandi;
                                try {
                                  sandi = await repo.resetSandi(a.id);
                                } catch (e) {
                                  if (context.mounted) toast(context, 'Gagal reset sandi', '$e');
                                  return;
                                }
                                if (!context.mounted) return;
                                // Dialog (bukan toast) agar admin sempat mencatat sandinya.
                                await showDialog<void>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Sandi direset'),
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Sandi sementara ${a.nama}:'),
                                        const SizedBox(height: 8),
                                        SelectableText(
                                          sandi,
                                          style: const TextStyle(
                                            fontSize: 28,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 4,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        const Text('Kirim ke pasien lewat WhatsApp.', style: tsMut),
                                      ],
                                    ),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Tutup')),
                                    ],
                                  ),
                                );
                              },
                            ),
                            Pil(
                              a.aktif ? 'Nonaktifkan' : 'Aktifkan',
                              onTap: () async {
                                final pesan = a.aktif
                                    ? 'Nonaktifkan akun ${a.nama}? Pasien tidak bisa masuk aplikasi.'
                                    : 'Aktifkan akun ${a.nama}?';
                                if (!await konfirmasi(context, pesan)) return;
                                try {
                                  await repo.aturAkunAktif(a.id, !a.aktif);
                                  if (context.mounted) {
                                    toast(
                                      context,
                                      a.aktif ? 'Akun dinonaktifkan' : 'Akun diaktifkan',
                                      a.aktif ? '${a.nama} tidak bisa masuk aplikasi.' : '${a.nama} bisa masuk lagi.',
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) toast(context, 'Gagal', '$e');
                                }
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ======================================================================= media sosial

/// Atur tautan media sosial, sama dengan halaman Media Sosial di panel web:
/// ubah langsung di daftar (platform, nama, URL, aktif, urutan), lalu Simpan sekaligus.
/// Bila belum ada perubahan, daftar ikut diperbarui saat data diubah dari web.
class MediaSosialPage extends StatefulWidget {
  const MediaSosialPage({super.key});

  @override
  State<MediaSosialPage> createState() => _MediaSosialPageState();
}

class _BarisMedsos {
  _BarisMedsos(MediaSosial m)
    : platform = m.platform,
      aktif = m.aktif,
      nama = TextEditingController(text: m.nama),
      url = TextEditingController(text: m.url);

  String platform;
  bool aktif;
  final TextEditingController nama;
  final TextEditingController url;

  MediaSosial get nilai => MediaSosial(platform: platform, nama: nama.text.trim(), url: url.text.trim(), aktif: aktif);

  void dispose() {
    nama.dispose();
    url.dispose();
  }
}

class _MediaSosialPageState extends State<MediaSosialPage> {
  late final Repository _repo;
  List<_BarisMedsos>? _baris;
  List<MediaSosial> _awal = const [];
  Object? _galat;
  bool _menyimpan = false;
  bool _cekIsian = false;

  @override
  void initState() {
    super.initState();
    _repo = context.read<Repository>()..addListener(_muatBilaBersih);
    _muat();
  }

  @override
  void dispose() {
    _repo.removeListener(_muatBilaBersih);
    for (final b in _baris ?? const <_BarisMedsos>[]) {
      b.dispose();
    }
    super.dispose();
  }

  bool get _berubah {
    final b = _baris;
    if (b == null) return false;
    if (b.length != _awal.length) return true;
    for (var i = 0; i < b.length; i++) {
      final x = b[i].nilai, y = _awal[i];
      if (x.platform != y.platform || x.nama != y.nama || x.url != y.url || x.aktif != y.aktif) return true;
    }
    return false;
  }

  void _muatBilaBersih() {
    if (!_berubah && !_menyimpan) _muat();
  }

  Future<void> _muat() async {
    try {
      final list = await _repo.mediaSosial();
      if (!mounted) return;
      setState(() {
        for (final b in _baris ?? const <_BarisMedsos>[]) {
          b.dispose();
        }
        _awal = list;
        _baris = [for (final m in list) _BarisMedsos(m)];
        _galat = null;
        _cekIsian = false;
      });
    } catch (e) {
      if (mounted && _baris == null) setState(() => _galat = e);
    }
  }

  String? _galatNama(_BarisMedsos b) => _cekIsian && b.nama.text.trim().isEmpty ? 'Isi nama akun.' : null;

  String? _galatUrl(_BarisMedsos b) =>
      _cekIsian && !RegExp(r'^https://\S+$').hasMatch(b.url.text.trim()) ? 'URL wajib diawali https://' : null;

  Future<void> _simpan() async {
    final baris = _baris!;
    setState(() => _cekIsian = true);
    if (baris.any((b) => _galatNama(b) != null || _galatUrl(b) != null)) {
      return toast(context, 'Periksa isian', 'Ada nama atau URL yang belum benar.');
    }
    setState(() => _menyimpan = true);
    try {
      final daftar = [for (final b in baris) b.nilai];
      await _repo.simpanMediaSosial(daftar);
      if (!mounted) return;
      setState(() {
        _awal = daftar;
        _cekIsian = false;
      });
      toast(context, 'Media sosial disimpan.', 'Langsung tampil di menu Info dan panel web.');
    } catch (e) {
      if (mounted) toast(context, 'Gagal menyimpan', '$e');
    } finally {
      if (mounted) setState(() => _menyimpan = false);
    }
  }

  void _geser(int i, int n) => setState(() {
    final b = _baris!;
    final x = b[i];
    b[i] = b[i + n];
    b[i + n] = x;
  });

  @override
  Widget build(BuildContext context) {
    final baris = _baris;
    return PopScope(
      canPop: !_berubah,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final nav = Navigator.of(context);
        if (await konfirmasi(context, 'Perubahan belum disimpan. Tetap keluar?')) nav.pop();
      },
      child: Scaffold(
        appBar: headerApp('Media Sosial', kembali: true),
        body: baris == null
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
                    child: Text(
                      'Tautan yang aktif tampil di menu Info aplikasi pasien, sesuai urutan di bawah.',
                      style: tsMut,
                    ),
                  ),
                  for (var i = 0; i < baris.length; i++) _kartu(baris, i),
                  Row(
                    children: [
                      Expanded(
                        child: Tombol(
                          'Tambah',
                          varian: Varian.garis,
                          onPressed: () {
                            setState(
                              () => baris.add(
                                _BarisMedsos(MediaSosial(platform: platformMedsos.first, nama: '', url: 'https://')),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Tombol('Simpan', memuat: _menyimpan, onPressed: _berubah ? _simpan : null),
                      ),
                    ],
                  ),
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

  Widget _kartu(List<_BarisMedsos> baris, int i) {
    final b = baris[i];
    return Opacity(
      opacity: b.aktif ? 1 : 0.6,
      child: Kartu(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<String>(
              key: ObjectKey(b),
              initialValue: platformMedsos.contains(b.platform) ? b.platform : platformMedsos.first,
              decoration: const InputDecoration(labelText: 'Platform'),
              items: [for (final p in platformMedsos) DropdownMenuItem(value: p, child: Text(p))],
              onChanged: (v) => setState(() => b.platform = v ?? b.platform),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: b.nama,
              decoration: InputDecoration(labelText: 'Nama akun', errorText: _galatNama(b)),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: b.url,
              keyboardType: TextInputType.url,
              decoration: InputDecoration(labelText: 'URL', hintText: 'https://', errorText: _galatUrl(b)),
              onChanged: (_) => setState(() {}),
            ),
            Row(
              children: [
                Switch(value: b.aktif, onChanged: (v) => setState(() => b.aktif = v)),
                const Text('Aktif'),
                const Spacer(),
                IconButton(
                  tooltip: 'Naik',
                  icon: const Icon(Icons.arrow_upward),
                  onPressed: i == 0 ? null : () => _geser(i, -1),
                ),
                IconButton(
                  tooltip: 'Turun',
                  icon: const Icon(Icons.arrow_downward),
                  onPressed: i == baris.length - 1 ? null : () => _geser(i, 1),
                ),
                IconButton(
                  tooltip: 'Hapus',
                  color: AppColors.red,
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => setState(() => baris.removeAt(i).dispose()),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ======================================================================= akun admin

/// Profil (nama, email) dan kata sandi admin; sama dengan Pengaturan di panel web.
class AkunAdminPage extends StatefulWidget {
  const AkunAdminPage({super.key});

  @override
  State<AkunAdminPage> createState() => _AkunAdminPageState();
}

class _AkunAdminPageState extends State<AkunAdminPage> {
  late final AppUser _u = context.read<Session>().user!;
  late final _nama = TextEditingController(text: _u.nama);
  late final _email = TextEditingController(text: _u.email ?? '');
  final _lama = TextEditingController();
  final _baru = TextEditingController();
  final _ulangi = TextEditingController();
  bool _simpanProfil = false, _simpanSandi = false;

  @override
  void dispose() {
    for (final c in [_nama, _email, _lama, _baru, _ulangi]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _profil() async {
    if (_nama.text.trim().isEmpty) return toast(context, 'Lengkapi', 'Isi nama.');
    final e = _email.text.trim();
    if (e.isNotEmpty && !RegExp(r'^\S+@\S+\.\S+$').hasMatch(e)) {
      return toast(context, 'Periksa isian', 'Format email tidak valid.');
    }
    setState(() => _simpanProfil = true);
    try {
      await context.read<Session>().ubahProfilAdmin(nama: _nama.text, email: e);
      if (mounted) toast(context, 'Profil disimpan', '');
    } catch (err) {
      if (mounted) toast(context, 'Gagal menyimpan', '$err');
    } finally {
      if (mounted) setState(() => _simpanProfil = false);
    }
  }

  Future<void> _sandi() async {
    if (_lama.text.isEmpty) return toast(context, 'Lengkapi', 'Isi kata sandi lama.');
    if (_baru.text.length < 6) return toast(context, 'Kata sandi terlalu pendek', 'Minimal 6 karakter.');
    if (_baru.text != _ulangi.text) {
      return toast(context, 'Kata sandi tidak sama', 'Ketik ulang kata sandi baru yang sama.');
    }
    setState(() => _simpanSandi = true);
    try {
      await context.read<Repository>().ubahSandi(_u.id, _baru.text, sandiLama: _lama.text);
      for (final c in [_lama, _baru, _ulangi]) {
        c.clear();
      }
      if (mounted) toast(context, 'Kata sandi diperbarui', 'Pakai sandi baru saat masuk berikutnya.');
    } catch (err) {
      if (mounted) toast(context, 'Gagal', '$err');
    } finally {
      if (mounted) setState(() => _simpanSandi = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: headerApp('Akun Admin', kembali: true),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Kartu(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const JudulKartu('Profil'),
                Text('Nama pengguna: ${_u.noHp} - ${Klinik.nama}', style: tsCap),
                const Label('Nama'),
                TextField(controller: _nama, textCapitalization: TextCapitalization.words),
                const Label('Email (boleh kosong)'),
                TextField(controller: _email, keyboardType: TextInputType.emailAddress),
                Tombol('Simpan profil', memuat: _simpanProfil, onPressed: _profil),
              ],
            ),
          ),
          Kartu(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const JudulKartu('Ubah kata sandi'),
                const Label('Kata sandi lama'),
                TextField(controller: _lama, obscureText: true, autofillHints: const [AutofillHints.password]),
                const Label('Kata sandi baru'),
                TextField(controller: _baru, obscureText: true, autofillHints: const [AutofillHints.newPassword]),
                const Label('Ulangi kata sandi baru'),
                TextField(controller: _ulangi, obscureText: true, onSubmitted: (_) => _sandi()),
                Tombol('Simpan kata sandi', varian: Varian.garis, memuat: _simpanSandi, onPressed: _sandi),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
