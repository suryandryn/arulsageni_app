import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../widgets/async_view.dart';
import '../../widgets/ui.dart';
import 'admin_shell.dart';

class BerandaAdminPage extends StatelessWidget {
  const BerandaAdminPage({super.key});

  @override
  Widget build(BuildContext context) {
    TextStyle angka() => lora(30, weight: FontWeight.w700);
    return Scaffold(
      appBar: headerApp('Beranda Admin'),
      body: AsyncView(
        load: (repo) => repo.ringkas(),
        builder: (context, r) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Kartu(
              child: Baris(
                kiri: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Pendaftaran menunggu', style: tsMut),
                    Text('${r.menunggu}', style: angka()),
                  ],
                ),
                kanan: Tombol('Tinjau', kecil: true, onPressed: () => tabAdmin.value = 1),
              ),
            ),
            Kartu(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Jadwal ${fmtHariTanggalPendek(r.hariBerikut)}', style: tsMut),
                  Text.rich(TextSpan(children: [
                    TextSpan(text: '${r.jadwalHariBerikut}', style: angka()),
                    const TextSpan(text: ' pasien', style: tsMut),
                  ])),
                ],
              ),
            ),
            Kartu(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Sisa kuota 30 hari ke depan', style: tsMut),
                  Text('${r.sisaKuota30Hari}', style: angka()),
                ],
              ),
            ),
            Kartu(
              child: Baris(
                kiri: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Chat belum dibaca', style: tsMut),
                    Text('${r.chatBelumDibaca}', style: angka()),
                  ],
                ),
                kanan: Tombol('Buka', kecil: true, varian: Varian.garis, onPressed: () => tabAdmin.value = 3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
