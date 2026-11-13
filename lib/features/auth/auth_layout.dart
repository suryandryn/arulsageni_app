import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../models/models.dart';
import '../../widgets/gambar_klinik.dart';

/// Kerangka halaman Masuk & Daftar Akun: isi berada di tengah layar
/// (vertikal & horizontal), tetap bisa digulir saat keyboard muncul,
/// dan lebarnya dibatasi agar rapi di layar lebar.
class AuthLayout extends StatelessWidget {
  const AuthLayout({super.key, required this.children, this.kembali = false});

  final List<Widget> children;

  /// Tampilkan tombol kembali di pojok kiri atas.
  final bool kembali;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            LayoutBuilder(
              builder: (context, box) => SingleChildScrollView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: box.maxHeight, minWidth: box.maxWidth),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 440),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: children,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (kembali)
              Positioned(
                top: 4,
                left: 4,
                child: IconButton(
                  tooltip: 'Kembali',
                  color: AppColors.pri,
                  icon: const Icon(Icons.chevron_left, size: 32),
                  onPressed: () => Navigator.maybePop(context),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Logo bulat (diatur admin di Atur › Info klinik) + judul + keterangan (.hero).
class AuthHero extends StatelessWidget {
  const AuthHero({super.key, required this.judul, required this.keterangan, this.ukuranFoto = 120});

  final String judul;
  final String keterangan;
  final double ukuranFoto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 0, 6, 20),
      child: Column(
        children: [
          GambarKlinik(JenisGambar.logo, ukuran: ukuranFoto),
          const SizedBox(height: 12),
          Text(judul, textAlign: TextAlign.center, style: lora(26)),
          const SizedBox(height: 8),
          Text(keterangan, textAlign: TextAlign.center, style: tsMut),
        ],
      ),
    );
  }
}

/// Baris "Belum punya akun? Daftar akun" / "Sudah punya akun? Masuk".
class AuthTautan extends StatelessWidget {
  const AuthTautan({super.key, required this.teks, required this.tautan, required this.onTap});

  final String teks;
  final String tautan;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text('$teks ', style: tsMut),
        GestureDetector(
          onTap: onTap,
          child: Text(
            tautan,
            style: const TextStyle(
              color: AppColors.pri,
              fontSize: 14,
              decoration: TextDecoration.underline,
              decorationColor: AppColors.pri,
            ),
          ),
        ),
      ],
    );
  }
}
