import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../models/models.dart';
import '../../state/session.dart';
import '../../widgets/async_view.dart';
import '../../widgets/kontak.dart';

void tampilkanBiaya(BuildContext context, KlinikInfo klinik) {
  showModalBottomSheet<void>(
    context: context,
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Estimasi Biaya', style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: 12),
            for (final b in klinik.estimasiBiaya)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_circle, size: 18, color: AppColors.hijau),
                    const SizedBox(width: 8),
                    Expanded(child: Text(b)),
                  ],
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

IconData _ikonMedsos(String platform) => switch (platform.toLowerCase()) {
      'youtube' => Icons.smart_display,
      'facebook' => Icons.facebook,
      'instagram' => Icons.camera_alt,
      'tiktok' || 'snack video' => Icons.music_video,
      _ => Icons.link,
    };

class InfoPage extends StatelessWidget {
  const InfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<Session>();
    final user = session.user!;
    return AsyncView(
      load: (repo) => repo.klinik(),
      builder: (context, k) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  AspectRatio(
                    aspectRatio: 4 / 3,
                    child: Image.asset('assets/images/kang_arul.jpeg',
                        fit: BoxFit.cover, alignment: const Alignment(0, -0.6)),
                  ),
                  ListTile(
                    title: Text(k.pemilik, style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text(k.nama),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.place, color: AppColors.hijau),
                    title: const Text('Alamat'),
                    subtitle: Text(k.alamat),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.map),
                            label: const Text('Google Maps'),
                            onPressed: () => bukaUrl(context, k.mapsUrl),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
                            icon: const Icon(Icons.chat),
                            label: const Text('WA Admin'),
                            onPressed: () => bukaWhatsApp(context, k.waAdmin),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.phone, color: AppColors.hijau),
                    title: const Text('WhatsApp admin resmi'),
                    subtitle: Text(k.waAdmin),
                  ),
                  ListTile(
                    leading: const Icon(Icons.payments, color: AppColors.hijau),
                    title: const Text('Estimasi biaya'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => tampilkanBiaya(context, k),
                  ),
                  ListTile(
                    leading: const Icon(Icons.language, color: AppColors.hijau),
                    title: const Text('Website'),
                    subtitle: Text(k.website.replaceFirst('https://', '')),
                    onTap: () => bukaUrl(context, k.website),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 14, 16, 4),
                    child: Text('Media Sosial', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                  for (final m in k.mediaSosial)
                    ListTile(
                      leading: Icon(_ikonMedsos(m.platform), color: AppColors.hijau),
                      title: Text(m.nama),
                      subtitle: Text(m.platform),
                      trailing: const Icon(Icons.open_in_new, size: 18),
                      onTap: () => bukaUrl(context, m.url),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.person, color: AppColors.hijau),
                    title: Text(user.nama),
                    subtitle: Text(user.noWa),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Icon(Icons.logout, color: Theme.of(context).colorScheme.error),
                    title: Text('Keluar', style: TextStyle(color: Theme.of(context).colorScheme.error)),
                    onTap: session.logout,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
