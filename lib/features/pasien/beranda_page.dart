import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../state/session.dart';
import '../../widgets/async_view.dart';
import '../../widgets/kontak.dart';
import '../../widgets/status_chip.dart';
import 'daftar_berobat_page.dart';
import 'info_page.dart';

class BerandaPage extends StatelessWidget {
  const BerandaPage({super.key, required this.keJanji});

  final VoidCallback keJanji;

  @override
  Widget build(BuildContext context) {
    final user = context.watch<Session>().user!;
    return AsyncView(
      load: (repo) async => (await repo.pendaftaranSaya(user.id), await repo.klinik()),
      builder: (context, data) {
        final (daftar, klinik) = data;
        final terdekat = daftar
            .where((p) => p.status == StatusPendaftaran.terjadwal && p.jadwal != null)
            .toList()
          ..sort((a, b) => a.jadwal!.compareTo(b.jadwal!));
        final proses = daftar.where((p) =>
            p.status == StatusPendaftaran.menungguVerifikasi || p.status == StatusPendaftaran.perluDilengkapi);

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Halo, ${user.nama.split(' ').first} 👋',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            if (terdekat.isNotEmpty)
              _KartuJanji(terdekat.first, onTap: keJanji)
            else
              const _KartuKosong(),
            if (proses.isNotEmpty) ...[
              const SizedBox(height: 12),
              for (final p in proses)
                Card(
                  child: ListTile(
                    title: Text(p.kode),
                    subtitle: Text(p.catatanAdmin ?? 'Sedang diperiksa admin.'),
                    trailing: StatusChip(p.status),
                    onTap: keJanji,
                  ),
                ),
            ],
            const SizedBox(height: 16),
            FilledButton.icon(
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('Daftar Berobat'),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const DaftarBerobatPage()),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _Pintasan(
                    ikon: Icons.place_outlined,
                    label: 'Alamat & Maps',
                    onTap: () => bukaUrl(context, klinik.mapsUrl),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _Pintasan(
                    ikon: Icons.payments_outlined,
                    label: 'Estimasi Biaya',
                    onTap: () => tampilkanBiaya(context, klinik),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _KartuJanji extends StatefulWidget {
  const _KartuJanji(this.p, {required this.onTap});
  final Pendaftaran p;
  final VoidCallback onTap;

  @override
  State<_KartuJanji> createState() => _KartuJanjiState();
}

class _KartuJanjiState extends State<_KartuJanji> {
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.p;
    const putih = TextStyle(color: Colors.white);
    return InkWell(
      onTap: widget.onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [AppColors.hijau, AppColors.hijauTua]),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Janji berobat terdekat', style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 6),
            Text(fmtTanggal(p.jadwal!),
                style: putih.copyWith(fontSize: 18, fontWeight: FontWeight.w700)),
            Text('Pukul ${fmtJam(p.jadwal!)}  •  Antrean no. ${p.noAntrean}', style: putih),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(20)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.timer_outlined, color: Colors.white, size: 16),
                  const SizedBox(width: 6),
                  Text(hitungMundur(p.jadwal!), style: putih.copyWith(fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text('Kode janji: ${p.kode}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _KartuKosong extends StatelessWidget {
  const _KartuKosong();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.event_available_outlined, color: AppColors.hijau, size: 36),
            SizedBox(width: 12),
            Expanded(child: Text('Belum ada jadwal berobat. Tekan "Daftar Berobat" untuk mendaftar.')),
          ],
        ),
      ),
    );
  }
}

class _Pintasan extends StatelessWidget {
  const _Pintasan({required this.ikon, required this.label, required this.onTap});
  final IconData ikon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 18),
          child: Column(
            children: [
              Icon(ikon, color: AppColors.hijau, size: 28),
              const SizedBox(height: 6),
              Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}
