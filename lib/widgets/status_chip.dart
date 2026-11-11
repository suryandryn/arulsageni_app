import 'package:flutter/material.dart';

import '../models/models.dart';

class StatusChip extends StatelessWidget {
  const StatusChip(this.status, {super.key});

  final StatusPendaftaran status;

  static (Color, Color) warna(StatusPendaftaran s) => switch (s) {
        StatusPendaftaran.menungguVerifikasi => (const Color(0xFFFFF4DB), const Color(0xFF8A5A00)),
        StatusPendaftaran.perluDilengkapi => (const Color(0xFFFFE8D6), const Color(0xFFB04A00)),
        StatusPendaftaran.terjadwal => (const Color(0xFFE6F3EC), const Color(0xFF145A39)),
        StatusPendaftaran.selesai => (const Color(0xFFE3EEFB), const Color(0xFF1D4E89)),
        StatusPendaftaran.tidakDapatDitangani ||
        StatusPendaftaran.tidakHadir => (const Color(0xFFFBE4E4), const Color(0xFF9B1C1C)),
        StatusPendaftaran.dibatalkan => (const Color(0xFFEDEDED), const Color(0xFF555555)),
      };

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = warna(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(
        status.label,
        style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}
