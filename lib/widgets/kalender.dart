import 'package:flutter/material.dart';

import '../core/format.dart';
import '../core/theme.dart';

/// Kalender bulanan (.kal di demo). Angka kecil di bawah tanggal = sisa kuota.
///
/// Tanggal bisa dipilih bila setelah hari ini dan punya slot aktif;
/// bila [wajibAdaSisa], sisa kuota juga harus > 0.
class KalenderBulan extends StatefulWidget {
  const KalenderBulan({
    super.key,
    required this.sisa,
    required this.terpilih,
    required this.onPilih,
    this.wajibAdaSisa = false,
    this.hariIni,
  });

  final Map<DateTime, int> sisa;
  final DateTime? terpilih;
  final ValueChanged<DateTime> onPilih;
  final bool wajibAdaSisa;
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

  DateTime get _akhir {
    if (widget.sisa.isEmpty) return _hariIni.add(const Duration(days: 30));
    return widget.sisa.keys.reduce((a, b) => a.isAfter(b) ? a : b);
  }

  @override
  void initState() {
    super.initState();
    final t = widget.terpilih;
    if (t != null) {
      final i = _bulan.indexWhere((m) => m.year == t.year && m.month == t.month);
      if (i >= 0) _ix = i;
    }
  }

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
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: AppColors.bd),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _ix,
                    isExpanded: true,
                    menuMaxHeight: 360,
                    style: const TextStyle(fontFamily: fontBody, fontSize: 16, color: AppColors.tx),
                    items: [
                      for (var i = 0; i < bulan.length; i++)
                        DropdownMenuItem(value: i, child: Text(fmtBulan(bulan[i]))),
                    ],
                    onChanged: (v) => setState(() => _ix = v ?? _ix),
                  ),
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
                child: Text(h[0],
                    textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: AppColors.mut)),
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
            'Angka kecil = sisa kuota. Slot tersedia sampai ${fmtPendekPanjang(_akhir)}.',
            style: tsCap,
          ),
        ),
      ],
    );
  }

  Widget _sel(DateTime t) {
    final s = widget.sisa[t];
    final setelahHariIni = t.isAfter(_hariIni);
    final ok = setelahHariIni && s != null && (!widget.wajibAdaSisa || s > 0);
    final on = widget.terpilih == t;
    return Opacity(
      opacity: ok ? 1 : 0.35,
      child: Material(
        color: on ? AppColors.pri : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: on ? AppColors.pri : AppColors.bd),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: ok ? () => widget.onPilih(t) : null,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('${t.day}', style: TextStyle(fontSize: 14, height: 1.15, color: on ? Colors.white : AppColors.tx)),
              if (s != null && setelahHariIni)
                Text('$s',
                    style: TextStyle(
                      fontSize: 11,
                      height: 1.15,
                      fontWeight: FontWeight.w600,
                      color: on ? Colors.white : AppColors.ok,
                    )),
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
