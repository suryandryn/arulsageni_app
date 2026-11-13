import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Logo WhatsApp (simple-icons, CC0) dari `assets/icons/whatsapp.svg`.
class IkonWhatsApp extends StatelessWidget {
  const IkonWhatsApp({super.key, this.ukuran = 24, this.warna = const Color(0xFF25D366)});

  final double ukuran;
  final Color warna;

  @override
  Widget build(BuildContext context) => SvgPicture.asset(
    'assets/icons/whatsapp.svg',
    width: ukuran,
    height: ukuran,
    colorFilter: ColorFilter.mode(warna, BlendMode.srcIn),
    semanticsLabel: 'WhatsApp',
  );
}
