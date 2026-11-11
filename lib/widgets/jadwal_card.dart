import 'package:flutter/material.dart';

import '../core/format.dart';
import '../core/klinik.dart';
import '../core/theme.dart';
import '../models/models.dart';
import 'kontak.dart';
import 'ui.dart';

/// Kartu jadwal hijau bergaris emas (.jadwal) + kartu arahan (.ket).
class KartuJadwal extends StatelessWidget {
  const KartuJadwal(this.p, {super.key});

  final Pendaftaran p;

  @override
  Widget build(BuildContext context) {
    final t = p.tanggal!;
    const putih = TextStyle(color: Colors.white);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              color: AppColors.pri,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(height: 4, color: AppColors.gold),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('Jadwal berobat - ${p.nama}',
                            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text(fmtHariTanggal(t),
                              style: lora(26, weight: FontWeight.w700, color: Colors.white, height: 1.25)),
                        ),
                        Text('${t.year} - pukul ${p.jam} WIB', style: putih),
                        const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: _GarisPutus()),
                        Row(
                          children: [
                            const Expanded(child: Text(Klinik.nama, style: putih)),
                            Text(hMinus(t), style: putih.copyWith(fontWeight: FontWeight.w700)),
                          ],
                        ),
                        Tombol('Buka Google Maps',
                            varian: Varian.putih, atas: 12, onPressed: () => bukaUrl(context, Klinik.maps)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        _KartuArahan(p),
      ],
    );
  }
}

class _KartuArahan extends StatelessWidget {
  const _KartuArahan(this.p);
  final Pendaftaran p;

  @override
  Widget build(BuildContext context) {
    final tgl = fmtTanggal(p.tanggal!).toUpperCase().replaceFirst(',', '');
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.card,
            border: Border(
              left: BorderSide(color: AppColors.gold, width: 4),
              top: BorderSide(color: AppColors.bd),
              right: BorderSide(color: AppColors.bd),
              bottom: BorderSide(color: AppColors.bd),
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: DefaultTextStyle.merge(
            style: const TextStyle(fontSize: 14, height: 1.55),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('JADWAL BEROBAT (${p.nama.toUpperCase()})', style: const TextStyle(fontWeight: FontWeight.w700)),
                for (final par in Klinik.arahanJadwal(tgl))
                  Padding(padding: const EdgeInsets.only(top: 8), child: Text(par)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GarisPutus extends StatelessWidget {
  const _GarisPutus();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final n = (c.maxWidth / 6).floor();
        return Row(
          children: [
            for (var i = 0; i < n; i++)
              Container(width: 3, height: 1, margin: const EdgeInsets.only(right: 3), color: const Color(0x66FFFFFF)),
          ],
        );
      },
    );
  }
}
