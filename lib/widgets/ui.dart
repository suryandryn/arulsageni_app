import 'dart:async';

import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../models/models.dart';

// =============================================================== header

/// Header hijau (header.top di demo): judul Lora + tombol transparan di kanan.
PreferredSizeWidget headerApp(String judul, {List<Widget> aksi = const [], bool kembali = false}) {
  return AppBar(
    automaticallyImplyLeading: kembali,
    // Seperti demo: padding 16 + judul (58) atau tombol 40 (72).
    toolbarHeight: aksi.isEmpty ? 58 : 72,
    titleSpacing: 16,
    title: Text(judul, maxLines: 1, overflow: TextOverflow.ellipsis),
    actions: [
      for (final a in aksi) Padding(padding: const EdgeInsets.only(left: 8), child: a),
      const SizedBox(width: 16),
    ],
  );
}

/// Tombol di header: latar putih 15%, sudut 10, bisa diberi titik angka emas.
class TombolHeader extends StatelessWidget {
  const TombolHeader(this.label, {super.key, required this.onTap, this.badge = 0});

  final String label;
  final VoidCallback onTap;
  final int badge;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Material(
            color: const Color(0x26FFFFFF),
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: onTap,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 40),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(label,
                          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (badge > 0) Positioned(top: -5, right: -5, child: TitikAngka(badge)),
        ],
      ),
    );
  }
}

/// Titik angka emas (.dot).
class TitikAngka extends StatelessWidget {
  const TitikAngka(this.n, {super.key});
  final int n;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 18),
      height: 18,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      alignment: Alignment.center,
      decoration: BoxDecoration(color: AppColors.gold, borderRadius: BorderRadius.circular(99)),
      child: Text('$n', style: const TextStyle(color: Colors.white, fontSize: 11, height: 1)),
    );
  }
}

// =============================================================== nav bawah

class ItemNav {
  const ItemNav(this.label, this.ikon, {this.badge = 0});
  final String label;
  final IconData ikon;
  final int badge;
}

/// Navigasi bawah (nav.bar): putih, garis atas, ikon garis + label 13.
class NavBawah extends StatelessWidget {
  const NavBawah({super.key, required this.items, required this.index, required this.onTap});

  final List<ItemNav> items;
  final int index;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.bd)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            for (var i = 0; i < items.length; i++)
              Expanded(
                child: InkWell(
                  onTap: () => onTap(i),
                  child: Padding(
                    padding: const EdgeInsets.only(top: 9, bottom: 10),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Icon(items[i].ikon, size: 22, color: i == index ? AppColors.pri : AppColors.mut),
                            if (items[i].badge > 0)
                              Positioned(top: -7, right: -14, child: TitikAngka(items[i].badge)),
                          ],
                        ),
                        const SizedBox(height: 2),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            items[i].label,
                            maxLines: 1,
                            style: TextStyle(
                              fontSize: 13,
                              color: i == index ? AppColors.pri : AppColors.mut,
                              fontWeight: i == index ? FontWeight.w700 : FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// =============================================================== kartu & teks

/// Kartu (.card): putih, garis krem, sudut 16, padding 16, jarak bawah 12.
class Kartu extends StatelessWidget {
  const Kartu({super.key, required this.child, this.onTap, this.padding = const EdgeInsets.all(16)});

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final isi = Padding(padding: padding, child: child);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.bd),
        ),
        clipBehavior: Clip.antiAlias,
        child: onTap == null ? isi : InkWell(onTap: onTap, child: isi),
      ),
    );
  }
}

/// Judul kartu (.card h3): Lora 18.
class JudulKartu extends StatelessWidget {
  const JudulKartu(this.teks, {super.key, this.bawah = 6});
  final String teks;
  final double bawah;

  @override
  Widget build(BuildContext context) =>
      Padding(padding: EdgeInsets.only(bottom: bawah), child: Text(teks, style: lora(18)));
}

