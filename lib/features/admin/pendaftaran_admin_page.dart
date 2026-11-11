import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../core/klinik.dart';
import '../../core/theme.dart';
import '../../data/repository.dart';
import '../../models/models.dart';
import '../../widgets/async_view.dart';
import '../../widgets/jadwal_card.dart';
import '../../widgets/kalender.dart';
import '../../widgets/kontak.dart';
import '../../widgets/media.dart';
import '../../widgets/ui.dart';
import 'chat_admin_page.dart';

/// Daftar pendaftaran dengan pencarian & filter status.
class PendaftaranAdminPage extends StatefulWidget {
  const PendaftaranAdminPage({super.key});

  @override
  State<PendaftaranAdminPage> createState() => _PendaftaranAdminPageState();
}

class _PendaftaranAdminPageState extends State<PendaftaranAdminPage> {
  StatusPendaftaran? _f = StatusPendaftaran.menunggu; // null = semua
  String _q = '';

  static const _filter = [
    StatusPendaftaran.menunggu,
    StatusPendaftaran.dijadwalkan,
    StatusPendaftaran.ditolak,
    StatusPendaftaran.selesai,
    null,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: headerApp('Pendaftaran'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            decoration: const InputDecoration(hintText: 'Cari nama atau nomor HP'),
            onChanged: (v) => setState(() => _q = v),
          ),
          DeretPil(children: [
            for (final s in _filter)
              Pil(s?.label ?? 'Semua', aktif: _f == s, onTap: () => setState(() => _f = s)),
          ]),
          AsyncView(
            key: ValueKey((_f, _q)),
            load: (repo) => repo.semuaPendaftaran(status: _f, cari: _q),
            builder: (context, list) => Column(
              children: [
                if (list.isEmpty) const Align(alignment: Alignment.centerLeft, child: TeksKosong('Tidak ada data.')),
                for (final p in list)
                  Kartu(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: (_) => DetailPendaftaranAdminPage(id: p.id)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Baris(
                          kiri: Text(p.nama, style: const TextStyle(fontWeight: FontWeight.w700)),
                          kanan: Tag.status(p.status),
                        ),
                        Text('${p.noHp} - ${p.keluhan}', style: tsMut),
                        if (p.status == StatusPendaftaran.dijadwalkan)
                          Text('${fmtPendek(p.tanggal!)} pukul ${p.jam}', style: tsCap),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ======================================================================= detail

class DetailPendaftaranAdminPage extends StatefulWidget {
  const DetailPendaftaranAdminPage({super.key, required this.id});
  final String id;

  @override
  State<DetailPendaftaranAdminPage> createState() => _DetailPendaftaranAdminPageState();
}

class _DetailPendaftaranAdminPageState extends State<DetailPendaftaranAdminPage> {
  DateTime? _beri;
  String? _jam;
  final _alasan = TextEditingController();
  bool _proses = false;

  @override
  void dispose() {
    _alasan.dispose();
    super.dispose();
  }

  Repository get _repo => context.read<Repository>();

  Future<void> _aksi(Future<void> Function() f, String judul, String isi) async {
    setState(() => _proses = true);
    try {
      await f();
      if (mounted) toast(context, judul, isi);
    } catch (e) {
      if (mounted) toast(context, 'Gagal', '$e');
    } finally {
      if (mounted) setState(() => _proses = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: headerApp('Detail Pendaftaran', aksi: [TombolHeader('Kembali', onTap: () => Navigator.pop(context))]),
      body: AsyncView(
        load: (repo) async => (await repo.pendaftaran(widget.id), await repo.sisaKuotaPerTanggal()),
        builder: (context, data) {
          final (p, sisa) = data;
          if (p == null) return const Center(child: Text('Data tidak ditemukan.'));
          final dijadwalkan = p.status == StatusPendaftaran.dijadwalkan;
          final bisaJadwal = p.status == StatusPendaftaran.menunggu || dijadwalkan;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (dijadwalkan) KartuJadwal(p),
              _kartuData(p),
              if (bisaJadwal) _kartuBeriJadwal(p, sisa),
              if (p.status == StatusPendaftaran.menunggu) _kartuTolak(p),
              if (dijadwalkan) ...[
                Tombol('Kirim pengingat sekarang',
                    atas: 0,
                    varian: Varian.garis,
                    onPressed: () => _aksi(() => _repo.kirimPengingat(p.id), 'Pengingat terkirim', 'Ke ${p.nama}')),
                Row(
                  children: [
                    Expanded(child: _tombolStatus(p, StatusPendaftaran.selesai, 'Selesai', Varian.garis)),
                    const SizedBox(width: 8),
                    Expanded(child: _tombolStatus(p, StatusPendaftaran.tidakHadir, 'Tidak hadir', Varian.garis)),
                    const SizedBox(width: 8),
                    Expanded(child: _tombolStatus(p, StatusPendaftaran.batal, 'Batal', Varian.merah)),
                  ],
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _kartuData(Pendaftaran p) {
    return Kartu(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Baris(
            kiri: Text('${p.nama}, ${p.umur} th', style: const TextStyle(fontWeight: FontWeight.w700)),
            kanan: Tag.status(p.status),
          ),
          Text('${p.noHp} - ${p.alamat}', style: tsMut),
          Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text(p.keluhan)),
          const Text('Foto/video kondisi (ketuk untuk memperbesar)', style: tsCap),
          GridMedia(berkas: p.mediaKondisi),
          const Padding(padding: EdgeInsets.only(top: 10), child: Text('Foto KTP (NIK ditutup)', style: tsCap)),
          GridMedia(berkas: [p.fotoKtp], label: 'KTP'),
          if (p.status == StatusPendaftaran.ditolak && p.alasan != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text.rich(
                TextSpan(children: [
                  const TextSpan(text: 'Alasan ditolak: ', style: TextStyle(fontWeight: FontWeight.w700)),
                  TextSpan(text: p.alasan),
                ]),
                style: const TextStyle(color: AppColors.red),
              ),
            ),
          Row(
            children: [
              Expanded(
                child: Tombol('WhatsApp',
                    varian: Varian.wa,
                    onPressed: () => bukaWhatsApp(context, p.noHp, pesan: 'Halo ${p.nama}, kami dari ${Klinik.nama}.')),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Tombol('Chat', varian: Varian.garis, onPressed: () => bukaChatAdmin(context, p.userId)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _kartuBeriJadwal(Pendaftaran p, Map<DateTime, int> sisa) {
    final pindah = p.status == StatusPendaftaran.dijadwalkan;
    return Kartu(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          JudulKartu(pindah ? 'Pindah jadwal' : 'Beri jadwal'),
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text('Pilih tanggal, lalu jam yang kuotanya masih ada.', style: tsMut),
          ),
          KalenderBulan(
            sisa: sisa,
            terpilih: _beri,
            wajibAdaSisa: true,
            onPilih: (t) => setState(() {
              _beri = t;
              _jam = null;
            }),
          ),
          if (_beri != null) ...[
            Label('Jam (${fmtHariTanggal(_beri!)})'),
            AsyncView(
              key: ValueKey(_beri),
              load: (repo) => repo.slotPada(_beri!),
              builder: (context, slot) => DeretPil(children: [
                for (final s in slot.where((s) => s.aktif))
                  () {
                    final milikSendiri = p.tanggal == _beri && p.jam == s.jam ? 1 : 0;
                    final r = s.kuota - s.terisi + milikSendiri;
                    return Pil('${s.jam} - sisa $r',
                        aktif: _jam == s.jam, nonaktif: r <= 0, onTap: () => setState(() => _jam = s.jam));
                  }(),
              ]),
            ),
          ],
          Tombol(
            pindah ? 'Simpan Jadwal Baru' : 'Jadwalkan & Kirim Notifikasi',
            memuat: _proses,
            onPressed: () {
              if (_beri == null || _jam == null) return toast(context, 'Pilih jadwal', 'Pilih tanggal dan jam dulu.');
              final (t, j) = (_beri!, _jam!);
              _aksi(() async {
                await _repo.jadwalkan(p.id, t, j);
                setState(() => _beri = _jam = null);
              }, 'Notifikasi terkirim', 'Jadwal dikirim ke ${p.nama}');
            },
          ),
        ],
      ),
    );
  }

  Widget _kartuTolak(Pendaftaran p) {
    return Kartu(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const JudulKartu('Tidak dapat ditangani?'),
          const Label('Alasan (wajib, dikirim ke pasien)', atas: 0),
          TextField(
            controller: _alasan,
            minLines: 4,
            maxLines: 6,
            decoration: const InputDecoration(
              hintText: 'Contoh: berdasarkan foto kondisi, keluhan ini belum dapat kami tangani.',
            ),
          ),
          Tombol('Tolak Pendaftaran', varian: Varian.merah, onPressed: () {
            if (_alasan.text.trim().isEmpty) {
              return toast(context, 'Alasan wajib', 'Tulis alasan penolakan untuk pasien.');
            }
            _aksi(() => _repo.tolak(p.id, _alasan.text), 'Terkirim', 'Ke ${p.nama}');
          }),
        ],
      ),
    );
  }

  Widget _tombolStatus(Pendaftaran p, StatusPendaftaran s, String label, Varian v) {
    return Tombol(label, varian: v, onPressed: () async {
      if (s == StatusPendaftaran.batal && !await konfirmasi(context, 'Batalkan jadwal ini?')) return;
      await _aksi(() => _repo.ubahStatus(p.id, s), 'Status diperbarui', s.label);
    });
  }
}
