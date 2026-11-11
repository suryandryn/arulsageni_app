import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../data/repository.dart';
import '../../models/models.dart';
import '../../state/session.dart';
import '../../widgets/async_view.dart';
import '../../widgets/dialogs.dart';
import '../../widgets/status_chip.dart';
import 'daftar_berobat_page.dart';

class JanjiPage extends StatelessWidget {
  const JanjiPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<Session>().user!;
    return AsyncView(
      load: (repo) => repo.pendaftaranSaya(user.id),
      builder: (context, list) {
        if (list.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Belum ada pendaftaran.'),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: (_) => const DaftarBerobatPage()),
                    ),
                    child: const Text('Daftar Berobat'),
                  ),
                ],
              ),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: list.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, i) {
            final p = list[i];
            return Card(
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                title: Text(p.kode, style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(
                  p.jadwal != null
                      ? '${fmtTanggalPendek(p.jadwal!)} • ${fmtJam(p.jadwal!)} • Antrean ${p.noAntrean}'
                      : 'Didaftarkan ${fmtTanggalPendek(p.dibuat)}',
                ),
                trailing: StatusChip(p.status),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => DetailJanjiPage(id: p.id)),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class DetailJanjiPage extends StatelessWidget {
  const DetailJanjiPage({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detail Janji')),
      body: AsyncView(
        load: (repo) => repo.pendaftaran(id),
        builder: (context, p) {
          if (p == null) return const Center(child: Text('Data tidak ditemukan.'));
          final repo = context.read<Repository>();
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  Expanded(child: Text(p.kode, style: Theme.of(context).textTheme.titleLarge)),
                  StatusChip(p.status),
                ],
              ),
              const SizedBox(height: 16),
              if (p.jadwal != null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Baris('Tanggal', fmtTanggal(p.jadwal!)),
                        _Baris('Jam', fmtJam(p.jadwal!)),
                        _Baris('No. antrean', '${p.noAntrean}'),
                        if (p.status == StatusPendaftaran.terjadwal) _Baris('Hitung mundur', hitungMundur(p.jadwal!)),
                      ],
                    ),
                  ),
                ),
              if (p.catatanAdmin != null) ...[
                const SizedBox(height: 12),
                Card(
                  color: const Color(0xFFFFF4DB),
                  child: ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: const Text('Catatan'),
                    subtitle: Text(p.catatanAdmin!),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Baris('Nama', p.nama),
                      _Baris('WhatsApp', p.noWa),
                      _Baris('Kota', p.kota),
                      _Baris('Keluhan', p.keluhan),
                      _Baris('Lampiran', '${p.mediaKondisi.length} foto/video${p.fotoKtp != null ? ' + KTP' : ''}'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              if (p.status == StatusPendaftaran.perluDilengkapi)
                FilledButton(
                  onPressed: () async {
                    final ket = await tanyaTeks(context,
                        judul: 'Lengkapi data', label: 'Keterangan tambahan / jawaban untuk admin');
                    if (ket != null && context.mounted) {
                      await jalankan(context, () => repo.lengkapiData(p.id, ket), sukses: 'Data dikirim ke admin.');
                    }
                  },
                  child: const Text('Lengkapi Data'),
                ),
              if (p.status == StatusPendaftaran.terjadwal) ...[
                OutlinedButton(
                  onPressed: () async {
                    final alasan = await tanyaTeks(context,
                        judul: 'Ajukan jadwal ulang', label: 'Alasan / tanggal yang diinginkan');
                    if (alasan != null && context.mounted) {
                      await jalankan(context, () => repo.ajukanJadwalUlang(p.id, alasan),
                          sukses: 'Pengajuan jadwal ulang terkirim.');
                    }
                  },
                  child: const Text('Ajukan Jadwal Ulang'),
                ),
                const SizedBox(height: 8),
              ],
              if (p.status == StatusPendaftaran.terjadwal || p.status == StatusPendaftaran.menungguVerifikasi)
                TextButton(
                  style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
                  onPressed: () async {
                    if (await konfirmasi(context, 'Batalkan janji?', 'Janji ${p.kode} akan dibatalkan.') &&
                        context.mounted) {
                      await jalankan(context, () => repo.batalkan(p.id), sukses: 'Janji dibatalkan.');
                    }
                  },
                  child: const Text('Batalkan Janji'),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _Baris extends StatelessWidget {
  const _Baris(this.label, this.nilai);
  final String label;
  final String nilai;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 110, child: Text(label, style: const TextStyle(color: Colors.black54))),
          Expanded(child: Text(nilai, style: const TextStyle(fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}