/// Label isian (label): tebal 14, jarak atas 14.
class Label extends StatelessWidget {
  const Label(this.teks, {super.key, this.atas = 14});
  final String teks;
  final double atas;

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(top: atas, bottom: 6),
        child: Text(teks, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      );
}

/// Baris kiri-kanan (.row).
class Baris extends StatelessWidget {
  const Baris({super.key, required this.kiri, required this.kanan});
  final Widget kiri;
  final Widget kanan;

  @override
  Widget build(BuildContext context) => Row(
        children: [Expanded(child: kiri), const SizedBox(width: 8), kanan],
      );
}

// =============================================================== tombol

enum Varian { primer, garis, merah, wa, putih }

/// Tombol (.btn): lebar penuh, sudut 10, tinggi min 48. `kecil` = .btn.s.
class Tombol extends StatelessWidget {
  const Tombol(
    this.label, {
    super.key,
    required this.onPressed,
    this.varian = Varian.primer,
    this.kecil = false,
    this.atas = 10,
    this.memuat = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final Varian varian;
  final bool kecil;
  final double atas;
  final bool memuat;

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color fg, Color? garis) = switch (varian) {
      Varian.primer => (AppColors.pri, Colors.white, null),
      Varian.garis => (Colors.white, AppColors.pri, AppColors.pri),
      Varian.merah => (Colors.white, AppColors.red, AppColors.redBd),
      Varian.wa => (AppColors.wa, AppColors.tx, null),
      Varian.putih => (Colors.white, AppColors.pri, null),
    };
    final tombol = FilledButton(
      onPressed: memuat ? null : onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: bg,
        foregroundColor: fg,
        disabledBackgroundColor: bg.withValues(alpha: 0.6),
        disabledForegroundColor: fg.withValues(alpha: 0.7),
        overlayColor: varian == Varian.primer ? AppColors.priAktif : null,
        minimumSize: Size(kecil ? 0 : double.infinity, kecil ? 40 : 48),
        padding: kecil
            ? const EdgeInsets.symmetric(horizontal: 14, vertical: 9)
            : const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        side: garis == null ? null : BorderSide(color: garis),
        textStyle: TextStyle(fontFamily: fontBody, fontSize: kecil ? 14 : 16, fontWeight: FontWeight.w600),
        elevation: 0,
      ),
      child: memuat
          ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: fg))
          : Text(label, textAlign: TextAlign.center),
    );
    return Padding(padding: EdgeInsets.only(top: kecil ? 6 : atas), child: tombol);
  }
}

// =============================================================== tag & pil

/// Label status (.tag).
class Tag extends StatelessWidget {
  const Tag(this.teks, {super.key, required this.bg, required this.fg});

  factory Tag.status(StatusPendaftaran s) {
    final (bg, fg) = warnaStatus(s);
    return Tag(s.label, bg: bg, fg: fg);
  }

  factory Tag.aktif(bool aktif) {
    final (bg, fg) = warnaStatus(aktif ? StatusPendaftaran.dijadwalkan : StatusPendaftaran.batal);
    return Tag(aktif ? 'Aktif' : 'Nonaktif', bg: bg, fg: fg);
  }

  final String teks;
  final Color bg;
  final Color fg;

  static (Color, Color) warnaStatus(StatusPendaftaran s) => switch (s) {
        StatusPendaftaran.menunggu => (const Color(0xFFF6ECD6), AppColors.wtx),
        StatusPendaftaran.dijadwalkan => (const Color(0xFFE2F0E7), AppColors.ok),
        StatusPendaftaran.ditolak => (const Color(0xFFFBE4E2), AppColors.red),
        _ => (const Color(0xFFECEBE6), const Color(0xFF4B524D)),
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(99)),
      child: Text(teks, style: TextStyle(color: fg, fontSize: 13, fontWeight: FontWeight.w600)),
    );
  }
}

/// Pil pilihan (.chip); `aktif` = .chip.on, `nonaktif` = redup & tak bisa diketuk.
class Pil extends StatelessWidget {
  const Pil(this.label, {super.key, this.onTap, this.aktif = false, this.nonaktif = false});

