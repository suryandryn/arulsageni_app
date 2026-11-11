import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../models/models.dart';
import '../../state/session.dart';
import '../../widgets/async_view.dart';
import '../../widgets/jadwal_card.dart';
import '../../widgets/media.dart';
import '../../widgets/ui.dart';
import 'beranda_page.dart';
import 'pasien_shell.dart';

/// Tab "Daftar": semua pendaftaran milik akun ini.
class PendaftaranPage extends StatelessWidget {
  const PendaftaranPage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = context.watch<Session>().user!.id;
    return Scaffold(
      appBar: headerApp('Pendaftaran', aksi: const [TombolNotif()]),
      body: AsyncView(
        load: (repo) => repo.pendaftaranSaya(uid),
        builder: (context, list) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Tombol('Daftar Berobat Baru', atas: 0, onPressed: () => bukaDaftarBerobat(context)),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('Satu akun bisa mendaftarkan lebih dari satu pasien, misalnya anggota keluarga.',
                  style: tsCap),
            ),
            for (final p in list)
              Kartu(
                onTap: () => bukaDetailPendaftaran(context, p.id),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Baris(
                      kiri: Text(p.nama, style: const TextStyle(fontWeight: FontWeight.w700)),
                      kanan: Tag.status(p.status),
                    ),
                    Text(p.keluhan, style: tsMut),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

void bukaDetailPendaftaran(BuildContext context, String id) => Navigator.of(context)
    .push(MaterialPageRoute<void>(builder: (_) => DetailPendaftaranPage(id: id)));

class DetailPendaftaranPage extends StatelessWidget {
  const DetailPendaftaranPage({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: headerApp('Detail Pendaftaran', aksi: [TombolHeader('Kembali', onTap: () => Navigator.pop(context))]),
      body: AsyncView(
        load: (repo) => repo.pendaftaran(id),
        builder: (context, p) {
          if (p == null) return const Center(child: Text('Data tidak ditemukan.'));
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (p.status == StatusPendaftaran.dijadwalkan) KartuJadwal(p),
              Kartu(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Baris(
                      kiri: Text('${p.nama}, ${p.umur} th', style: const TextStyle(fontWeight: FontWeight.w700)),
                      kanan: Tag.status(p.status),
                    ),
                    Padding(padding: const EdgeInsets.only(top: 6), child: Text(p.keluhan, style: tsMut)),
                    if (p.status == StatusPendaftaran.ditolak && p.alasan != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text.rich(
                          TextSpan(children: [
                            const TextSpan(text: 'Alasan: ', style: TextStyle(fontWeight: FontWeight.w700)),
                            TextSpan(text: p.alasan),
                          ]),
                          style: const TextStyle(color: AppColors.red),
                        ),
                      ),
                    const Padding(padding: EdgeInsets.only(top: 10), child: Text('Foto/video kondisi', style: tsCap)),
                    GridMedia(berkas: p.mediaKondisi),
                  ],
                ),
              ),
              Tombol('Tanya admin lewat chat',
                  atas: 0, varian: Varian.garis, onPressed: () => bukaTabPasien(context, 2)),
            ],
          );
        },
      ),
    );
  }
}
