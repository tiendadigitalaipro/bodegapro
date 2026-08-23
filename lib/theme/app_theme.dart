import 'package:flutter/material.dart';

/// Identidad "bodega industrial": índigo/navy con acento verde lima neón,
/// distinta de BarberFlow (dorado), ZYNC (cian), Mercado Logic Pro
/// (terracota), Nail Studio Pro (fucsia) y Frutería Pro (naranja/verde).
class AppColors {
  static const indigo = Color(0xFF3D4FE0);
  static const indigoDim = Color(0xFF2A38A8);
  static const lime = Color(0xFFC6FF00);
  static const limeDim = Color(0xFF9BCC00);
  static const background = Color(0xFF0A0D1C);
  static const surface = Color(0xFF11162A);
  static const surfaceLight = Color(0xFF1A2140);
}

class AppTheme {
  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.indigo,
        secondary: AppColors.lime,
        surface: AppColors.surface,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.indigo,
        elevation: 0,
        centerTitle: false,
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: AppColors.surface,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceLight,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.indigo,
        foregroundColor: Colors.white,
      ),
      fontFamily: 'Roboto',
    );
  }
}
