import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/session.dart';
import 'atur_page.dart';
import 'jadwal_page.dart';
import 'pendaftar_page.dart';
import 'ringkas_page.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    const judul = ['Ringkas', 'Pendaftar', 'Jadwal', 'Atur'];
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin • ${judul[_tab]}'),
        actions: [
          IconButton(
            tooltip: 'Keluar',
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<Session>().logout(),
          ),
        ],
      ),
      body: IndexedStack(
        index: _tab,
        children: [
          RingkasPage(keTab: (i) => setState(() => _tab = i)),
          const PendaftarPage(),
          const JadwalPage(),
          const AturPage(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Ringkas'),
          NavigationDestination(icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people), label: 'Pendaftar'),
          NavigationDestination(icon: Icon(Icons.calendar_month_outlined), selectedIcon: Icon(Icons.calendar_month), label: 'Jadwal'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: 'Atur'),
        ],
      ),
    );
  }
}
