import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/klinik.dart';
import '../data/repository.dart';
import '../models/models.dart';

/// Gambar Info klinik yang memuat sendiri ([InfoKlinik.gambar]), mis. logo di halaman
/// Masuk & Daftar Akun.
///
/// Selama memuat, saat offline, atau bila gambar gagal dimuat, tampil gambar bawaan
/// sehingga tidak pernah kosong. Ikut berubah begitu admin menggantinya.
class GambarKlinik extends StatefulWidget {
  const GambarKlinik(this.jenis, {super.key, this.ukuran = 120});

  final JenisGambar jenis;
  final double ukuran;

  @override
  State<GambarKlinik> createState() => _GambarKlinikState();
}

class _GambarKlinikState extends State<GambarKlinik> {
  Repository? _repo;
  String _sumber = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final repo = context.read<Repository>();
    if (!identical(repo, _repo)) {
      _repo?.removeListener(_muat);
      _repo = repo..addListener(_muat);
      _muat();
    }
  }

  @override
  void dispose() {
    _repo?.removeListener(_muat);
    super.dispose();
  }

  Future<void> _muat() async {
    try {
      final s = (await _repo!.infoKlinik()).gambar(widget.jenis);
      if (mounted && s != _sumber) setState(() => _sumber = s);
    } catch (_) {
      // Tetap gambar terakhir / bawaan.
    }
  }

  @override
  Widget build(BuildContext context) => GambarBulat(_sumber, ukuran: widget.ukuran);
}

/// Gambar bulat dari URL server, path berkas, atau bawaan bila [sumber] kosong.
///
/// Gaya bawaan: bingkai putih + bayangan (halaman Masuk). Ubah lewat [bingkai] / [bayangan].
class GambarBulat extends StatelessWidget {
  const GambarBulat(
    this.sumber, {
    super.key,
    this.ukuran = 120,
    this.bingkai = const BorderSide(color: Colors.white, width: 4),
    this.bayangan = true,
  });

  final String sumber;
  final double ukuran;
  final BorderSide bingkai;
  final bool bayangan;

  @override
  Widget build(BuildContext context) {
    Widget bawaan(BuildContext c, Object e, StackTrace? s) => _bawaan();
    final gambar = sumber.isEmpty
        ? _bawaan()
        : sumber.startsWith('http')
        ? Image.network(sumber, fit: BoxFit.cover, errorBuilder: bawaan)
        : Image.file(File(sumber), fit: BoxFit.cover, errorBuilder: bawaan);
    return Container(
      width: ukuran,
      height: ukuran,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.fromBorderSide(bingkai),
        boxShadow: bayangan
            ? const [BoxShadow(color: Color(0x22000000), blurRadius: 14, offset: Offset(0, 4))]
            : null,
      ),
      child: ClipOval(child: SizedBox.expand(child: gambar)),
    );
  }

  // Foto bawaan: wajah sedikit ke atas agar pas di lingkaran.
  static Widget _bawaan() => Image.asset(Klinik.foto, fit: BoxFit.cover, alignment: const Alignment(0, -0.7));
}
