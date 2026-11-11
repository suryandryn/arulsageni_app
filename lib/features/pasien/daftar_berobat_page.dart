import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../data/repository.dart';
import '../../models/models.dart';
import '../../state/session.dart';
import '../../widgets/media_preview.dart';

/// Formulir Daftar Berobat.
///
/// Foto dikompres di HP (maks. 1600 px, kualitas 80) dan video dibatasi 30 detik
/// untuk menghemat ruang hosting (lihat docs/ARSITEKTUR.md).
class DaftarBerobatPage extends StatefulWidget {
  const DaftarBerobatPage({super.key});

  @override
  State<DaftarBerobatPage> createState() => _DaftarBerobatPageState();
}

class _DaftarBerobatPageState extends State<DaftarBerobatPage> {
  static const _maksMedia = 5;

  final _form = GlobalKey<FormState>();
  final _picker = ImagePicker();
  late final TextEditingController _nama;
  late final TextEditingController _wa;
  final _kota = TextEditingController();
  final _keluhan = TextEditingController();
  final _media = <String>[];
  String? _ktp;
  bool _proses = false;
  bool _cobaKirim = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<Session>().user!;
    _nama = TextEditingController(text: user.nama);
    _wa = TextEditingController(text: user.noWa);
  }

  @override
  void dispose() {
    for (final c in [_nama, _wa, _kota, _keluhan]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _tambahMedia(Future<List<XFile>> Function() ambil) async {
    try {
      final hasil = await ambil();
      setState(() {
        for (final f in hasil) {
          if (_media.length < _maksMedia) _media.add(f.path);
        }
      });
    } catch (e) {
      _info('Gagal mengambil media: $e');
    }
  }

  Future<void> _pilihSumberMedia() async {
    final pilihan = await showModalBottomSheet<int>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(leading: const Icon(Icons.photo_camera), title: const Text('Ambil foto'), onTap: () => Navigator.pop(ctx, 0)),
            ListTile(leading: const Icon(Icons.videocam), title: const Text('Rekam video (maks. 30 detik)'), onTap: () => Navigator.pop(ctx, 1)),
            ListTile(leading: const Icon(Icons.photo_library), title: const Text('Pilih dari galeri'), onTap: () => Navigator.pop(ctx, 2)),
          ],
        ),
      ),
    );
    switch (pilihan) {
      case 0:
        await _tambahMedia(() async {
          final f = await _picker.pickImage(source: ImageSource.camera, maxWidth: 1600, imageQuality: 80);
          return [?f];
        });
      case 1:
        await _tambahMedia(() async {
          final f = await _picker.pickVideo(source: ImageSource.camera, maxDuration: const Duration(seconds: 30));
          return [?f];
        });
      case 2:
        await _tambahMedia(() => _picker.pickMultipleMedia(maxWidth: 1600, imageQuality: 80));
    }
  }

  Future<void> _pilihKtp() async {
    final lanjut = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 40),
        title: const Text('Tutup NOMOR NIK'),
        content: const Text(
          'Sebelum memfoto KTP, TUTUP nomor NIK dengan kertas atau jari.\n\n'
          'Ini untuk menjaga keamanan data Anda. Foto KTP hanya dapat dilihat admin klinik.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('NIK sudah saya tutup')),
        ],
      ),
    );
    if (lanjut != true) return;
    try {
      final f = await _picker.pickImage(source: ImageSource.camera, maxWidth: 1600, imageQuality: 80);
      if (f != null) setState(() => _ktp = f.path);
    } catch (e) {
      _info('Gagal mengambil foto KTP: $e');
    }
  }

  Future<void> _kirim() async {
    setState(() => _cobaKirim = true);
    final valid = _form.currentState!.validate();
    if (!valid || _media.isEmpty) return;
    setState(() => _proses = true);
    try {
      final p = await context.read<Repository>().daftarBerobat(FormPendaftaran(
            userId: context.read<Session>().user!.id,
            nama: _nama.text.trim(),
            noWa: _wa.text.trim(),
            kota: _kota.text.trim(),
            keluhan: _keluhan.text.trim(),
            mediaKondisi: List.of(_media),
            fotoKtp: _ktp,
          ));
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          icon: const Icon(Icons.check_circle, color: AppColors.hijau, size: 48),
          title: const Text('Pendaftaran terkirim'),
          content: Text('Kode pendaftaran: ${p.kode}\n\n'
              'Admin akan memeriksa data Anda. Anda akan mendapat notifikasi saat jadwal diberikan.'),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
        ),
      );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      _info('$e');
    } finally {
      if (mounted) setState(() => _proses = false);
    }
  }

  void _info(String pesan) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(pesan)));
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    String? wajib(String? v) => (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null;
    return Scaffold(
      appBar: AppBar(title: const Text('Daftar Berobat')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(controller: _nama, decoration: const InputDecoration(labelText: 'Nama pasien'), validator: wajib),
            const SizedBox(height: 12),
            TextFormField(
              controller: _wa,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Nomor WhatsApp'),
              validator: wajib,
            ),
            const SizedBox(height: 12),
            TextFormField(controller: _kota, decoration: const InputDecoration(labelText: 'Kota / Kabupaten'), validator: wajib),
            const SizedBox(height: 12),
            TextFormField(
              controller: _keluhan,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Keluhan', alignLabelWithHint: true),
              validator: wajib,
            ),
            const SizedBox(height: 20),
            Text('Foto / video kondisi pasien *', style: tema.textTheme.titleSmall),
            const SizedBox(height: 4),
            const Text('Wajib. Maksimal 5 file. Video maksimal 30 detik.', style: TextStyle(fontSize: 12)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final m in _media)
                  MediaThumb(m, onHapus: () => setState(() => _media.remove(m))),
                if (_media.length < _maksMedia)
                  _TombolTambah(label: 'Tambah', onTap: _pilihSumberMedia),
              ],
            ),
            if (_cobaKirim && _media.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text('Foto atau video kondisi pasien wajib dilampirkan.',
                    style: TextStyle(color: tema.colorScheme.error, fontSize: 12)),
              ),
            const SizedBox(height: 20),
            Text('Foto KTP', style: tema.textTheme.titleSmall),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF4DB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFF2C94C)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.shield_outlined, color: Color(0xFF8A5A00)),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text('NOMOR NIK WAJIB DITUTUP sebelum difoto, demi keamanan data Anda.',
                        style: TextStyle(color: Color(0xFF8A5A00), fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                if (_ktp != null) MediaThumb(_ktp!, onHapus: () => setState(() => _ktp = null)),
                if (_ktp == null) _TombolTambah(label: 'Foto KTP', onTap: _pilihKtp),
              ],
            ),
            const SizedBox(height: 28),
            FilledButton(
              onPressed: _proses ? null : _kirim,
              child: _proses
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Kirim Pendaftaran'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TombolTambah extends StatelessWidget {
  const _TombolTambah({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 88,
        height: 88,
        decoration: BoxDecoration(
          color: AppColors.hijauMuda,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.hijau.withValues(alpha: 0.4)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_a_photo_outlined, color: AppColors.hijau),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 12, color: AppColors.hijau)),
          ],
        ),
      ),
    );
  }
}
