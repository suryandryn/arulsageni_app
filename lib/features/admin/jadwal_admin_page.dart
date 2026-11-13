import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../data/repository.dart';
import '../../models/models.dart';
import '../../widgets/async_view.dart';
import '../../widgets/kalender.dart';
import '../../widgets/ui.dart';
import 'admin_shell.dart';
import 'pendaftaran_admin_page.dart';

/// Kalender jadwal: slot per tanggal (kuota, aktif, hapus, tambah jam) + buat slot massal.
class JadwalAdminPage extends StatefulWidget {
  const JadwalAdminPage({super.key});

  @override
  State<JadwalAdminPage> createState() => _JadwalAdminPageState();
}

class _JadwalAdminPageState extends State<JadwalAdminPage> {
  // Sama dengan panel web: bawaan tanggal besok. Disimpan di [tanggalJadwalAdmin]
  // agar Beranda bisa membuka hari praktik berikutnya.
  DateTime? get _tgl => tanggalJadwalAdmin.value;
  set _tgl(DateTime? t) => tanggalJadwalAdmin.value = t;

  @override
  void initState() {
    super.initState();
    if (_tgl == null) {
      final h = tanggalSaja(DateTime.now());
      _tgl = DateTime(h.year, h.month, h.day + 1);
    }
    tanggalJadwalAdmin.addListener(_ubah);
  }

  @override
  void dispose() {
    tanggalJadwalAdmin.removeListener(_ubah);
    super.dispose();
  }

  void _ubah() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: headerApp('Kalender Jadwal'),
      body: RefreshIndicator(
        onRefresh: () async => context.read<Repository>().segarkan(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Kartu(
              child: AsyncView(
                load: (repo) => repo.sisaKuotaPerTanggal(),
                builder: (context, sisa) =>
                    KalenderBulan(
                      sisa: sisa,
                      terpilih: _tgl,
                      bebasPilih: true, // tanggal tanpa slot / slot nonaktif tetap bisa dibuka untuk diatur
                      pilihBulanTahun: true,
                      onPilih: (t) => setState(() => _tgl = t),
                    ),
              ),
            ),
            if (_tgl == null)
              const TeksKosong('Ketuk tanggal untuk melihat slot jam.')
            else
              _SlotTanggal(key: ValueKey(_tgl), tanggal: _tgl!),
            const _SlotMassal(),
          ],
        ),
      ),
    );
  }
}

class _SlotTanggal extends StatefulWidget {
  const _SlotTanggal({super.key, required this.tanggal});
  final DateTime tanggal;

  @override
  State<_SlotTanggal> createState() => _SlotTanggalState();
}

class _SlotTanggalState extends State<_SlotTanggal> {
  final _jam = TextEditingController();
  final _kuota = TextEditingController(text: '3');

  @override
  void dispose() {
    _jam.dispose();
    _kuota.dispose();
    super.dispose();
  }

