import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/config.dart';
import '../../state/session.dart';
import '../../widgets/async_view.dart';
import '../chat/chat_page.dart';
import 'beranda_page.dart';
import 'info_page.dart';
import 'janji_page.dart';
import 'notifikasi_page.dart';

class PasienShell extends StatefulWidget {
  const PasienShell({super.key});

  @override
  State<PasienShell> createState() => _PasienShellState();
}

class _PasienShellState extends State<PasienShell> {
  int _tab = 0;

  void pindahTab(int i) => setState(() => _tab = i);

  @override
  Widget build(BuildContext context) {
    final user = context.watch<Session>().user!;
    final judul = ['Beranda', 'Janji Saya', 'Chat Admin', 'Info'][_tab];
    return Scaffold(
      appBar: AppBar(
        title: Text(_tab == 0 ? AppConfig.namaAplikasi : judul),
        actions: [
          AsyncView(
            load: (repo) => repo.notifikasi(user.id),
            builder: (context, list) {
              final belum = list.where((n) => !n.dibaca).length;
              return IconButton(
                tooltip: 'Notifikasi',
                icon: Badge(
                  isLabelVisible: belum > 0,
                  label: Text('$belum'),
                  child: const Icon(Icons.notifications_outlined),
                ),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const NotifikasiPage()),
                ),
              );
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _tab,
        children: [
          BerandaPage(keJanji: () => pindahTab(1)),
          const JanjiPage(),
          ChatPage(pasienId: user.id, sebagaiAdmin: false),
          const InfoPage(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: pindahTab,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Beranda'),
          NavigationDestination(icon: Icon(Icons.event_note_outlined), selectedIcon: Icon(Icons.event_note), label: 'Janji'),
          NavigationDestination(icon: Icon(Icons.chat_bubble_outline), selectedIcon: Icon(Icons.chat_bubble), label: 'Chat'),
          NavigationDestination(icon: Icon(Icons.info_outline), selectedIcon: Icon(Icons.info), label: 'Info'),
        ],
      ),
    );
  }
}
