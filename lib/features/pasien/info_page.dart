import 'package:flutter/material.dart';

import '../../core/klinik.dart';
import '../../core/theme.dart';
import '../../widgets/async_view.dart';
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

class InfoPage extends StatelessWidget {
  const InfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: headerApp('Info', aksi: const [TombolNotif()]),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Kartu(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.gold, width: 2),
                        image: const DecorationImage(
                          image: AssetImage(Klinik.foto),
                          fit: BoxFit.cover,
                          alignment: Alignment(0, -0.7),
                        ),
                      ),
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
                const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.place_outlined, size: 22),
                    SizedBox(width: 8),
                    Expanded(child: Text(Klinik.alamat)),
                  ],
                ),
                Tombol('Buka Google Maps', varian: Varian.garis, onPressed: () => bukaUrl(context, Klinik.maps)),
              ],
            ),
          ),
          Kartu(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const JudulKartu('Admin resmi'),
                const Text(Klinik.waAdmin),
                Tombol('Chat via WhatsApp',
                    varian: Varian.wa,
                    onPressed: () => bukaWhatsApp(context, Klinik.waAdmin, pesan: 'Halo admin ${Klinik.nama}')),
              ],
            ),
          ),
          Kartu(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const JudulKartu('Estimasi biaya'),
                for (final b in Klinik.biaya)
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
                const SizedBox(height: 4),
                const Text(Klinik.biayaAkhir, style: TextStyle(fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          Kartu(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const JudulKartu('Website'),
                BarisTautan(
                  ikon: Icons.language,
                  judul: 'pengobatankangarulsageni.com',
                  sub: 'Website resmi',
                  onTap: () => bukaUrl(context, Klinik.website),
                ),
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
}
