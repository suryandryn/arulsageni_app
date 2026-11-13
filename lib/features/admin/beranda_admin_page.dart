import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../data/repository.dart';
import '../../models/models.dart';
import '../../widgets/async_view.dart';
import '../../widgets/ui.dart';
import 'admin_shell.dart';
import 'pendaftaran_admin_page.dart';

/// Beranda admin, isinya sama dengan Beranda panel web: 4 angka ringkas,
/// daftar "Menunggu dinilai", dan pasien di hari praktik berikutnya.
class BerandaAdminPage extends StatelessWidget {
  const BerandaAdminPage({super.key});

  void _detail(BuildContext context, String id) =>
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => DetailPendaftaranAdminPage(id: id)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: headerApp('Beranda Admin'),
      body: AsyncView(
        load: (repo) => repo.ringkas(),
        builder: (context, r) => RefreshIndicator(
          onRefresh: () async => context.read<Repository>().segarkan(),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (r.pengajuanMenunggu > 0)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Material(
                    color: const Color(0xFFFBE4E2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: AppColors.redBd),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => bukaPendaftaranAdmin(context, null, pengajuan: true),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${r.pengajuanMenunggu} pengajuan jadwal ulang / pembatalan menunggu keputusan',
                                style: const TextStyle(color: AppColors.red, fontWeight: FontWeight.w700),
                              ),
                            ),
                            const Icon(Icons.chevron_right, color: AppColors.red),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.35,
                children: [
                  _KotakAngka(
                    judul: 'Pendaftaran menunggu',
                    angka: r.menunggu,
                    latar: AppColors.wbg,
                    warna: AppColors.wtx,
                    warnaJudul: AppColors.wtx,
                    onTap: () => bukaPendaftaranAdmin(context, StatusPendaftaran.menunggu),
                  ),
                  _KotakAngka(
                    judul: 'Jadwal hari praktik berikutnya',
                    angka: r.jadwalHariBerikut,
                    keterangan: r.hariBerikut == null ? 'Belum ada slot aktif' : fmtTanggal(r.hariBerikut!),
                    onTap: () => bukaJadwalAdmin(context, r.hariBerikut),
                  ),
                  _KotakAngka(
                    judul: 'Sisa kuota 30 hari',
                    angka: r.sisaKuota30Hari,
                    onTap: () => bukaJadwalAdmin(context, null),
                  ),
                  _KotakAngka(
                    judul: 'Chat belum dibaca',
                    angka: r.chatBelumDibaca,
                    warna: AppColors.gold,
                    onTap: () => bukaTabAdmin(context, 3),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Kartu(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const JudulKartu('Menunggu dinilai'),
                    if (r.terbaru.isEmpty) const Text('Tidak ada pendaftaran baru.', style: tsMut),
                    for (final p in r.terbaru)
                      _BarisDaftar(
                        onTap: () => _detail(context, p.id),
                        atas: Row(
                          children: [
                            Expanded(
                              child: Text.rich(
                                TextSpan(
                                  children: [
                                    TextSpan(
                                      text: p.nama,
                                      style: const TextStyle(fontWeight: FontWeight.w700),
                                    ),
                                    TextSpan(text: ' (${p.umur} th)', style: tsMut),
                                  ],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(fmtPendek(p.dibuat), style: tsCap),
                          ],
                        ),
                        bawah: Text(p.keluhan, style: tsMut, maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                  ],
                ),
              ),
              Kartu(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    JudulKartu(
                      r.hariBerikut == null ? 'Pasien hari praktik berikutnya' : 'Pasien ${fmtTanggal(r.hariBerikut!)}',
                    ),
                    if (r.pasienHariBerikut.isEmpty)
                      Text(
                        r.hariBerikut == null ? 'Belum ada hari praktik yang dibuka.' : 'Belum ada pasien terjadwal.',
                        style: tsMut,
                      ),
                    for (final p in r.pasienHariBerikut)
                      _BarisDaftar(
                        onTap: () => _detail(context, p.id),
                        atas: Row(
                          children: [
                            SizedBox(
                              width: 52,
                              child: Text('No. ${p.nomor ?? '-'}',
                                  style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.pri)),
                            ),
                            Expanded(
                              child: Text(p.nama, style: const TextStyle(fontWeight: FontWeight.w700)),
                            ),
                            Text('${p.jam} WIB'),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _KotakAngka extends StatelessWidget {
  const _KotakAngka({
    required this.judul,
    required this.angka,
    required this.onTap,
    this.keterangan,
    this.latar = AppColors.card,
    this.warna = AppColors.pri,
    this.warnaJudul = AppColors.mut,
  });

  final String judul;
  final int angka;
  final String? keterangan;
  final VoidCallback onTap;
  final Color latar;
  final Color warna;
  final Color warnaJudul;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: latar,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.bd),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(judul, style: TextStyle(fontSize: 13, color: warnaJudul), maxLines: 2),
              const Spacer(),
              Text(
                '$angka',
                style: lora(30, weight: FontWeight.w700, color: warna, height: 1.1),
              ),
              if (keterangan != null) Text(keterangan!, style: tsCap, maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    );
  }
}

class _BarisDaftar extends StatelessWidget {
  const _BarisDaftar({required this.atas, this.bawah, required this.onTap});

  final Widget atas;
  final Widget? bawah;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [atas, ?bawah]),
      ),
    );
  }
}
