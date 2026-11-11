import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../state/session.dart';
import '../../widgets/async_view.dart';
import '../../widgets/jadwal_card.dart';
import '../../widgets/ui.dart';
import 'daftar_berobat_page.dart';
import 'pasien_shell.dart';
import 'pendaftaran_page.dart';

class BerandaPage extends StatelessWidget {
  const BerandaPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<Session>().user!;
    return Scaffold(
      appBar: headerApp('Halo, ${user.nama.split(' ').first}', aksi: const [TombolNotif()]),
      body: AsyncView(
        load: (repo) => repo.pendaftaranSaya(user.id),
        builder: (context, daftar) {
          final jadwal = daftar.where((p) => p.status == StatusPendaftaran.dijadwalkan).toList()
            ..sort((a, b) => a.tanggal!.compareTo(b.tanggal!));
          final terdekat = jadwal.firstOrNull;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (terdekat != null)
                KartuJadwal(terdekat)
              else
                const Kartu(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      JudulKartu('Belum ada jadwal'),
                      Text('Kirim pendaftaran berobat. Admin akan memeriksa lalu memberi jadwal.', style: tsMut),
                    ],
                  ),
                ),
              Tombol(
                'Daftar Berobat',
                atas: 0,
                varian: terdekat != null ? Varian.garis : Varian.primer,
                onPressed: () => bukaDaftarBerobat(context),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 20, bottom: 8),
                child: Text('Pendaftaran saya', style: lora(18)),
              ),
              if (daftar.isEmpty) const TeksKosong('Belum ada pendaftaran.'),
              for (final p in daftar) KartuPendaftaranSaya(p),
              const Kartu(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    JudulKartu('Jadwal tersimpan di akun Anda'),
                    Text('Jadwal tersimpan di server, bukan hanya di HP. Ganti HP? Cukup masuk lagi.', style: tsMut),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Kartu pendaftaran di Beranda: nama + status, tanggal / tanggal kirim, alasan bila ditolak.
class KartuPendaftaranSaya extends StatelessWidget {
  const KartuPendaftaranSaya(this.p, {super.key});
  final Pendaftaran p;

  @override
  Widget build(BuildContext context) {
    return Kartu(
      onTap: () => bukaDetailPendaftaran(context, p.id),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Baris(
            kiri: Text(p.nama, style: const TextStyle(fontWeight: FontWeight.w700)),
            kanan: Tag.status(p.status),
          ),
          Text(
            p.status == StatusPendaftaran.dijadwalkan
                ? '${fmtPendek(p.tanggal!)} pukul ${p.jam}'
                : 'Dikirim ${fmtTglBln(p.dibuat)}',
            style: tsMut,
          ),
          if (p.status == StatusPendaftaran.ditolak && p.alasan != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(p.alasan!, style: const TextStyle(fontSize: 14, color: AppColors.red)),
            ),
        ],
      ),
    );
  }
}

void bukaDaftarBerobat(BuildContext context) =>
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const DaftarBerobatPage()));