  final String label;
  final VoidCallback? onTap;
  final bool aktif;
  final bool nonaktif;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: nonaktif ? 0.35 : 1,
      child: Material(
        color: aktif ? AppColors.pri : Colors.white,
        shape: StadiumBorder(side: BorderSide(color: aktif ? AppColors.pri : AppColors.bd)),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: nonaktif ? null : onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 40),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label, style: TextStyle(fontSize: 14, color: aktif ? Colors.white : AppColors.tx)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class DeretPil extends StatelessWidget {
  const DeretPil({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Wrap(spacing: 6, runSpacing: 6, children: children),
      );
}

// =============================================================== lain-lain

/// Kotak peringatan kuning (.warn).
class KotakPeringatan extends StatelessWidget {
  const KotakPeringatan({super.key, required this.child, this.ikon = Icons.verified_user_outlined});
  final Widget child;
  final IconData ikon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.wbg, borderRadius: BorderRadius.circular(10)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(ikon, size: 22, color: AppColors.wtx),
          const SizedBox(width: 10),
          Expanded(
            child: DefaultTextStyle.merge(style: const TextStyle(color: AppColors.wtx, fontSize: 14), child: child),
          ),
        ],
      ),
    );
  }
}

/// Baris tautan (.sos): ikon hijau, nama + keterangan kecil, ikon keluar.
class BarisTautan extends StatelessWidget {
  const BarisTautan({super.key, required this.ikon, required this.judul, required this.sub, required this.onTap});
  final IconData ikon;
  final String judul;
  final String sub;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: AppColors.bd),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(ikon, color: AppColors.pri, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(judul, style: const TextStyle(height: 1.3)),
                      Text(sub, style: const TextStyle(color: AppColors.mut, fontSize: 13, height: 1.3)),
                    ],
                  ),
                ),
                const Icon(Icons.north_east, color: AppColors.pri, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Teks kosong (p.mut).
class TeksKosong extends StatelessWidget {
  const TeksKosong(this.teks, {super.key});
  final String teks;

  @override
  Widget build(BuildContext context) =>
      Padding(padding: const EdgeInsets.symmetric(vertical: 14), child: Text(teks, style: tsMut));
}

Future<bool> konfirmasi(BuildContext context, String pesan) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      content: Text(pesan),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
        TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Ya')),
      ],
    ),
  );
  return ok ?? false;
}

// =============================================================== toast atas

OverlayEntry? _toastAktif;

/// Pemberitahuan meluncur dari atas (#push di demo), hilang setelah 3,8 detik.
void toast(BuildContext context, String judul, String isi) {
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return;
  _toastAktif?.remove();
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _Toast(
      judul: judul,
      isi: isi,
      selesai: () {
        if (_toastAktif == entry) _toastAktif = null;
        if (entry.mounted) entry.remove();
      },
    ),
  );
  _toastAktif = entry;
  overlay.insert(entry);
}

class _Toast extends StatefulWidget {
  const _Toast({required this.judul, required this.isi, required this.selesai});
  final String judul;
  final String isi;
  final VoidCallback selesai;

  @override
  State<_Toast> createState() => _ToastState();
}

class _ToastState extends State<_Toast> {
  bool _tampil = false;
  Timer? _t;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _tampil = true);
    });
    _t = Timer(const Duration(milliseconds: 3800), _tutup);
  }

  void _tutup() {
    if (!mounted) return;
    setState(() => _tampil = false);
    _t = Timer(const Duration(milliseconds: 350), widget.selesai);
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final atas = MediaQuery.paddingOf(context).top + 12;
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
      left: 10,
      right: 10,
      top: _tampil ? atas : -140,
      child: GestureDetector(
        onTap: _tutup,
        child: Material(
          color: Colors.white,
          elevation: 8,
          shadowColor: Colors.black45,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.judul,
                    style: const TextStyle(color: AppColors.pri, fontWeight: FontWeight.w700, fontSize: 14)),
                Text(widget.isi, style: const TextStyle(fontSize: 14, color: AppColors.tx)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
