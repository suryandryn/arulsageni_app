import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../models/models.dart';
import '../../widgets/async_view.dart';
import '../../widgets/kontak.dart';
import '../../widgets/status_chip.dart';
import '../chat/chat_page.dart';
import 'pendaftar_page.dart';

class JadwalPage extends StatefulWidget {
  const JadwalPage({super.key});

  @override
  State<JadwalPage> createState() => _JadwalPageState();
}

class _JadwalPageState extends State<JadwalPage> {
  DateTime _tanggal = tanggalSaja(DateTime.now());

  void _geser(int hari) =>
      setState(() => _tanggal = DateTime(_tanggal.year, _tanggal.month, _tanggal.day + hari));

  Future<void> _pilih() async {
    final t = await showDatePicker(
      context: context,
      initialDate: _tanggal,
      firstDate: DateTime(2024),
      lastDate: DateTime(DateTime.now().year + 5),
    );
    if (t != null) setState(() => _tanggal = tanggalSaja(t));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: Colors.white,
          child: Row(
            children: [
              IconButton(onPressed: () => _geser(-1), icon: const Icon(Icons.chevron_left)),
              Expanded(
                child: TextButton.icon(
                  onPressed: _pilih,
                  icon: const Icon(Icons.calendar_today, size: 18),
                  label: Text(fmtTanggal(_tanggal)),
                ),
              ),
              IconButton(onPressed: () => _geser(1), icon: const Icon(Icons.chevron_right)),
            ],
          ),
        ),
        Expanded(
          child: AsyncView(
            key: ValueKey(_tanggal),
            load: (repo) async => (await repo.jadwalPada(_tanggal), await repo.kuotaPada(_tanggal)),
            builder: (context, data) {
              final (list, kuota) = data;
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.groups),
                      title: Text(kuota == 0 ? 'Tutup / libur' : 'Kuota terisi ${list.length} / $kuota'),
                      subtitle: kuota == 0
                          ? null
                          : LinearProgressIndicator(value: (list.length / kuota).clamp(0, 1).toDouble()),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (list.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: Text('Belum ada pasien terjadwal.')),
                    ),
                  for (final p in list) ...[
                    _KartuPasien(p),
                    const SizedBox(height: 8),
                  ],
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _KartuPasien extends StatelessWidget {
  const _KartuPasien(this.p);
  final Pendaftaran p;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(radius: 16, child: Text('${p.noAntrean}')),
                const SizedBox(width: 10),
                Expanded(
                  child: InkWell(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: (_) => DetailPendaftarPage(id: p.id)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.nama, style: const TextStyle(fontWeight: FontWeight.w700)),
                        Text('${fmtJam(p.jadwal!)} • ${p.kota}'),
                      ],
                    ),
                  ),
                ),
                StatusChip(p.status),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.chat, size: 18),
                  label: const Text('WhatsApp'),
                  onPressed: () => bukaWhatsApp(context, p.noWa,
                      pesan: 'Assalamualaikum ${p.nama}, mengingatkan jadwal berobat Anda '
                          '${fmtTanggal(p.jadwal!)} pukul ${fmtJam(p.jadwal!)}, antrean no. ${p.noAntrean}.'),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.forum_outlined, size: 18),
                  label: const Text('Chat'),
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
                    builder: (_) => ChatScreen(pasienId: p.userId, namaPasien: p.nama),
                  )),
                ),
              ],
            ),
            if (p.status == StatusPendaftaran.terjadwal) AksiJadwal(p: p),
          ],
        ),
      ),
    );
  }
}
