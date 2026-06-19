import 'package:flutter/material.dart';

/// Tema de Allegro: Material 3, fondo neutro, acento verde, bordes redondeados
/// moderados y buena legibilidad. Inspirado en interfaces limpias tipo FotMob,
/// sin copiar su marca.
class AppTheme {
  static const Color _seed = Color(0xFF2E7D52); // verde glamping

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  /// Color del borde sutil de los campos (estilo Rappi). Reutilizable por
  /// widgets que imitan un campo (tarjetas de fecha, selects, etc.).
  static Color _fieldBorder(bool isDark) =>
      isDark ? const Color(0xFF2E322F) : const Color(0xFFE6E8E4);

  static Color fieldBorder(BuildContext context) =>
      _fieldBorder(Theme.of(context).brightness == Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(seedColor: _seed, brightness: brightness);
    final isDark = brightness == Brightness.dark;

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: isDark ? const Color(0xFF121413) : const Color(0xFFF6F7F5),
      visualDensity: VisualDensity.standard,
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: isDark ? const Color(0xFF1C1F1D) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        toolbarHeight: 64,
        backgroundColor: isDark ? const Color(0xFF121413) : const Color(0xFFF6F7F5),
        titleTextStyle: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
          color: scheme.onSurface,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 64,
        elevation: 1,
        backgroundColor: isDark ? const Color(0xFF1C1F1D) : Colors.white,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      inputDecorationTheme: InputDecorationTheme(
        // Campos altos, redondeados y blancos con borde muy sutil (estilo Rappi).
        filled: true,
        fillColor: isDark ? const Color(0xFF1C1F1D) : Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        hintStyle: TextStyle(color: scheme.outline, fontWeight: FontWeight.w400),
        prefixIconColor: scheme.outline,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: _fieldBorder(isDark)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: _fieldBorder(isDark)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.primary, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.error, width: 1.8),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      chipTheme: const ChipThemeData(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
      ),
    );
  }
}
