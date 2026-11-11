import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../data/repository.dart';
import '../../models/models.dart';
import '../../state/session.dart';
import '../../widgets/media.dart';
import '../../widgets/ui.dart';

/// Formulir Daftar Berobat.
///
/// Batas berkas sesuai demo: foto jpg/png maks. 5 MB (maks. 5), video mp4 maks. 30 MB (1).
/// Foto dikompres di HP untuk menghemat ruang hosting.
class DaftarBerobatPage extends StatefulWidget {
  const DaftarBerobatPage({super.key});

  @override
  State<DaftarBerobatPage> createState() => _DaftarBerobatPageState();
}

class _DaftarBerobatPageState extends State<DaftarBerobatPage> {
  static const _maksFoto = 5, _maksVideo = 1;
  static const _batasFoto = 5 * 1000 * 1000, _batasVideo = 30 * 1000 * 1000;

  final _picker = ImagePicker();
  late final TextEditingController _nama;
  late final TextEditingController _hp;
  final _umur = TextEditingController();
  final _alamat = TextEditingController();
  final _keluhan = TextEditingController();
  final _kondisi = <String>[];
  String? _ktp;
  bool _nikDitutup = false;
  bool _proses = false;

  @override
  void initState() {
    super.initState();
    final u = context.read<Session>().user!;
    _nama = TextEditingController(text: u.nama);
    _hp = TextEditingController(text: u.noHp);
  }

  @override
  void dispose() {
    for (final c in [_nama, _hp, _umur, _alamat, _keluhan]) {
      c.dispose();
    }
    super.dispose();
  }

  int get _jmlVideo => _kondisi.where(adalahVideo).length;
  int get _jmlFoto => _kondisi.length - _jmlVideo;

  Future<void> _tambahBerkas(List<XFile> berkas) async {
    for (final f in berkas) {
      final video = adalahVideo(f.path);
      final ukuran = await f.length();
      if (!mounted) return;
      if (video ? _jmlVideo >= _maksVideo : _jmlFoto >= _maksFoto) {
        return toast(context, 'Terlalu banyak berkas', 'Maks. 5 foto dan 1 video.');
      }
      if (ukuran > (video ? _batasVideo : _batasFoto)) {
        return toast(context, 'Berkas terlalu besar', 'Foto maks. 5 MB, video maks. 30 MB.');
      }
      setState(() => _kondisi.add(f.path));
    }
  }

