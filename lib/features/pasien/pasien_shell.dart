import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/session.dart';
import '../../widgets/async_view.dart';
import '../../widgets/ui.dart';
import '../chat/chat_view.dart';
import 'beranda_page.dart';
import 'info_page.dart';
import 'notifikasi_page.dart';
import 'pendaftaran_page.dart';
import 'profil_page.dart';

/// Tab aktif pasien: 0 Beranda, 1 Daftar, 2 Chat, 3 Info, 4 Profil.
/// Dipakai juga oleh halaman lain untuk berpindah tab.
final tabPasien = ValueNotifier<int>(0);

/// Kembali ke layar utama lalu buka tab [i].
void bukaTabPasien(BuildContext context, int i) {
  Navigator.of(context).popUntil((r) => r.isFirst);
  tabPasien.value = i;
}

class PasienShell extends StatefulWidget {
  const PasienShell({super.key});

  @override
  State<PasienShell> createState() => _PasienShellState();
}

class _PasienShellState extends State<PasienShell> {
  @override
  void initState() {
    super.initState();
    tabPasien.value = 0;
  }

  @override
  Widget build(BuildContext context) {
    final uid = context.watch<Session>().user!.id;
    return ValueListenableBuilder<int>(
      valueListenable: tabPasien,
      builder: (context, tab, _) => Scaffold(
        body: IndexedStack(
          index: tab,
          children: [
            const BerandaPage(),
            const PendaftaranPage(),
            Scaffold(
              appBar: headerApp('Chat Admin', aksi: const [TombolNotif()]),
              body: ChatView(pasienId: uid, sebagaiAdmin: false, terlihat: tab == 2),
            ),
            const InfoPage(),
            const ProfilPage(),
          ],
        ),
        bottomNavigationBar: AsyncView(
          load: (repo) => repo.chatBelumDibaca(olehAdmin: false, pasienId: uid),
          builder: (context, chatBaru) => NavBawah(
            index: tab,
            onTap: (i) => tabPasien.value = i,
            items: [
              const ItemNav('Beranda', Icons.home_outlined),
              const ItemNav('Daftar', Icons.assignment_outlined),
              ItemNav('Chat', Icons.chat_bubble_outline, badge: chatBaru),
              const ItemNav('Info', Icons.info_outline),
              const ItemNav('Profil', Icons.person_outline),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tombol "Notif" di header; hanya tampil bila ada notifikasi belum dibaca.
class TombolNotif extends StatelessWidget {
  const TombolNotif({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = context.watch<Session>().user?.id;
    if (uid == null) return const SizedBox.shrink();
    return AsyncView(
      load: (repo) => repo.notifikasiBelumDibaca(uid),
      builder: (context, n) => n == 0
          ? const SizedBox.shrink()
          : TombolHeader('Notif', badge: n, onTap: () => bukaNotifikasi(context)),
    );
  }
}

void bukaNotifikasi(BuildContext context) =>
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const NotifikasiPage()));
