import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../data/repository.dart';
import '../../state/session.dart';
import '../../widgets/async_view.dart';
import '../../widgets/ui.dart';

class NotifikasiPage extends StatefulWidget {
  const NotifikasiPage({super.key});

  @override
  State<NotifikasiPage> createState() => _NotifikasiPageState();
}

class _NotifikasiPageState extends State<NotifikasiPage> {
  late final String _uid = context.read<Session>().user!.id;

  @override
  void initState() {
    super.initState();
    // Seperti demo: notifikasi dianggap dibaca saat halaman dibuka.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<Repository>().tandaiNotifikasiDibaca(_uid);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: headerApp('Notifikasi', kembali: true),
      body: AsyncView(
        load: (repo) => repo.notifikasi(_uid),
        builder: (context, list) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (list.isEmpty) const TeksKosong('Belum ada notifikasi.'),
            for (final n in list)
              Kartu(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(n.judul, style: const TextStyle(fontWeight: FontWeight.w700)),
                    Text(n.isi),
                    Text(fmtWaktu(n.waktu), style: tsCap),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
