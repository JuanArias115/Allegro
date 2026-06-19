import 'package:flutter/material.dart';

import 'design/tokens.dart';

/// Tema de Allegro: Material 3 totalmente personalizado, tipografía Manrope,
/// paleta natural y superficies cálidas. Centraliza color, tipografía, radios
/// y formas; los componentes del sistema de diseño consumen estos valores.
class AppTheme {
  AppTheme._();

  static const String _font = 'Manrope';

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.forest,
      brightness: brightness,
    ).copyWith(
      primary: AppColors.forest,
      onPrimary: AppColors.white,
      secondary: AppColors.coral,
      surface: isDark ? AppColors.darkSurface : AppColors.surface,
      onSurface: isDark ? const Color(0xFFEDF1EA) : AppColors.textPrimary,
      surfaceContainerHighest: isDark ? AppColors.darkSurfaceMuted : AppColors.surfaceMuted,
      error: AppColors.red,
      outline: isDark ? const Color(0xFF8A958C) : AppColors.textSecondary,
      outlineVariant: isDark ? const Color(0xFF2E342C) : AppColors.hairline,
    );

    final bg = isDark ? AppColors.darkBg : AppColors.cream;
    final onSurface = scheme.onSurface;
    final secondaryText = isDark ? const Color(0xFF9AA69D) : AppColors.textSecondary;

    final text = TextTheme(
      displaySmall: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: -0.6, color: onSurface),
      headlineMedium: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.5, color: onSurface),
      headlineSmall: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: -0.3, color: onSurface),
      titleLarge: TextStyle(fontSize: 19, fontWeight: FontWeight.w700, letterSpacing: -0.2, color: onSurface),
      titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: onSurface),
      titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: onSurface),
      bodyLarge: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w500, color: onSurface, height: 1.35),
      bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: secondaryText, height: 1.35),
      bodySmall: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500, color: secondaryText, height: 1.3),
      labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: onSurface),
      labelMedium: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: secondaryText),
    ).apply(fontFamily: _font);

    return ThemeData(
      useMaterial3: true,
      fontFamily: _font,
      colorScheme: scheme,
      scaffoldBackgroundColor: bg,
      canvasColor: bg,
      textTheme: text,
      splashFactory: InkSparkle.splashFactory,
      visualDensity: VisualDensity.standard,
      dividerTheme: DividerThemeData(color: scheme.outlineVariant, thickness: 1, space: 1),
      iconTheme: IconThemeData(color: onSurface),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: scheme.surface,
        shape: RoundedRectangleBorder(borderRadius: AppRadii.all(AppRadii.lg)),
      ),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: bg,
        foregroundColor: onSurface,
        titleTextStyle: text.headlineSmall,
      ),
      // Fondo de campos: tinte muy suave, sin bordes grises; foco verde claro.
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? AppColors.darkSurfaceMuted : AppColors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: TextStyle(color: secondaryText, fontWeight: FontWeight.w500),
        prefixIconColor: secondaryText,
        suffixIconColor: secondaryText,
        floatingLabelBehavior: FloatingLabelBehavior.never,
        border: _inputBorder(Colors.transparent),
        enabledBorder: _inputBorder(Colors.transparent),
        focusedBorder: _inputBorder(scheme.primary, 1.8),
        errorBorder: _inputBorder(scheme.error, 1.4),
        focusedErrorBorder: _inputBorder(scheme.error, 1.8),
        errorStyle: TextStyle(color: scheme.error, fontWeight: FontWeight.w600, fontSize: 12.5),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          minimumSize: const Size.fromHeight(54),
          textStyle: text.labelLarge?.copyWith(fontSize: 15.5),
          shape: RoundedRectangleBorder(borderRadius: AppRadii.all(AppRadii.md)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.textPrimary,
        contentTextStyle: const TextStyle(color: AppColors.white, fontFamily: _font, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: AppRadii.all(AppRadii.md)),
        insetPadding: const EdgeInsets.all(AppSpacing.x4),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.xl)),
        ),
      ),
      chipTheme: const ChipThemeData(padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4)),
    );
  }

  static OutlineInputBorder _inputBorder(Color color, [double width = 1]) => OutlineInputBorder(
        borderRadius: AppRadii.all(AppRadii.md),
        borderSide: BorderSide(color: color, width: width),
      );
}
