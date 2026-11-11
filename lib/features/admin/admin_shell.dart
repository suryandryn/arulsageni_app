import 'package:flutter/material.dart';

import '../../widgets/async_view.dart';
import '../../widgets/ui.dart';
import 'atur_page.dart';
import 'beranda_admin_page.dart';
import 'chat_admin_page.dart';
import 'jadwal_admin_page.dart';
import 'pendaftaran_admin_page.dart';

/// Tab aktif admin: 0 Beranda, 1 Pendaftaran, 2 Jadwal, 3 Chat, 4 Atur.
final tabAdmin = ValueNotifier<int>(0);

void bukaTabAdmin(BuildContext context, int i) {
  Navigator.of(context).popUntil((r) => r.isFirst);
  tabAdmin.value = i;
}

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  @override
  void initState() {
    super.initState();
    tabAdmin.value = 0;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: tabAdmin,
      builder: (context, tab, _) => Scaffold(
        body: IndexedStack(
          index: tab,
          children: const [
            BerandaAdminPage(),
            PendaftaranAdminPage(),
            JadwalAdminPage(),
            ChatAdminPage(),
            AturPage(),
          ],
        ),
        bottomNavigationBar: AsyncView(
          load: (repo) => repo.chatBelumDibaca(olehAdmin: true),
          builder: (context, chatBaru) => NavBawah(
            index: tab,
            onTap: (i) => tabAdmin.value = i,
            items: [
              const ItemNav('Beranda', Icons.home_outlined),
              const ItemNav('Pendaftaran', Icons.format_list_bulleted),
              const ItemNav('Jadwal', Icons.calendar_today_outlined),
              ItemNav('Chat', Icons.chat_bubble_outline, badge: chatBaru),
              const ItemNav('Atur', Icons.settings_outlined),
            ],
          ),
        ),
      ),
    );
  }
}
