import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../data/repository.dart';
import '../../models/models.dart';
import '../../widgets/async_view.dart';
import '../../widgets/dialogs.dart';
import '../../widgets/kontak.dart';
import '../../widgets/media_preview.dart';
import '../../widgets/status_chip.dart';
import '../chat/chat_page.dart';

class PendaftarPage extends StatefulWidget {
  const PendaftarPage({super.key});

  @override
  State<PendaftarPage> createState() => _PendaftarPageState();
}

class _PendaftarPageState extends State<PendaftarPage> {
  StatusPendaftaran? _filter = StatusPendaftaran.menungguVerifikasi;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 56,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            children: [
              _chip(null, 'Semua'),
              for (final s in StatusPendaftaran.values) _chip(s, s.label),
            ],
          ),
        ),
        Expanded(
          child: AsyncView(
            key: ValueKey(_filter),
            load: (repo) => repo.semuaPendaftaran(status: _filter),
            builder: (context, list) {
              if (list.isEmpty) return const Center(child: Text('Tidak ada pendaftar.'));
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                itemCount: list.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final p = list[i];
                  return Card(
                    child: ListTile(
                      title: Text(p.nama, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text('${p.kode} • ${p.kota}\n${p.keluhan}', maxLines: 2, overflow: TextOverflow.ellipsis),
                      isThreeLine: true,
                      trailing: StatusChip(p.status),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(builder: (_) => DetailPendaftarPage(id: p.id)),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _chip(StatusPendaftaran? s, String label) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(
          label: Text(label),
          selected: _filter == s,
          onSelected: (_) => setState(() => _filter = s),
        ),
      );
}

class DetailPendaftarPage extends StatelessWidget {
  const DetailPendaftarPage({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detail Pendaftar')),
      body: AsyncView(
        load: (repo) => repo.pendaftaran(id),
        builder: (context, p) {
          if (p == null) return const Center(child: Text('Data tidak ditemukan.'));
          final repo = context.read<Repository>();
          final bisaDinilai = p.status == StatusPendaftaran.menungguVerifikasi ||
              p.status == StatusPendaftaran.perluDilengkapi;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  Expanded(child: Text(p.nama, style: Theme.of(context).textTheme.titleLarge)),
                  StatusChip(p.status),
                ],
              ),
              Text('${p.kode} • Didaftarkan ${fmtTanggalPendek(p.dibuat)}'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.chat),
                      label: const Text('WhatsApp'),
                      onPressed: () => bukaWhatsApp(context, p.noWa,
                          pesan: 'Assalamualaikum ${p.nama}, kami dari Padepokan Arul Sageni.'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.forum_outlined),
                      label: const Text('Chat'),
                      onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
                        builder: (_) => ChatScreen(pasienId: p.userId, namaPasien: p.nama),
                      )),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('WhatsApp: ${p.noWa}'),
                      Text('Kota: ${p.kota}'),
                      const SizedBox(height: 8),
                      const Text('Keluhan', style: TextStyle(fontWeight: FontWeight.w700)),
                      Text(p.keluhan),
                      if (p.catatanAdmin != null) ...[
                        const SizedBox(height: 8),
                        const Text('Catatan', style: TextStyle(fontWeight: FontWeight.w700)),
                        Text(p.catatanAdmin!),
                      ],
                      if (p.jadwal != null) ...[
                        const SizedBox(height: 8),
                        Text('Jadwal: ${fmtTanggal(p.jadwal!)} ${fmtJam(p.jadwal!)} • Antrean ${p.noAntrean}',
                            style: const TextStyle(fontWeight: FontWeight.w700)),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text('Foto / video kondisi', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              p.mediaKondisi.isEmpty
                  ? const Text('(Data contoh tanpa lampiran)', style: TextStyle(color: Colors.black45))
                  : Wrap(spacing: 8, runSpacing: 8, children: [for (final m in p.mediaKondisi) MediaThumb(m, size: 100)]),
              const SizedBox(height: 12),
              const Text('Foto KTP (NIK ditutup)', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              p.fotoKtp == null
                  ? const Text('Tidak dilampirkan', style: TextStyle(color: Colors.black45))
                  : Align(alignment: Alignment.centerLeft, child: MediaThumb(p.fotoKtp!, size: 140)),
              const SizedBox(height: 24),
              if (bisaDinilai || p.status == StatusPendaftaran.terjadwal)
                FilledButton.icon(
                  icon: const Icon(Icons.event_available),
                  label: Text(p.status == StatusPendaftaran.terjadwal ? 'Ubah Jadwal' : 'Jadwalkan & Kirim Notifikasi'),
                  onPressed: () async {
                    final waktu = await pilihJadwal(context, repo);
                    if (waktu != null && context.mounted) {
                      await jalankan(context, () => repo.jadwalkan(p.id, waktu),
                          sukses: 'Jadwal dikirim ke pasien.');
                    }
                  },
                ),
              if (bisaDinilai) ...[
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () async {
                    final c = await tanyaTeks(context, judul: 'Minta dilengkapi', label: 'Data apa yang kurang?');
                    if (c != null && context.mounted) {
                      await jalankan(context, () => repo.mintaLengkapi(p.id, c), sukses: 'Permintaan dikirim.');
                    }
                  },
                  child: const Text('Minta Dilengkapi'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
                  onPressed: () async {
                    final c = await tanyaTeks(context,
                        judul: 'Tidak dapat ditangani', label: 'Pesan untuk pasien', tombol: 'Tandai');
                    if (c != null && context.mounted) {
                      await jalankan(context, () => repo.tolak(p.id, c), sukses: 'Pasien telah diberi tahu.');
                    }
                  },
                  child: const Text('Tidak Dapat Ditangani'),
                ),
              ],
              if (p.status == StatusPendaftaran.terjadwal) ...[
                const SizedBox(height: 8),
                AksiJadwal(p: p),
              ],
            ],
          );
        },
      ),
    );
  }
}

/// Tombol Selesai / Tidak hadir / Ingatkan untuk janji terjadwal.
class AksiJadwal extends StatelessWidget {
  const AksiJadwal({super.key, required this.p});
  final Pendaftaran p;

  @override
  Widget build(BuildContext context) {
    final repo = context.read<Repository>();
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        OutlinedButton.icon(
          icon: const Icon(Icons.check),
          label: const Text('Selesai'),
          onPressed: () => jalankan(context, () => repo.tandaiSelesai(p.id), sukses: '${p.nama} ditandai selesai.'),
        ),
        OutlinedButton.icon(
          icon: const Icon(Icons.person_off_outlined),
          label: const Text('Tidak hadir'),
          onPressed: () => jalankan(context, () => repo.tandaiTidakHadir(p.id), sukses: '${p.nama} ditandai tidak hadir.'),
        ),
        OutlinedButton.icon(
          icon: const Icon(Icons.notifications_active_outlined),
          label: const Text('Ingatkan'),
          onPressed: () => jalankan(context, () => repo.kirimPengingat(p.id), sukses: 'Pengingat dikirim.'),
        ),
      ],
    );
  }
}
