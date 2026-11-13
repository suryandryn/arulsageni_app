import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/repository.dart';
import '../../models/models.dart';
import '../../widgets/async_view.dart';
import '../../widgets/penyegar.dart';
import '../../widgets/ui.dart';
import 'atur_page.dart';
import 'beranda_admin_page.dart';
import 'chat_admin_page.dart';
import 'jadwal_admin_page.dart';
import 'pendaftaran_admin_page.dart';

/// Tab aktif admin: 0 Beranda, 1 Pendaftaran, 2 Jadwal, 3 Chat, 4 Atur.
final tabAdmin = ValueNotifier<int>(0);

/// Filter status di tab Pendaftaran (null = Semua); diatur dari Beranda.
final filterPendaftaranAdmin = ValueNotifier<StatusPendaftaran?>(null);

/// Filter "Pengajuan pasien" di tab Pendaftaran (status diabaikan bila `true`).
final filterPengajuanAdmin = ValueNotifier<bool>(false);

/// Kata pencarian di tab Pendaftaran; diatur dari Data Pasien (jumlah pendaftaran).
final cariPendaftaranAdmin = ValueNotifier<String>('');

/// Tanggal terpilih di tab Jadwal; diatur dari Beranda.
final tanggalJadwalAdmin = ValueNotifier<DateTime?>(null);

void bukaTabAdmin(BuildContext context, int i) {
  Navigator.of(context).popUntil((r) => r.isFirst);
  tabAdmin.value = i;
}

void bukaPendaftaranAdmin(BuildContext context, StatusPendaftaran? status, {bool pengajuan = false, String? cari}) {
  filterPengajuanAdmin.value = pengajuan;
  filterPendaftaranAdmin.value = pengajuan ? null : status;
  if (cari != null) cariPendaftaranAdmin.value = cari;
  bukaTabAdmin(context, 1);
}

void bukaJadwalAdmin(BuildContext context, DateTime? tanggal) {
  if (tanggal != null) tanggalJadwalAdmin.value = tanggal;
  bukaTabAdmin(context, 2);
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
    filterPendaftaranAdmin.value = null;
    filterPengajuanAdmin.value = false;
    tanggalJadwalAdmin.value = null;
  }

  void _pindahTab(int i) {
    // Data bisa berubah dari panel web: segarkan setiap pindah tab.
    if (i != tabAdmin.value) context.read<Repository>().segarkan();
    tabAdmin.value = i;
  }

  @override
  Widget build(BuildContext context) {
    return Penyegar(
      child: ValueListenableBuilder<int>(
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
              onTap: _pindahTab,
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
      ),
    );
  }
}
