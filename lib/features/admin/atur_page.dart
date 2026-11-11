import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../data/repository.dart';
import '../../models/models.dart';
import '../../widgets/async_view.dart';
import '../../widgets/dialogs.dart';

class AturPage extends StatelessWidget {
  const AturPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AsyncView(
      load: (repo) async => (await repo.klinik(), await repo.pengaturan()),
      builder: (context, data) {
        final (klinik, pengaturan) = data;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _InfoKlinikForm(klinik),
            const SizedBox(height: 16),
            _JadwalPraktik(pengaturan),
            const SizedBox(height: 16),
            _Periode(pengaturan),
            const SizedBox(height: 16),
            _TanggalKhusus(pengaturan),
          ],
        );
      },
    );
  }
}

class _Bagian extends StatelessWidget {
  const _Bagian({required this.judul, required this.children});
  final String judul;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(judul, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------------ info klinik

class _InfoKlinikForm extends StatefulWidget {
  const _InfoKlinikForm(this.klinik);
  final KlinikInfo klinik;

  @override
  State<_InfoKlinikForm> createState() => _InfoKlinikFormState();
}

class _InfoKlinikFormState extends State<_InfoKlinikForm> {
  late final _alamat = TextEditingController(text: widget.klinik.alamat);
  late final _maps = TextEditingController(text: widget.klinik.mapsUrl);
  late final _wa = TextEditingController(text: widget.klinik.waAdmin);
  late final _biaya = TextEditingController(text: widget.klinik.estimasiBiaya.join('\n'));

  @override
  void dispose() {
    for (final c in [_alamat, _maps, _wa, _biaya]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _Bagian(
      judul: 'Info Klinik',
      children: [
        TextField(controller: _alamat, maxLines: 2, decoration: const InputDecoration(labelText: 'Alamat lengkap')),
        const SizedBox(height: 10),
        TextField(controller: _maps, decoration: const InputDecoration(labelText: 'Link Google Maps')),
        const SizedBox(height: 10),
        TextField(
          controller: _wa,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(labelText: 'Nomor WhatsApp admin resmi'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _biaya,
          maxLines: 5,
          decoration: const InputDecoration(
            labelText: 'Estimasi biaya (satu poin per baris)',
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 6),
        const Text('Media sosial dikelola dari server (menyusul).', style: TextStyle(fontSize: 12, color: Colors.black54)),
        const SizedBox(height: 10),
        FilledButton(
          onPressed: () {
            final info = widget.klinik.copyWith(
              alamat: _alamat.text.trim(),
              mapsUrl: _maps.text.trim(),
              waAdmin: _wa.text.trim(),
              estimasiBiaya: _biaya.text.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
            );
            jalankan(context, () => context.read<Repository>().simpanKlinik(info), sukses: 'Info klinik disimpan.');
          },
          child: const Text('Simpan Info Klinik'),
        ),
      ],
    );
  }
}

// ------------------------------------------------------------ jadwal praktik

class _JadwalPraktik extends StatefulWidget {
  const _JadwalPraktik(this.p);
  final PengaturanJadwal p;

  @override
  State<_JadwalPraktik> createState() => _JadwalPraktikState();
}

class _JadwalPraktikState extends State<_JadwalPraktik> {
  late final _kuota = TextEditingController(text: '${widget.p.kuotaPerHari}');

  @override
  void dispose() {
    _kuota.dispose();
    super.dispose();
  }

  Future<void> _simpan(PengaturanJadwal baru, [String? pesan]) =>
      jalankan(context, () => context.read<Repository>().simpanPengaturan(baru), sukses: pesan);

  Future<void> _tambahSlot() async {
    final t = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 8, minute: 0));
    if (t == null || !mounted) return;
    final s = '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
    if (widget.p.slotJam.contains(s)) return;
    await _simpan(widget.p.copyWith(slotJam: [...widget.p.slotJam, s]..sort()));
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.p;
    return _Bagian(
      judul: 'Jadwal Praktik',
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _kuota,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Kuota pasien per hari'),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size(0, 52)),
              onPressed: () {
                final k = int.tryParse(_kuota.text);
                if (k == null || k < 1) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kuota harus angka ≥ 1.')));
                  return;
                }
                _simpan(p.copyWith(kuotaPerHari: k), 'Kuota disimpan.');
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
        const SizedBox(height: 14),
        const Text('Hari praktik'),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (var d = 1; d <= 7; d++)
              FilterChip(
                label: Text(namaHari[d - 1]),
                selected: p.hariPraktik.contains(d),
                onSelected: (on) {
                  final hari = {...p.hariPraktik};
                  on ? hari.add(d) : hari.remove(d);
                  _simpan(p.copyWith(hariPraktik: hari));
                },
              ),
          ],
        ),
        const SizedBox(height: 14),
        const Text('Pilihan jam janji'),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final s in p.slotJam)
              InputChip(
                label: Text(s),
                onDeleted: p.slotJam.length <= 1
                    ? null
                    : () => _simpan(p.copyWith(slotJam: p.slotJam.where((x) => x != s).toList())),
              ),
            ActionChip(avatar: const Icon(Icons.add, size: 18), label: const Text('Tambah'), onPressed: _tambahSlot),
          ],
        ),
      ],
    );
  }
}

