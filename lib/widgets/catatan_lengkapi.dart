import 'package:flutter/material.dart';

import '../core/format.dart';
import '../core/theme.dart';
import '../models/models.dart';

/// Catatan "perlu dilengkapi" dari admin. Tetap tampil setelah pasien melengkapi
/// (status kembali Menunggu) beserta waktu dilengkapi.
class KartuCatatanLengkapi extends StatelessWidget {
  const KartuCatatanLengkapi(this.p, {super.key, this.admin = false, this.aksi = const []});

  final Pendaftaran p;
  final bool admin;
  final List<Widget> aksi;

  static const _latar = Color(0xFFFDE7D6), _teks = Color(0xFF9A4A00);

  @override
  Widget build(BuildContext context) {
    final perlu = p.status == StatusPendaftaran.perluDilengkapi;
    final keterangan = perlu
        ? (admin ? 'Menunggu pasien melengkapi.' : 'Perbaiki data atau berkas sesuai catatan di atas, lalu kirim lagi.')
        : p.dilengkapi != null
            ? 'Sudah dilengkapi ${fmtWaktu(p.dilengkapi!)}.'
            : null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _latar,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF1C7A6)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(perlu ? 'Pendaftaran perlu dilengkapi' : 'Catatan perlu dilengkapi',
                style: lora(17, color: _teks)),
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(p.catatan ?? '', style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.tx)),
            ),
            if (keterangan != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(keterangan, style: TextStyle(fontSize: 13, color: perlu ? _teks : AppColors.ok)),
              ),
            ...aksi,
          ],
        ),
      ),
    );
  }
}
