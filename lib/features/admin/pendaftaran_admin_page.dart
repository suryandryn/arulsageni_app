import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../core/klinik.dart';
import '../../core/theme.dart';
import '../../data/repository.dart';
import '../../models/models.dart';
import '../../widgets/async_view.dart';
import '../../widgets/catatan_lengkapi.dart';
import '../../widgets/jadwal_card.dart';
import '../../widgets/kalender.dart';
import '../../widgets/kontak.dart';
import '../../widgets/media.dart';
import '../../widgets/pengajuan.dart';
import '../../widgets/ui.dart';
import 'admin_shell.dart';
import 'chat_admin_page.dart';

/// Daftar pendaftaran dengan pencarian & filter status.
class PendaftaranAdminPage extends StatefulWidget {
  const PendaftaranAdminPage({super.key});

  @override
  State<PendaftaranAdminPage> createState() => _PendaftaranAdminPageState();
}

class _PendaftaranAdminPageState extends State<PendaftaranAdminPage> {
  // Sama dengan panel web: bawaan "Semua", lalu semua status beserta jumlahnya.
  // Filter disimpan di [filterPendaftaranAdmin] agar Beranda bisa membuka "Menunggu".
  StatusPendaftaran? get _f => filterPendaftaranAdmin.value;
  bool get _pengajuan => filterPengajuanAdmin.value;

  void _pilih(StatusPendaftaran? s, {bool pengajuan = false}) => setState(() {
        filterPengajuanAdmin.value = pengajuan;
        filterPendaftaranAdmin.value = pengajuan ? null : s;
      });

  // Pencarian disimpan di [cariPendaftaranAdmin] agar Data Pasien bisa membuka pendaftaran satu pasien.
  String get _q => cariPendaftaranAdmin.value;
  late final _cari = TextEditingController(text: _q);

  @override
  void initState() {
    super.initState();
    filterPendaftaranAdmin.addListener(_ubah);
    filterPengajuanAdmin.addListener(_ubah);
    cariPendaftaranAdmin.addListener(_ubahCari);
  }

  @override
  void dispose() {
    filterPendaftaranAdmin.removeListener(_ubah);
    filterPengajuanAdmin.removeListener(_ubah);
    cariPendaftaranAdmin.removeListener(_ubahCari);
    _cari.dispose();
    super.dispose();
  }

  void _ubah() => setState(() {});

