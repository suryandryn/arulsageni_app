import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../data/repository.dart';
import '../../state/session.dart';
import '../../widgets/async_view.dart';

class NotifikasiPage extends StatefulWidget {
  const NotifikasiPage({super.key});

  @override
  State<NotifikasiPage> createState() => _NotifikasiPageState();
}

class _NotifikasiPageState extends State<NotifikasiPage> {
  late final Repository _repo;
  late final String _userId;

  @override
  void initState() {
    super.initState();
    _repo = context.read<Repository>();
    _userId = context.read<Session>().user!.id;
  }

  @override
  void dispose() {
    // Tandai dibaca saat halaman ditutup agar penanda "baru" masih terlihat.
    _repo.tandaiNotifikasiDibaca(_userId);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifikasi')),
      body: AsyncView(
        load: (repo) => repo.notifikasi(_userId),
        builder: (context, list) {
          if (list.isEmpty) return const Center(child: Text('Belum ada notifikasi.'));
          return ListView.separated(
            itemCount: list.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final n = list[i];
              return Container(
                color: n.dibaca ? null : AppColors.hijauMuda,
                child: ListTile(
                  leading: const Icon(Icons.notifications, color: AppColors.hijau),
                  title: Text(n.judul, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('${n.isi}\n${fmtWaktu(n.waktu)}'),
                  isThreeLine: true,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
