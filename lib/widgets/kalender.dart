import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/format.dart';
import '../core/theme.dart';

/// Kalender bulanan (.kal di demo). Angka kecil di bawah tanggal = sisa kuota.
///
/// Tanggal bisa dipilih bila setelah hari ini dan punya slot aktif;
/// bila [wajibAdaSisa], sisa kuota juga harus > 0 (kecuali [tanggalSendiri]).
/// Bila [bebasPilih] (atur slot admin), semua tanggal setelah hari ini bisa dipilih
/// sampai 24 bulan ke depan, termasuk yang belum punya slot / slotnya nonaktif.
class KalenderBulan extends StatefulWidget {
  const KalenderBulan({
    super.key,
    required this.sisa,
    required this.terpilih,
    required this.onPilih,
    this.wajibAdaSisa = false,
    this.bebasPilih = false,
    this.tanggalSendiri,
    this.hariIni,
    this.pilihBulanTahun = false,
  });

  /// Dropdown bulan & tahun terpisah agar bisa lompat langsung (halaman Jadwal admin).
  final bool pilihBulanTahun;

  final Map<DateTime, int> sisa;
  final DateTime? terpilih;
  final ValueChanged<DateTime> onPilih;
  final bool wajibAdaSisa;
  final bool bebasPilih;

  /// Tanggal jadwal pasien saat ini: tetap bisa dipilih walau penuh (slotnya milik pasien itu).
  final DateTime? tanggalSendiri;
  final DateTime? hariIni;

  @override
  State<KalenderBulan> createState() => _KalenderBulanState();
}

class _KalenderBulanState extends State<KalenderBulan> {
  int _ix = 0;

  DateTime get _hariIni => tanggalSaja(widget.hariIni ?? DateTime.now());

  List<DateTime> get _bulan {
    final awal = DateTime(_hariIni.year, _hariIni.month);
    final akhir = _akhir;
    final n = (akhir.year - awal.year) * 12 + akhir.month - awal.month + 1;
    return [for (var i = 0; i < (n < 1 ? 1 : n); i++) DateTime(awal.year, awal.month + i)];
  }

  /// Tanggal terakhir yang punya slot aktif, atau null.
  DateTime? get _slotTerakhir =>
      widget.sisa.isEmpty ? null : widget.sisa.keys.reduce((a, b) => a.isAfter(b) ? a : b);

  /// Batas bulan yang bisa dibuka.
  DateTime get _akhir {
    if (widget.bebasPilih) return DateTime(_hariIni.year, _hariIni.month, _hariIni.day + 730);
    return _slotTerakhir ?? _hariIni.add(const Duration(days: 30));
  }

  @override
  void initState() {
    super.initState();
    _keBulanTerpilih();
  }

  @override
  void didUpdateWidget(KalenderBulan old) {
    super.didUpdateWidget(old);
    // Tanggal dipilih dari luar (mis. dari Beranda) di bulan lain: pindah ke bulannya.
    final t = widget.terpilih;
    if (t != null && t != old.terpilih) {
      final m = _bulan[_ix.clamp(0, _bulan.length - 1)];
      if (m.year != t.year || m.month != t.month) _keBulanTerpilih();
    }
  }

  void _keBulanTerpilih() {
    final t = widget.terpilih;
    if (t != null) {
      final i = _bulan.indexWhere((m) => m.year == t.year && m.month == t.month);
      if (i >= 0) _ix = i;
    }
  }

  static const _gayaDropdown = TextStyle(fontFamily: fontBody, fontSize: 16, color: AppColors.tx);

