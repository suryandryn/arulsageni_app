import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../widgets/async_view.dart';
import '../../widgets/kontak.dart';
import '../../widgets/ui.dart';
import '../chat/chat_view.dart';

class ChatAdminPage extends StatelessWidget {
  const ChatAdminPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: headerApp('Chat Pasien'),
      body: AsyncView(
        load: (repo) => repo.percakapan(),
        builder: (context, list) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (list.isEmpty) const TeksKosong('Belum ada chat.'),
            for (final c in list)
              Kartu(
                onTap: () => bukaChatAdmin(context, c.pasien.id),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Baris(
                      kiri: Text(c.pasien.nama, style: const TextStyle(fontWeight: FontWeight.w700)),
                      kanan: c.belumDibaca > 0
                          ? Tag('${c.belumDibaca} baru', bg: const Color(0xFFF6ECD6), fg: AppColors.wtx)
                          : Text(fmtWaktu(c.terakhir.waktu), style: tsCap),
                    ),
                    Text(
                      '${c.terakhir.dariAdmin ? 'Anda: ' : ''}${c.terakhir.isi}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: tsMut,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

void bukaChatAdmin(BuildContext context, String pasienId) => Navigator.of(context)
    .push(MaterialPageRoute<void>(builder: (_) => ChatAdminRoomPage(pasienId: pasienId)));

/// Ruang chat admin dengan satu akun pasien.
class ChatAdminRoomPage extends StatelessWidget {
  const ChatAdminRoomPage({super.key, required this.pasienId});
  final String pasienId;

  @override
  Widget build(BuildContext context) {
    return AsyncView(
      load: (repo) async => (await repo.akunPasien()).where((u) => u.id == pasienId).firstOrNull,
      builder: (context, u) => Scaffold(
        appBar: headerApp(
          u?.nama ?? 'Chat',
          kembali: true,
          aksi: [
            if (u != null)
              TombolHeader('WhatsApp', onTap: () => bukaWhatsApp(context, u.noHp, pesan: 'Halo ${u.nama}')),
          ],
        ),
        body: ChatView(pasienId: pasienId, sebagaiAdmin: true),
      ),
    );
  }
}