  Future<void> _coba(Future<void> Function() f, [String? judul, String? isi]) async {
    try {
      await f();
      if (judul != null && mounted) toast(context, judul, isi ?? '');
    } catch (e) {
      if (mounted) toast(context, 'Tidak bisa', '$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.tanggal;
    final repo = context.read<Repository>();
    return Kartu(
      child: AsyncView(
        load: (repo) async => (
          await repo.slotPada(t),
          (await repo.semuaPendaftaran(status: StatusPendaftaran.dijadwalkan)).where((p) => p.tanggal == t).toList(),
        ),
        builder: (context, data) {
          final (slot, pasien) = data;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              JudulKartu(fmtTanggal(t)),
              if (slot.isEmpty) const TeksKosong('Belum ada slot di tanggal ini.'),
              for (final s in slot) ...[
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: AppColors.bd)),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 64,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(s.jam, style: const TextStyle(fontWeight: FontWeight.w700)),
                            Text('${s.terisi} terisi', style: tsCap),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      _KolomKuota(
                        key: ValueKey('${s.jam}-${s.kuota}'),
                        nilai: s.kuota,
                        onSimpan: (v) =>
                            _coba(() => repo.ubahKuotaSlot(t, s.jam, v), 'Kuota disimpan', '${s.jam} WIB, kuota $v'),
                      ),
                      const SizedBox(width: 8),
                      Pil(
                        s.aktif ? 'Aktif' : 'Nonaktif',
                        aktif: s.aktif,
                        onTap: () => _coba(
                          () => repo.aturSlotAktif(t, s.jam, !s.aktif),
                          s.aktif ? 'Slot dinonaktifkan' : 'Slot diaktifkan',
                          s.aktif ? '${s.jam} WIB tidak bisa dipilih pasien.' : '${s.jam} WIB bisa dipilih pasien.',
                        ),
                      ),
                      const Spacer(),
                      if (s.terisi == 0)
                        Pil(
                          'Hapus',
                          onTap: () async {
                            if (!await konfirmasi(context, 'Hapus jam ${s.jam}?')) return;
                            await _coba(() => repo.hapusSlot(t, s.jam), 'Jam dihapus', '${s.jam} WIB');
                          },
                        ),
                    ],
                  ),
                ),
                for (final p in pasien.where((p) => p.jam == s.jam).toList()
                  ..sort((a, b) => (a.nomorAntrean ?? 0).compareTo(b.nomorAntrean ?? 0)))
                  InkWell(
                    onTap: () =>
                        Navigator.of(context)
                            .push(MaterialPageRoute<void>(builder: (_) => DetailPendaftaranAdminPage(id: p.id))),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(72, 4, 0, 4),
                      child: Text(
                        'No. ${p.nomorAntrean ?? '-'} · ${p.nama}',
                        style: tsCap.copyWith(
                          color: AppColors.pri,
                          decoration: TextDecoration.underline,
                          decorationColor: AppColors.pri,
                        ),
                      ),
                    ),
                  ),
              ],
              const Label('Tambah jam di tanggal ini'),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _jam,
                      keyboardType: TextInputType.datetime,
                      decoration: const InputDecoration(hintText: 'contoh 09.00'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 76,
                    child: TextField(controller: _kuota, keyboardType: TextInputType.number),
                  ),
                  const SizedBox(width: 8),
                  Pil(
                    'Tambah',
                    aktif: true,
                    onTap: () {
                      final j = normalJam(_jam.text);
                      final k = int.tryParse(_kuota.text) ?? 0;
                      if (j == null || k < 1) {
                        return toast(context, 'Jam tidak valid', 'Isi jam seperti 09.00 dan kuota minimal 1.');
                      }
                      _coba(
                        () async {
                          await repo.tambahSlot(t, j, k);
                          _jam.clear();
                        },
                        'Jam ditambah',
                        '$j WIB, kuota $k',
                      );
                    },
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Kolom angka kuota; disimpan saat selesai diketik / fokus pindah.
class _KolomKuota extends StatefulWidget {
  const _KolomKuota({super.key, required this.nilai, required this.onSimpan});
  final int nilai;
  final Future<void> Function(int) onSimpan;

  @override
  State<_KolomKuota> createState() => _KolomKuotaState();
}

class _KolomKuotaState extends State<_KolomKuota> {
  late final _c = TextEditingController(text: '${widget.nilai}');
  final _fokus = FocusNode();

  @override
  void initState() {
    super.initState();
    _fokus.addListener(() {
      if (!_fokus.hasFocus) _simpan();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    _fokus.dispose();
    super.dispose();
  }

  Future<void> _simpan() async {
    final v = int.tryParse(_c.text);
    if (v == null || v == widget.nilai) {
      _c.text = '${widget.nilai}';
      return;
    }
    await widget.onSimpan(v);
    if (mounted) _c.text = '${widget.nilai}'; // dikembalikan bila ditolak; widget baru dibuat bila berhasil
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 76,
      child: TextField(
        controller: _c,
        focusNode: _fokus,
        keyboardType: TextInputType.number,
        onSubmitted: (_) => _fokus.unfocus(),
      ),
    );
  }
}

class _SlotMassal extends StatefulWidget {
  const _SlotMassal();

  @override
  State<_SlotMassal> createState() => _SlotMassalState();
}

class _SlotMassalState extends State<_SlotMassal> {
  late DateTime _mulai;
  late DateTime _sampai;
  final _hari = {1, 2, 3, 4, 5, 6}; // Minggu (0) libur
  final _jam = TextEditingController(text: '08.00, 10.00, 13.00, 15.00');
  final _kuota = TextEditingController(text: '3');
  bool _proses = false;

  @override
  void initState() {
    super.initState();
    final h = tanggalSaja(DateTime.now());
    _mulai = DateTime(h.year, h.month, h.day + 1);
    _sampai = DateTime(h.year, h.month, h.day + 730);
  }

  @override
  void dispose() {
    _jam.dispose();
    _kuota.dispose();
    super.dispose();
  }

  Future<void> _pilihTanggal(bool mulai) async {
    final h = tanggalSaja(DateTime.now());
    final t = await showDatePicker(
      context: context,
      initialDate: mulai ? _mulai : _sampai,
      firstDate: DateTime(h.year, h.month, h.day + 1),
      lastDate: DateTime(h.year + 6),
    );
    if (t != null) setState(() => mulai ? _mulai = t : _sampai = t);
  }

  Future<void> _buat() async {
    setState(() => _proses = true);
    try {
      final (baru, ada) = await context.read<Repository>().buatSlotMassal(
        mulai: _mulai,
        sampai: _sampai,
        hari: _hari,
        // Sama dengan panel web: pisahkan koma, titik koma, atau spasi.
        jam: _jam.text.split(RegExp(r'[,;\s]+')).where((e) => e.isNotEmpty).toList(),
        kuota: int.tryParse(_kuota.text) ?? 0,
      );
      if (mounted) toast(context, 'Slot dibuat', '$baru slot baru${ada > 0 ? ', $ada sudah ada (dilewati)' : ''}');
    } catch (e) {
      if (mounted) toast(context, 'Tidak bisa', '$e');
    } finally {
      if (mounted) setState(() => _proses = false);
    }
  }

  Widget _kolomTanggal(String label, DateTime nilai, bool mulai) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Label(label),
        InkWell(
          onTap: () => _pilihTanggal(mulai),
          child: InputDecorator(
            decoration: const InputDecoration(suffixIcon: Icon(Icons.calendar_today_outlined, size: 18)),
            child: Text(fmtPendek(nilai)),
          ),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Kartu(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const JudulKartu('Buat slot massal'),
          const Text(
            'Buka atau perpanjang jadwal, maksimal 24 bulan per sekali buat. Untuk 2 tahun berikutnya, '
            'ulangi dengan tanggal mulai baru. Slot yang sudah ada tidak digandakan.',
            style: tsMut,
          ),
          Row(
            children: [
              _kolomTanggal('Mulai', _mulai, true),
              const SizedBox(width: 8),
              _kolomTanggal('Sampai', _sampai, false),
            ],
          ),
          const Label('Hari praktik'),
          DeretPil(
            children: [
              for (var i = 0; i < 7; i++)
                Pil(
                  hariSingkat[i],
                  aktif: _hari.contains(i),
                  onTap: () => setState(() => _hari.contains(i) ? _hari.remove(i) : _hari.add(i)),
                ),
            ],
          ),
          const Label('Jam (pisahkan koma atau spasi)', atas: 6),
          TextField(controller: _jam),
          const Label('Kuota per jam'),
          TextField(controller: _kuota, keyboardType: TextInputType.number),
          Tombol('Buat Slot', memuat: _proses, onPressed: _buat),
        ],
      ),
    );
  }
}
