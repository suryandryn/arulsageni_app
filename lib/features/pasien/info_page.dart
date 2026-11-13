import 'package:flutter/material.dart';

import '../../core/klinik.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../widgets/async_view.dart';
import '../../widgets/gambar_klinik.dart';
import '../../widgets/kontak.dart';
import '../../widgets/ui.dart';
import 'pasien_shell.dart';

IconData ikonPlatform(String platform) => switch (platform) {
  'YouTube' => Icons.smart_display_outlined,
  'Facebook' => Icons.facebook_outlined,
  'Instagram' => Icons.camera_alt_outlined,
  'TikTok' => Icons.music_note_outlined,
  _ => Icons.play_circle_outline,
};

/// Menu Info pasien. Alamat, Maps, WA admin, biaya, dan website diatur admin
/// (panel web / aplikasi admin > Atur > Info klinik).
class InfoPage extends StatelessWidget {
  const InfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: headerApp('Info', aksi: const [TombolNotif()]),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AsyncView(
            load: (repo) => repo.infoKlinik(),
            builder: (context, info) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _kartuProfil(context, info),
                _kartuAdmin(context, info),
                _kartuBiaya(info),
                if (info.websiteUrl.isNotEmpty) _kartuWebsite(context, info),
              ],
            ),
          ),
          Kartu(
            child: AsyncView(
              load: (repo) => repo.mediaSosial(),
              builder: (context, list) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const JudulKartu('Media sosial'),
                  for (final s in list.where((s) => s.aktif))
                    BarisTautan(
                      ikon: ikonPlatform(s.platform),
                      judul: s.nama,
                      sub: s.platform,
                      onTap: () => bukaUrl(context, s.url),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _kartuProfil(BuildContext context, InfoKlinik info) => Kartu(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            GambarBulat(
              info.fotoUrl,
              ukuran: 64,
              bingkai: const BorderSide(color: AppColors.gold, width: 2),
              bayangan: false,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(Klinik.nama, style: lora(18)),
                  const Text(Klinik.pemilik, style: tsMut),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.place_outlined, size: 22),
            const SizedBox(width: 8),
            Expanded(child: Text(info.alamat)),
          ],
        ),
        Tombol('Buka Google Maps', varian: Varian.garis, onPressed: () => bukaUrl(context, info.mapsUrl)),
      ],
    ),
  );

  Widget _kartuAdmin(BuildContext context, InfoKlinik info) => Kartu(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const JudulKartu('Admin resmi'),
        Text(info.waAdmin),
        Tombol(
          'Chat via WhatsApp',
          varian: Varian.wa,
          onPressed: () => bukaWhatsApp(context, info.waAdmin, pesan: 'Halo admin ${Klinik.nama}'),
        ),
      ],
    ),
  );

  Widget _kartuBiaya(InfoKlinik info) => Kartu(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const JudulKartu('Estimasi biaya'),
        for (final b in info.poinBiaya)
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('•  '),
                Expanded(child: Text(b)),
              ],
            ),
          ),
        if (info.biayaCatatan.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(info.biayaCatatan, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ],
    ),
  );

  Widget _kartuWebsite(BuildContext context, InfoKlinik info) => Kartu(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const JudulKartu('Website'),
        BarisTautan(
          ikon: Icons.language,
          judul: info.websiteNama,
          sub: info.websiteKeterangan.isEmpty ? 'Website' : info.websiteKeterangan,
          onTap: () => bukaUrl(context, info.websiteUrl),
        ),
      ],
    ),
  );
}