  Widget _kotak(Widget dropdown) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.bd),
          borderRadius: BorderRadius.circular(6),
        ),
        child: DropdownButtonHideUnderline(child: dropdown),
      );

  /// Dropdown bulan (Januari–Desember); bulan di luar jangkauan kalender tidak bisa dipilih.
  Widget _pilihBulan(List<DateTime> bulan, DateTime m) => _kotak(
        DropdownButton<int>(
          value: m.month,
          isExpanded: true,
          menuMaxHeight: 360,
          style: _gayaDropdown,
          items: [
            for (var b = 1; b <= 12; b++)
              () {
                final ada = bulan.any((x) => x.year == m.year && x.month == b);
                return DropdownMenuItem(
                  value: b,
                  enabled: ada,
                  child: Text(
                    DateFormat('MMMM', 'id_ID').format(DateTime(m.year, b)),
                    style: ada ? null : const TextStyle(color: AppColors.mut),
                  ),
                );
              }(),
          ],
          onChanged: (b) {
            final i = bulan.indexWhere((x) => x.year == m.year && x.month == b);
            if (i >= 0) setState(() => _ix = i);
          },
        ),
      );

  /// Dropdown tahun; pindah tahun tetap di bulan yang sama bila ada, selain itu bulan terdekat.
  Widget _pilihTahun(List<DateTime> bulan, DateTime m) => _kotak(
        DropdownButton<int>(
          value: m.year,
          isExpanded: true,
          style: _gayaDropdown,
          items: [
            for (final y in {for (final x in bulan) x.year}) DropdownMenuItem(value: y, child: Text('$y')),
          ],
          onChanged: (y) {
            if (y == null) return;
            var i = bulan.indexWhere((x) => x.year == y && x.month == m.month);
            if (i < 0) {
              i = y > m.year
                  ? bulan.indexWhere((x) => x.year == y)
                  : bulan.lastIndexWhere((x) => x.year == y);
            }
            if (i >= 0) setState(() => _ix = i);
          },
        ),
      );

  @override
  Widget build(BuildContext context) {
    final bulan = _bulan;
    if (_ix >= bulan.length) _ix = bulan.length - 1;
    final m = bulan[_ix];
    final jumlahHari = DateTime(m.year, m.month + 1, 0).day;
    final kosongAwal = m.weekday % 7; // Minggu di kolom pertama

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            _Panah('‹', aktif: _ix > 0, onTap: () => setState(() => _ix--)),
            const SizedBox(width: 6),
            if (widget.pilihBulanTahun) ...[
              Expanded(flex: 3, child: _pilihBulan(bulan, m)),
              const SizedBox(width: 6),
              Expanded(flex: 2, child: _pilihTahun(bulan, m)),
            ] else
              Expanded(
                child: _kotak(
                  DropdownButton<int>(
                    value: _ix,
                    isExpanded: true,
                    menuMaxHeight: 360,
                    style: _gayaDropdown,
                    items: [
                      for (var i = 0; i < bulan.length; i++)
                        DropdownMenuItem(value: i, child: Text(fmtBulan(bulan[i]))),
                    ],
                    onChanged: (v) => setState(() => _ix = v ?? _ix),
                  ),
                ),
              ),
            const SizedBox(width: 6),
            _Panah('›', aktif: _ix < bulan.length - 1, onTap: () => setState(() => _ix++)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (final h in hariSingkat)
              Expanded(
                child: Text(
                  h[0],
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: AppColors.mut),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        GridView.count(
          crossAxisCount: 7,
          mainAxisSpacing: 4,
          crossAxisSpacing: 4,
          childAspectRatio: 1.15,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            for (var i = 0; i < kosongAwal; i++) const SizedBox.shrink(),
            for (var d = 1; d <= jumlahHari; d++) _sel(DateTime(m.year, m.month, d)),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            _slotTerakhir == null
                ? 'Belum ada slot aktif.'
                : 'Angka kecil = sisa kuota. Slot tersedia sampai ${fmtPendekPanjang(_slotTerakhir!)}.',
            style: tsCap,
          ),
        ),
      ],
    );
  }

  Widget _sel(DateTime t) {
    final s = widget.sisa[t];
    final setelahHariIni = t.isAfter(_hariIni);
    final ok = setelahHariIni &&
        (widget.bebasPilih ||
            (s != null && (!widget.wajibAdaSisa || s > 0 || t == widget.tanggalSendiri)));
    final on = widget.terpilih == t;
    final hariIni = t == _hariIni; // ditandai bingkai emas & tebal (sama dengan panel web)
    return Opacity(
      opacity: ok ? 1 : (hariIni ? 0.7 : 0.35),
      child: Material(
        color: on ? AppColors.pri : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: on ? AppColors.pri : (hariIni ? AppColors.gold : AppColors.bd),
            width: hariIni && !on ? 2 : 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: ok ? () => widget.onPilih(t) : null,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${t.day}',
                semanticsLabel: hariIni ? '${t.day}, hari ini' : null,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.15,
                  fontWeight: hariIni ? FontWeight.w800 : null,
                  color: on ? Colors.white : AppColors.tx,
                ),
              ),
              if (s != null && setelahHariIni)
                Text(
                  '$s',
                  style: TextStyle(
                    fontSize: 11,
                    height: 1.15,
                    fontWeight: FontWeight.w600,
                    color: on ? Colors.white : (s > 0 ? AppColors.ok : AppColors.red),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 25 November 2026
String fmtPendekPanjang(DateTime d) => '${d.day} ${fmtBulan(d)}';

class _Panah extends StatelessWidget {
  const _Panah(this.teks, {required this.aktif, required this.onTap});
  final String teks;
  final bool aktif;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: aktif ? 1 : 0.3,
      child: Material(
        color: Colors.white,
        shape: const StadiumBorder(side: BorderSide(color: AppColors.bd)),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: aktif ? onTap : null,
          child: Container(
            constraints: const BoxConstraints(minHeight: 40, minWidth: 44),
            alignment: Alignment.center,
            child: Text(teks, style: const TextStyle(fontSize: 20)),
          ),
        ),
      ),
    );
  }
}