// ------------------------------------------------------------ periode

class _Periode extends StatelessWidget {
  const _Periode(this.p);
  final PengaturanJadwal p;

  @override
  Widget build(BuildContext context) {
    final repo = context.read<Repository>();
    final sisaHari = tanggalSaja(p.periodeAkhir).difference(tanggalSaja(DateTime.now())).inDays;
    return _Bagian(
      judul: 'Periode Jadwal',
      children: [
        Text('Jadwal dibuka sampai ${fmtTanggal(p.periodeAkhir)}'),
        Text('Sisa $sisaHari hari', style: TextStyle(color: sisaHari < 60 ? Colors.orange.shade800 : Colors.black54)),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => jalankan(context, () => repo.perpanjangPeriode(1), sukses: 'Periode diperpanjang 1 tahun.'),
                child: const Text('+1 tahun'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: () => jalankan(context, () => repo.perpanjangPeriode(2), sukses: 'Periode diperpanjang 2 tahun.'),
                child: const Text('+2 tahun'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ------------------------------------------------------------ tanggal khusus

class _TanggalKhusus extends StatelessWidget {
  const _TanggalKhusus(this.p);
  final PengaturanJadwal p;

  Future<void> _tambah(BuildContext context) async {
    final repo = context.read<Repository>();
    final t = await showDatePicker(
      context: context,
      helpText: 'Pilih tanggal khusus',
      firstDate: tanggalSaja(DateTime.now()),
      lastDate: p.periodeAkhir,
    );
    if (t == null || !context.mounted) return;
    final kuotaTeks = await tanyaTeks(context,
        judul: fmtTanggal(t), label: 'Kuota hari itu (isi 0 untuk LIBUR)', tombol: 'Simpan');
    final kuota = int.tryParse(kuotaTeks ?? '');
    if (kuota == null || kuota < 0 || !context.mounted) return;
    await jalankan(context,
        () => repo.simpanPengaturan(p.copyWith(tanggalKhusus: {...p.tanggalKhusus, tanggalSaja(t): kuota})));
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.read<Repository>();
    final daftar = p.tanggalKhusus.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    return _Bagian(
      judul: 'Tanggal Khusus / Libur',
      children: [
        if (daftar.isEmpty) const Text('Belum ada tanggal khusus.', style: TextStyle(color: Colors.black54)),
        for (final e in daftar)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(e.value == 0 ? Icons.event_busy : Icons.event_note,
                color: e.value == 0 ? Colors.red : Colors.orange),
            title: Text(fmtTanggal(e.key)),
            subtitle: Text(e.value == 0 ? 'Libur' : 'Kuota ${e.value}'),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => jalankan(context,
                  () => repo.simpanPengaturan(p.copyWith(tanggalKhusus: {...p.tanggalKhusus}..remove(e.key)))),
            ),
          ),
        const SizedBox(height: 6),
        OutlinedButton.icon(
          icon: const Icon(Icons.add),
          label: const Text('Tambah tanggal khusus'),
          onPressed: () => _tambah(context),
        ),
      ],
    );
  }
}
