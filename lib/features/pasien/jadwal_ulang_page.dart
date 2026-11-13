import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../data/repository.dart';
import '../../models/models.dart';
import '../../widgets/async_view.dart';
import '../../widgets/kalender.dart';
import '../../widgets/ui.dart';

Future<void> bukaAjukanJadwalUlang(BuildContext context, Pendaftaran p) =>
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => AjukanJadwalUlangPage(p: p)));

/// Pasien memilih tanggal + jam baru (slot yang masih bersisa) dan alasan;
/// jadwal baru berlaku setelah disetujui admin.
class AjukanJadwalUlangPage extends StatefulWidget {
  const AjukanJadwalUlangPage({super.key, required this.p});
  final Pendaftaran p;

  @override
  State<AjukanJadwalUlangPage> createState() => _AjukanJadwalUlangPageState();
}

class _AjukanJadwalUlangPageState extends State<AjukanJadwalUlangPage> {
  DateTime? _tanggal;
  String? _jam;
  final _alasan = TextEditingController();
  bool _proses = false;

  @override
  void dispose() {
    _alasan.dispose();
    super.dispose();
  }

  Future<void> _kirim() async {
    if (_tanggal == null || _jam == null) return toast(context, 'Pilih jadwal', 'Pilih tanggal dan jam baru dulu.');
    setState(() => _proses = true);
    try {
      await context.read<Repository>().ajukanJadwalUlang(widget.p.id, _tanggal!, _jam!, alasan: _alasan.text);
      if (!mounted) return;
      toast(context, 'Pengajuan terkirim', 'Menunggu persetujuan admin.');
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) toast(context, 'Gagal', '$e');
    } finally {
      if (mounted) setState(() => _proses = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.p;
    return Scaffold(
      appBar: headerApp('Ajukan Jadwal Ulang', kembali: true),
      body: AsyncView(
        load: (repo) => repo.sisaKuotaPerTanggal(),
        builder: (context, sisa) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Kartu(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(p.nama, style: const TextStyle(fontWeight: FontWeight.w700)),
                  if (p.tanggal != null) Text('Jadwal sekarang: ${fmtTanggal(p.tanggal!)} pukul ${p.jam}', style: tsMut),
                ],
              ),
            ),
            Kartu(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const JudulKartu('Pilih jadwal baru'),
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Text('Pilih tanggal, lalu jam yang kuotanya masih ada.', style: tsMut),
                  ),
                  KalenderBulan(
                    sisa: sisa,
                    terpilih: _tanggal,
                    wajibAdaSisa: true,
                    onPilih: (t) => setState(() {
                      _tanggal = t;
                      _jam = null;
                    }),
                  ),
                  if (_tanggal != null) ...[
                    Label('Jam (${fmtHariTanggal(_tanggal!)})'),
                    AsyncView(
                      key: ValueKey(_tanggal),
                      load: (repo) => repo.slotPada(_tanggal!),
                      builder: (context, slot) {
                        final aktif = slot.where((s) => s.aktif).toList();
                        if (aktif.isEmpty) return const TeksKosong('Tidak ada jam di tanggal ini.');
                        return DeretPil(
                          children: [
                            for (final s in aktif)
                              Pil(
                                '${s.jam} - sisa ${s.sisa}',
                                aktif: _jam == s.jam,
                                // Jadwal sekarang sendiri tidak bisa dipilih.
                                nonaktif: s.sisa <= 0 || (p.tanggal == _tanggal && p.jam == s.jam),
                                onTap: () => setState(() => _jam = s.jam),
                              ),
                          ],
                        );
                      },
                    ),
                  ],
                  const Label('Alasan (boleh dikosongkan)'),
                  TextField(
                    controller: _alasan,
                    minLines: 2,
                    maxLines: 4,
                    maxLength: 1000,
                    decoration: const InputDecoration(hintText: 'Contoh: ada acara keluarga di tanggal tersebut.'),
                  ),
                  Tombol('Kirim Pengajuan', memuat: _proses, onPressed: _kirim),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
