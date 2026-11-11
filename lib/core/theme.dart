import 'package:flutter/material.dart';

/// Warna utama hijau & putih (sementara, final menyesuaikan logo klinik).
class AppColors {
  AppColors._();
  static const hijau = Color(0xFF1E7D4F);
  static const hijauTua = Color(0xFF145A39);
  static const hijauMuda = Color(0xFFE6F3EC);
  static const latar = Color(0xFFF5F8F6);
  static const garis = Color(0xFFE0E8E3);
}

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.hijau,
    primary: AppColors.hijau,
    surface: Colors.white,
  );
  final radius = BorderRadius.circular(12);
  return ThemeData(
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.latar,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.hijau,
      foregroundColor: Colors.white,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.garis),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: radius),
      enabledBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: const BorderSide(color: AppColors.garis),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: radius),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 44),
        shape: RoundedRectangleBorder(borderRadius: radius),
      ),
    ),
    navigationBarTheme: const NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: AppColors.hijauMuda,
    ),
  );
}