  void _ubahCari() {
    if (_cari.text != _q) _cari.text = _q;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: headerApp('Pendaftaran'),
      body: RefreshIndicator(
        onRefresh: () async => context.read<Repository>().segarkan(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              controller: _cari,
              decoration: InputDecoration(
                hintText: 'Cari nama atau nomor HP',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _q.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Hapus pencarian',
                        icon: const Icon(Icons.close),
                        onPressed: () => cariPendaftaranAdmin.value = '',
                      ),
              ),
              onChanged: (v) => cariPendaftaranAdmin.value = v,
            ),
            AsyncView(
              load: (repo) async => (await repo.jumlahPendaftaran(), await repo.jumlahPengajuanMenunggu()),
              builder: (context, data) {
                final (jumlah, pengajuan) = data;
                return DeretPil(
                  geser: true,
                  children: [
                    Pil(
                      'Semua',
                      aktif: _f == null && !_pengajuan,
                      jumlah: jumlah.values.fold<int>(0, (a, b) => a + b),
                      onTap: () => _pilih(null),
                    ),
                    Pil('Pengajuan pasien', aktif: _pengajuan, jumlah: pengajuan, onTap: () => _pilih(null, pengajuan: true)),
                    for (final s in StatusPendaftaran.values)
                      Pil(s.label, aktif: !_pengajuan && _f == s, jumlah: jumlah[s] ?? 0, onTap: () => _pilih(s)),
                  ],
                );
              },
            ),
            AsyncView(
              key: ValueKey((_f, _q, _pengajuan)),
              load: (repo) => repo.semuaPendaftaran(status: _f, cari: _q, hanyaPengajuan: _pengajuan),
              builder: (context, list) => Column(
                children: [
                  if (list.isEmpty) const Align(alignment: Alignment.centerLeft, child: TeksKosong('Tidak ada data.')),
                  for (final p in list)
                    Kartu(
                      onTap: () =>
                          Navigator.of(context)
                              .push(MaterialPageRoute<void>(builder: (_) => DetailPendaftaranAdminPage(id: p.id))),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Baris(
                            kiri: Text(p.nama, style: const TextStyle(fontWeight: FontWeight.w700)),
                            kanan: Tag.status(p.status),
                          ),
                          Text('${p.noHp} - ${p.keluhan}', style: tsMut),
                          Text('Daftar ${fmtPendek(p.dibuat)}', style: tsCap),
                          if (p.status == StatusPendaftaran.dijadwalkan)
                            Text(
                              '${fmtPendek(p.tanggal!)} pukul ${p.jam}'
                              '${p.nomorAntrean == null ? '' : ' · No. ${p.nomorAntrean}'}',
                              style: tsCap,
                            ),
                          if (p.status == StatusPendaftaran.menunggu && p.dilengkapi != null)
                            const Text('Sudah dilengkapi pasien',
                                style: TextStyle(fontSize: 13, color: AppColors.ok, fontWeight: FontWeight.w600)),
                          if (p.pengajuanMenunggu case final a?)
                            Text(
                              a.jenis == JenisPengajuan.jadwalUlang
                                  ? 'Minta jadwal ulang ke ${fmtPendek(a.tanggal!)} pukul ${a.jam}'
                                  : 'Minta pembatalan',
                              style: const TextStyle(fontSize: 13, color: AppColors.red, fontWeight: FontWeight.w600),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
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
      appBar: headerApp('Detail Pendaftaran', kembali: true),
      body: AsyncView(
        load: (repo) async => (await repo.pendaftaran(widget.id), await repo.sisaKuotaPerTanggal()),
        builder: (context, data) {
          final (p, sisa) = data;
          if (p == null) return const Center(child: Text('Data tidak ditemukan.'));
          final dijadwalkan = p.status == StatusPendaftaran.dijadwalkan;
          final belumDinilai = p.status == StatusPendaftaran.menunggu || p.status == StatusPendaftaran.perluDilengkapi;
          final bisaJadwal = belumDinilai || dijadwalkan;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Pengajuan menunggu tampil paling atas agar langsung diputuskan.
              if (p.pengajuanMenunggu != null) _kartuPengajuan(p),
              if (dijadwalkan) KartuJadwal(p),
              if (p.catatan != null) KartuCatatanLengkapi(p, admin: true),
              _kartuData(p),
              if (p.pengajuan != null && p.pengajuanMenunggu == null) KartuPengajuan(p, admin: true),
              if (bisaJadwal) _kartuBeriJadwal(p, sisa),
              if (belumDinilai) _kartuLengkapi(p),
              if (belumDinilai) _kartuTolak(p),
              if (dijadwalkan) ...[
                Tombol(
                  'Kirim pengingat sekarang',
                  atas: 0,
                  varian: Varian.garis,
                  onPressed: () => _aksi(() => _repo.kirimPengingat(p.id), 'Pengingat terkirim', 'Ke ${p.nama}'),
                ),
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

  Widget _kartuPengajuan(Pendaftaran p) {
    final a = p.pengajuan!;
    return KartuPengajuan(
      p,
      admin: true,
      aksi: [
        Row(
          children: [
            Expanded(
              child: Tombol(
                'Setujui',
                memuat: _proses,
                onPressed: () async {
                  final teks = a.jenis == JenisPengajuan.jadwalUlang
                      ? 'Setujui jadwal ulang ke ${fmtTanggal(a.tanggal!)} pukul ${a.jam}? Jadwal pasien langsung dipindah.'
                      : 'Setujui pembatalan? Status pendaftaran menjadi Batal.';
                  if (!await konfirmasi(context, teks)) return;
                  await _aksi(() => _repo.setujuiPengajuan(a.id), 'Pengajuan disetujui', 'Notifikasi dikirim ke ${p.nama}');
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Tombol(
                'Tolak',
                varian: Varian.merah,
                onPressed: _proses
                    ? null
                    : () async {
                        final alasan = await mintaAlasan(
                          context,
                          judul: 'Tolak pengajuan ${a.jenis.label.toLowerCase()}',
                          label: 'Alasan (wajib, dikirim ke pasien)',
                          petunjuk: 'Contoh: jadwal tersebut sudah penuh, silakan pilih tanggal lain.',
                          tombol: 'Tolak',
                          wajib: true,
                          merah: true,
                        );
                        if (alasan == null || !mounted) return;
                        await _aksi(() => _repo.tolakPengajuan(a.id, alasan), 'Pengajuan ditolak',
                            'Alasan dikirim ke ${p.nama}');
                      },
              ),
            ),
          ],
        ),
      ],
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
          Text(
            'Didaftarkan ${fmtWaktu(p.dibuat)}${p.namaAkun == null ? '' : ' oleh akun ${p.namaAkun}'}',
            style: tsCap,
          ),
          Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text(p.keluhan)),
          const Text('Foto/video kondisi (ketuk untuk memperbesar)', style: tsCap),
          GridMedia(berkas: p.mediaKondisi),
          const Padding(
            padding: EdgeInsets.only(top: 10),
            child: Text('Foto KTP (NIK ditutup)', style: tsCap),
          ),
          GridMedia(berkas: [p.fotoKtp], label: 'KTP'),
          if (p.status == StatusPendaftaran.ditolak && p.alasan != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(
                      text: 'Alasan ditolak: ',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    TextSpan(text: p.alasan),
                  ],
                ),
                style: const TextStyle(color: AppColors.red),
              ),
            ),
          Row(
            children: [
              Expanded(
                child: Tombol(
                  'WhatsApp',
                  varian: Varian.wa,
                  onPressed: () => bukaWhatsApp(context, p.noHp, pesan: 'Halo ${p.nama}, kami dari ${Klinik.nama}.'),
                ),
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
            // Tanggal pasien sendiri tetap bisa dipilih walau penuh (mis. pindah jam di hari yang sama).
            tanggalSendiri: pindah ? p.tanggal : null,
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
              builder: (context, slot) => DeretPil(
                children: [
                  for (final s in slot.where((s) => s.aktif))
                    () {
                      final milikSendiri = p.tanggal == _beri && p.jam == s.jam ? 1 : 0;
                      final r = s.kuota - s.terisi + milikSendiri;
                      return Pil(
                        '${s.jam} - sisa $r',
                        aktif: _jam == s.jam,
                        nonaktif: r <= 0,
                        onTap: () => setState(() => _jam = s.jam),
                      );
                    }(),
                ],
              ),
            ),
          ],
          Tombol(
            pindah ? 'Simpan Jadwal Baru' : 'Jadwalkan & Kirim Notifikasi',
            memuat: _proses,
            onPressed: () {
              if (_beri == null || _jam == null) return toast(context, 'Pilih jadwal', 'Pilih tanggal dan jam dulu.');
              final (t, j) = (_beri!, _jam!);
              _aksi(
                () async {
                  await _repo.jadwalkan(p.id, t, j);
                  setState(() => _beri = _jam = null);
                },
                'Notifikasi terkirim',
                'Jadwal dikirim ke ${p.nama}',
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _kartuLengkapi(Pendaftaran p) {
    final ulang = p.status == StatusPendaftaran.perluDilengkapi;
    return Kartu(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const JudulKartu('Data atau berkas kurang?'),
          const Text('Pasien diminta memperbaiki pendaftaran, lalu status kembali Menunggu.', style: tsMut),
          Tombol(
            ulang ? 'Ubah Catatan Perlu Dilengkapi' : 'Minta Dilengkapi',
            varian: Varian.garis,
            onPressed: _proses
                ? null
                : () async {
                    final catatan = await mintaAlasan(
                      context,
                      judul: 'Perlu dilengkapi',
                      label: 'Apa yang perlu dilengkapi? (wajib, dikirim ke pasien)',
                      petunjuk: 'Contoh: foto kondisi kurang jelas, mohon kirim ulang dari dekat.',
                      tombol: 'Kirim ke pasien',
                      wajib: true,
                    );
                    if (catatan == null || !mounted) return;
                    await _aksi(() => _repo.mintaDilengkapi(p.id, catatan), 'Terkirim', '${p.nama} diminta melengkapi');
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
          Tombol(
            'Tolak Pendaftaran',
            varian: Varian.merah,
            onPressed: () {
              if (_alasan.text.trim().isEmpty) {
                return toast(context, 'Alasan wajib', 'Tulis alasan penolakan untuk pasien.');
              }
              _aksi(() => _repo.tolak(p.id, _alasan.text), 'Terkirim', 'Ke ${p.nama}');
            },
          ),
        ],
      ),
    );
  }

  Widget _tombolStatus(Pendaftaran p, StatusPendaftaran s, String label, Varian v) {
    return Tombol(
      label,
      varian: v,
      onPressed: () async {
        if (s == StatusPendaftaran.batal && !await konfirmasi(context, 'Batalkan jadwal ini?')) return;
        await _aksi(() => _repo.ubahStatus(p.id, s), 'Status diperbarui', s.label);
      },
    );
  }
}
