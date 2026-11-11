import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../widgets/async_view.dart';
import '../chat/chat_page.dart';

class RingkasPage extends StatelessWidget {
  const RingkasPage({super.key, required this.keTab});

  final ValueChanged<int> keTab;

  @override
  Widget build(BuildContext context) {
    return AsyncView(
      load: (repo) => repo.ringkas(),
      builder: (context, r) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                Expanded(child: _Stat(label: 'Menunggu verifikasi', nilai: r.menunggu, ikon: Icons.hourglass_top, onTap: () => keTab(1))),
                const SizedBox(width: 12),
                Expanded(child: _Stat(label: 'Jadwal besok', nilai: r.jadwalBesok, ikon: Icons.event, onTap: () => keTab(2))),
              ],
            ),
            const SizedBox(height: 12),
            _Stat(label: 'Total pasien terdaftar', nilai: r.totalTerdaftar, ikon: Icons.people),
            const SizedBox(height: 20),
            Text('Chat pasien terbaru', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (r.chatTerbaru.isEmpty)
              const Card(child: ListTile(title: Text('Belum ada chat.')))
            else
              Card(
                child: Column(
                  children: [
                    for (final c in r.chatTerbaru)
                      ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.hijauMuda,
                          child: Text(c.pasien.nama[0], style: const TextStyle(color: AppColors.hijau)),
                        ),
                        title: Text(c.pasien.nama),
                        subtitle: Text(
                          '${c.terakhir.dariAdmin ? 'Anda: ' : ''}${c.terakhir.isi}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Text(fmtWaktu(c.terakhir.waktu), style: const TextStyle(fontSize: 11)),
                        onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                          builder: (_) => ChatScreen(pasienId: c.pasien.id, namaPasien: c.pasien.nama),
                        )),
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

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.nilai, required this.ikon, this.onTap});
  final String label;
  final int nilai;
  final IconData ikon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(ikon, color: AppColors.hijau),
              const SizedBox(height: 8),
              Text('$nilai', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700)),
              Text(label, style: const TextStyle(color: Colors.black54)),
            ],
          ),
        ),
      ),
    );
  }
}