  Future<void> _pilihKondisi() async {
    final pilihan = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.white,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(leading: const Icon(Icons.photo_camera_outlined), title: const Text('Ambil foto'), onTap: () => Navigator.pop(ctx, 0)),
            ListTile(leading: const Icon(Icons.videocam_outlined), title: const Text('Rekam video'), onTap: () => Navigator.pop(ctx, 1)),
            ListTile(leading: const Icon(Icons.photo_library_outlined), title: const Text('Pilih dari galeri'), onTap: () => Navigator.pop(ctx, 2)),
          ],
        ),
      ),
    );
    try {
      switch (pilihan) {
        case 0:
          final f = await _picker.pickImage(source: ImageSource.camera, maxWidth: 1600, imageQuality: 80);
          await _tambahBerkas([?f]);
        case 1:
          final f = await _picker.pickVideo(source: ImageSource.camera, maxDuration: const Duration(seconds: 60));
          await _tambahBerkas([?f]);
        case 2:
          await _tambahBerkas(await _picker.pickMultipleMedia(maxWidth: 1600, imageQuality: 80));
      }
    } catch (e) {
      if (mounted) toast(context, 'Gagal mengambil berkas', '$e');
    }
  }

  Future<void> _pilihKtp() async {
    final sumber = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: KotakPeringatan(
                child: Text.rich(TextSpan(children: [
                  TextSpan(text: 'Tutup NOMOR NIK', style: TextStyle(fontWeight: FontWeight.w700)),
                  TextSpan(text: ' sebelum memfoto KTP.'),
                ])),
              ),
            ),
            ListTile(leading: const Icon(Icons.photo_camera_outlined), title: const Text('Ambil foto KTP'), onTap: () => Navigator.pop(ctx, ImageSource.camera)),
            ListTile(leading: const Icon(Icons.photo_library_outlined), title: const Text('Pilih dari galeri'), onTap: () => Navigator.pop(ctx, ImageSource.gallery)),
          ],
        ),
      ),
    );
    if (sumber == null) return;
    try {
      final f = await _picker.pickImage(source: sumber, maxWidth: 1600, imageQuality: 80);
      if (f == null || !mounted) return;
      if (await f.length() > _batasFoto) {
        if (mounted) toast(context, 'Berkas terlalu besar', 'Foto maks. 5 MB.');
        return;
      }
      setState(() => _ktp = f.path);
    } catch (e) {
      if (mounted) toast(context, 'Gagal mengambil foto', '$e');
    }
  }

  Future<void> _kirim() async {
    final umur = int.tryParse(_umur.text.trim());
    if ([_nama, _hp, _alamat, _keluhan].any((c) => c.text.trim().isEmpty) || umur == null || umur < 0 || umur > 120) {
      return toast(context, 'Lengkapi', 'Isi nama, umur, nomor HP, alamat, dan keluhan.');
    }
    if (_kondisi.isEmpty) return toast(context, 'Lengkapi', 'Unggah minimal 1 foto/video kondisi.');
    if (_ktp == null) return toast(context, 'Lengkapi', 'Unggah foto KTP dengan NIK ditutup.');
    if (!_nikDitutup) return toast(context, 'Lengkapi', 'Centang bahwa NIK pada foto KTP sudah ditutup.');

    setState(() => _proses = true);
    try {
      await context.read<Repository>().daftarBerobat(FormPendaftaran(
            userId: context.read<Session>().user!.id,
            nama: _nama.text,
            umur: umur,
            noHp: _hp.text,
            alamat: _alamat.text,
            keluhan: _keluhan.text,
            mediaKondisi: List.of(_kondisi),
            fotoKtp: _ktp!,
          ));
      if (!mounted) return;
      toast(context, 'Pendaftaran terkirim', 'Admin akan memeriksa lalu memberi jadwal.');
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) toast(context, 'Gagal mengirim', '$e');
    } finally {
      if (mounted) setState(() => _proses = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bisaTambah = _jmlFoto < _maksFoto || _jmlVideo < _maksVideo;
    return Scaffold(
      appBar: headerApp('Daftar Berobat', aksi: [TombolHeader('Batal', onTap: () => Navigator.pop(context))]),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Label('Nama pasien', atas: 0),
          TextField(controller: _nama, textCapitalization: TextCapitalization.words),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Label('Umur'),
                    TextField(controller: _umur, keyboardType: TextInputType.number),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Label('Nomor HP'),
                    TextField(controller: _hp, keyboardType: TextInputType.phone),
                  ],
                ),
              ),
            ],
          ),
          const Label('Alamat'),
          TextField(
            controller: _alamat,
            decoration: const InputDecoration(hintText: 'Desa/kelurahan, kecamatan, kota'),
          ),
          const Label('Keluhan'),
          TextField(
            controller: _keluhan,
            minLines: 4,
            maxLines: 8,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(hintText: 'Ceritakan keluhan dan sudah berapa lama'),
          ),
          const Label('Foto atau video kondisi pasien (wajib)'),
          GridMedia(
            berkas: _kondisi,
            onHapus: (f) => setState(() => _kondisi.remove(f)),
            tambahan: bisaTambah ? KotakTambah(label: 'Tambah foto/video', onTap: _pilihKondisi) : null,
          ),
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Text('Foto jpg/png maks. 5 MB (maks. 5 berkas), video mp4 maks. 30 MB (1 berkas).', style: tsCap),
          ),
          const Label('Foto KTP (wajib)'),
          const KotakPeringatan(
            child: Text.rich(TextSpan(children: [
              TextSpan(text: 'Tutup NOMOR NIK', style: TextStyle(fontWeight: FontWeight.w700)),
              TextSpan(text: ' pada foto KTP untuk menjaga keamanan data Anda.'),
            ])),
          ),
          GridMedia(
            berkas: [?_ktp],
            label: 'KTP',
            onHapus: (_) => setState(() => _ktp = null),
            tambahan: _ktp == null ? KotakTambah(label: 'Foto KTP', onTap: _pilihKtp) : null,
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: () => setState(() => _nikDitutup = !_nikDitutup),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  SizedBox(
                    width: 22,
                    height: 22,
                    child: Checkbox(
                      value: _nikDitutup,
                      onChanged: (v) => setState(() => _nikDitutup = v ?? false),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(child: Text('NIK pada foto KTP sudah saya tutup.', style: TextStyle(fontSize: 14))),
                ],
              ),
            ),
          ),
          Tombol('Kirim Pendaftaran', memuat: _proses, onPressed: _kirim),
        ],
      ),
    );
  }
}
