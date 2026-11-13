import 'package:flutter/material.dart';

import '../core/format.dart';
import '../core/theme.dart';
import '../models/models.dart';
import 'ui.dart';

/// Kartu pengajuan jadwal ulang / pembatalan terbaru dari pasien.
/// [aksi] (mis. tombol Setujui/Tolak admin atau Tarik pasien) tampil di bawah isi.
class KartuPengajuan extends StatelessWidget {
  const KartuPengajuan(this.p, {super.key, this.admin = false, this.aksi = const []});

  final Pendaftaran p;
  final bool admin;
  final List<Widget> aksi;

  static (Color, Color) warna(StatusPengajuan s) => switch (s) {
        StatusPengajuan.menunggu => (const Color(0xFFF6ECD6), AppColors.wtx),
        StatusPengajuan.disetujui => (const Color(0xFFE2F0E7), AppColors.ok),
        StatusPengajuan.ditolak => (const Color(0xFFFBE4E2), AppColors.red),
      };

  @override
  Widget build(BuildContext context) {
    final a = p.pengajuan!;
    final (bg, fg) = warna(a.status);
    final judul = admin ? 'Pengajuan ${a.jenis.label.toLowerCase()} dari pasien' : 'Pengajuan ${a.jenis.label.toLowerCase()}';
    return Kartu(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Baris(kiri: Text(judul, style: lora(17)), kanan: Tag(a.status.label, bg: bg, fg: fg)),
          Padding(
            padding: const EdgeInsets.only(top: 2, bottom: 8),
            child: Text('Diajukan ${fmtWaktu(a.dibuat)}', style: tsCap),
          ),
          if (a.jenis == JenisPengajuan.jadwalUlang) ...[
            if (admin && p.tanggal != null && a.status == StatusPengajuan.menunggu)
              _Isi('Jadwal sekarang', '${fmtTanggal(p.tanggal!)} pukul ${p.jam}'),
            _Isi('Jadwal yang diminta', '${fmtTanggal(a.tanggal!)} pukul ${a.jam}', tebal: true),
          ],
          _Isi(admin ? 'Alasan pasien' : 'Alasan Anda', a.alasan ?? '-'),
          if (a.status == StatusPengajuan.ditolak && a.alasanTolak != null)
            _Isi('Alasan ditolak', a.alasanTolak!, warna: AppColors.red),
          if (!admin && a.status == StatusPengajuan.menunggu)
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text('Admin akan meninjau pengajuan ini. Hasilnya dikirim lewat notifikasi.', style: tsMut),
            ),
          ...aksi,
        ],
      ),
    );
  }
}

class _Isi extends StatelessWidget {
  const _Isi(this.label, this.isi, {this.tebal = false, this.warna});
  final String label;
  final String isi;
  final bool tebal;
  final Color? warna;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: tsCap),
            Text(isi, style: TextStyle(fontWeight: tebal ? FontWeight.w700 : FontWeight.w500, color: warna)),
          ],
        ),
      );
}

/// Dialog isian alasan; mengembalikan teks (boleh kosong bila tidak [wajib]) atau null bila dibatalkan.
Future<String?> mintaAlasan(
  BuildContext context, {
  required String judul,
  required String label,
  required String tombol,
  String? petunjuk,
  bool wajib = false,
  bool merah = false,
}) =>
    showDialog<String>(
      context: context,
      builder: (_) => _DialogAlasan(
        judul: judul,
        label: label,
        tombol: tombol,
        petunjuk: petunjuk,
        wajib: wajib,
        merah: merah,
      ),
    );

class _DialogAlasan extends StatefulWidget {
  const _DialogAlasan({
    required this.judul,
    required this.label,
    required this.tombol,
    required this.petunjuk,
    required this.wajib,
    required this.merah,
  });

  final String judul;
  final String label;
  final String tombol;
  final String? petunjuk;
  final bool wajib;
  final bool merah;

  @override
  State<_DialogAlasan> createState() => _DialogAlasanState();
}

class _DialogAlasanState extends State<_DialogAlasan> {
  final _c = TextEditingController();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final kosong = _c.text.trim().isEmpty;
    return AlertDialog(
      title: Text(widget.judul, style: lora(18)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Label(widget.label, atas: 0),
          TextField(
            controller: _c,
            autofocus: true,
            minLines: 3,
            maxLines: 5,
            maxLength: 1000,
            decoration: InputDecoration(hintText: widget.petunjuk),
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Kembali')),
        TextButton(
          onPressed: widget.wajib && kosong ? null : () => Navigator.pop(context, _c.text.trim()),
          style: TextButton.styleFrom(foregroundColor: widget.merah ? AppColors.red : AppColors.pri),
          child: Text(widget.tombol),
        ),
      ],
    );
  }
}
