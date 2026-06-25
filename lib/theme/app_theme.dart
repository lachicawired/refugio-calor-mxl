import 'package:flutter/material.dart';

class AppTheme {
  static const Color heat = Color(0xFFE4552F);
  static const Color water = Color(0xFF087EA4);
  static const Color refuge = Color(0xFF2E7D59);
  static const Color sand = Color(0xFFFFF3D8);
  static const Color night = Color(0xFF101820);

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: refuge,
      brightness: Brightness.light,
      primary: refuge,
      secondary: water,
      tertiary: heat,
      surface: const Color(0xFFFFFBF4),
    );

    return _base(scheme).copyWith(
      scaffoldBackgroundColor: const Color(0xFFFFFBF4),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: heat,
        foregroundColor: Colors.white,
        elevation: 0,
        titleTextStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    );
  }

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: water,
      brightness: Brightness.dark,
      primary: const Color(0xFF65C18C),
      secondary: const Color(0xFF6ED6F2),
      tertiary: const Color(0xFFFF9A76),
      surface: night,
    );

    return _base(scheme).copyWith(
      scaffoldBackgroundColor: const Color(0xFF0B1117),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: const Color(0xFF16232D),
        foregroundColor: scheme.onSurface,
        elevation: 0,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: scheme.onSurface,
        ),
      ),
    );
  }

  static ThemeData _base(ColorScheme scheme) {
    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
    );

    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      visualDensity: VisualDensity.standard,
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        selectedColor: scheme.secondaryContainer,
        labelStyle: TextStyle(color: scheme.onSurface),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.tertiary,
        foregroundColor: scheme.onTertiary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: inputBorder,
        enabledBorder: inputBorder,
        filled: true,
        fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}
