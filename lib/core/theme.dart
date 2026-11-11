import 'package:flutter/material.dart';

/// Token warna mengikuti demo desain yang disetujui
/// (velocity.ai.id/preview/aplikasi-janji-pengobatan-958cad).
class AppColors {
  AppColors._();
  static const pri = Color(0xFF2F5D3A); // hijau utama
  static const priAktif = Color(0xFF244A2E);
  static const gold = Color(0xFFB8892B); // aksen emas
  static const bg = Color(0xFFF7F3EA); // latar krem
  static const card = Colors.white;
  static const tx = Color(0xFF1F2A22);
  static const mut = Color(0xFF5B665E);
  static const bd = Color(0xFFE4DDCD);
  static const wbg = Color(0xFFFFF4D6); // latar peringatan
  static const wtx = Color(0xFF7A5200); // teks peringatan
  static const ok = Color(0xFF2E7D4F);
  static const red = Color(0xFFB3261E);
  static const redBd = Color(0xFFE9B8B3);
  static const wa = Color(0xFF25D366);
  static const krem = Color(0xFFECE6D8); // tab & kotak media
}

const fontBody = 'PlusJakartaSans';
const fontJudul = 'Lora';

/// Gaya judul (Lora).
TextStyle lora(double size, {FontWeight weight = FontWeight.w600, Color? color, double? height}) =>
    TextStyle(fontFamily: fontJudul, fontSize: size, fontWeight: weight, color: color ?? AppColors.tx, height: height);

const tsMut = TextStyle(color: AppColors.mut, fontSize: 14);
const tsCap = TextStyle(color: AppColors.mut, fontSize: 13, fontWeight: FontWeight.w500);

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.pri,
    primary: AppColors.pri,
    surface: AppColors.card,
    error: AppColors.red,
  );
  final base = ThemeData(colorScheme: scheme, fontFamily: fontBody);
  OutlineInputBorder garis(Color c) =>
      OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: c));
  return base.copyWith(
    scaffoldBackgroundColor: AppColors.bg,
    textTheme: base.textTheme.apply(bodyColor: AppColors.tx, displayColor: AppColors.tx),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.pri,
      foregroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: lora(20, color: Colors.white, height: 1.3),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      isDense: true,
      contentPadding: const EdgeInsets.all(12),
      hintStyle: const TextStyle(color: AppColors.mut),
      border: garis(AppColors.bd),
      enabledBorder: garis(AppColors.bd),
      focusedBorder: garis(AppColors.pri),
      errorBorder: garis(AppColors.red),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? AppColors.pri : null),
    ),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    dividerColor: AppColors.bd,
  );
}
