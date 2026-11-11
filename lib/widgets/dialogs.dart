import 'package:flutter/material.dart';

import '../core/format.dart';
import '../data/repository.dart';

/// Dialog isian teks. Mengembalikan teks atau null bila dibatalkan.
Future<String?> tanyaTeks(
  BuildContext context, {
  required String judul,
  required String label,
  String tombol = 'Kirim',
}) {
  final c = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(judul),
      content: TextField(
        controller: c,
        autofocus: true,
        maxLines: 3,
        decoration: InputDecoration(labelText: label),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
          onPressed: () {
            if (c.text.trim().isNotEmpty) Navigator.pop(ctx, c.text.trim());
          },
          child: Text(tombol),
        ),
      ],
    ),
  );
}

Future<bool> konfirmasi(BuildContext context, String judul, String isi) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(judul),
      content: Text(isi),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Tidak')),
        TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Ya')),
      ],
    ),
  );
  return ok ?? false;
}

/// Pilih tanggal (hanya yang tersedia) lalu jam janji.
Future<DateTime?> pilihJadwal(BuildContext context, Repository repo) async {
  final tersedia = await repo.tanggalTersedia();
  final pengaturan = await repo.pengaturan();
  if (!context.mounted) return null;
  if (tersedia.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Tidak ada tanggal tersedia. Perpanjang periode jadwal di menu Atur.'),
    ));
    return null;
  }
  final urut = tersedia.toList()..sort();
  final tanggal = await showDatePicker(
    context: context,
    helpText: 'Pilih tanggal berobat',
    initialDate: urut.first,
    firstDate: urut.first,
    lastDate: pengaturan.periodeAkhir,
    selectableDayPredicate: (d) => tersedia.contains(tanggalSaja(d)),
  );
  if (tanggal == null || !context.mounted) return null;

  final slot = await showModalBottomSheet<String>(
    context: context,
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pilih jam — ${fmtTanggal(tanggal)}', style: Theme.of(ctx).textTheme.titleMedium),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final s in pengaturan.slotJam)
                  ActionChip(label: Text(s), onPressed: () => Navigator.pop(ctx, s)),
              ],
            ),
          ],
        ),
      ),
    ),
  );
  if (slot == null) return null;
  return gabungJam(tanggal, slot);
}

/// Jalankan aksi async dengan snackbar sukses / gagal.
Future<bool> jalankan(BuildContext context, Future<void> Function() aksi, {String? sukses}) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    await aksi();
    if (sukses != null) messenger.showSnackBar(SnackBar(content: Text(sukses)));
    return true;
  } catch (e) {
    messenger.showSnackBar(SnackBar(content: Text('$e')));
    return false;
  }
}
