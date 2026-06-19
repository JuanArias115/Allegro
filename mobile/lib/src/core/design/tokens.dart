import 'package:flutter/material.dart';

/// Paleta de Allegro — naturaleza, descanso y hospitalidad.
class AppColors {
  AppColors._();

  static const forest = Color(0xFF145A41); // verde bosque (acento principal)
  static const forestDark = Color(0xFF0E4231);
  static const mint = Color(0xFFDDF4E8); // verde menta (fondos suaves)
  static const cream = Color(0xFFF7F4ED); // crema (fondo de la app)
  static const coral = Color(0xFFFF6B4A);
  static const yellow = Color(0xFFF4C95D);
  static const blue = Color(0xFF4E7CF0);
  static const violet = Color(0xFF8B5CF6); // reservas futuras
  static const red = Color(0xFFE2483D); // error / vencido real

  static const textPrimary = Color(0xFF18201C);
  static const textSecondary = Color(0xFF68736C);
  static const white = Color(0xFFFFFFFF);

  // Superficies
  static const surface = white;
  static const surfaceMuted = Color(0xFFF0EEE6); // crema un poco más oscura
  static const hairline = Color(0xFFEDEAE1); // separadores casi invisibles

  // Modo oscuro
  static const darkBg = Color(0xFF11150F);
  static const darkSurface = Color(0xFF1A1F19);
  static const darkSurfaceMuted = Color(0xFF222820);

  /// Fondo suave (12% aprox.) para chips/íconos de un color de acento.
  static Color soft(Color c) => Color.alphaBlend(c.withValues(alpha: 0.14), cream);
}

/// Espaciado en una cuadrícula de 4 px.
class AppSpacing {
  AppSpacing._();
  static const double x1 = 4;
  static const double x2 = 8;
  static const double x3 = 12;
  static const double x4 = 16;
  static const double x5 = 20; // margen horizontal estándar
  static const double x6 = 24;
  static const double x7 = 28;
  static const double x8 = 32;

  /// Margen horizontal estándar de las pantallas.
  static const EdgeInsets screenH = EdgeInsets.symmetric(horizontal: x5);
}

class AppRadii {
  AppRadii._();
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double pill = 999;

  static BorderRadius all(double r) => BorderRadius.circular(r);
}

/// Sombras muy suaves (sin bordes grises visibles).
class AppShadows {
  AppShadows._();

  static List<BoxShadow> get card => const [
        BoxShadow(
          color: Color(0x0F18201C), // ~6% negro
          blurRadius: 18,
          offset: Offset(0, 6),
        ),
      ];

  static List<BoxShadow> get soft => const [
        BoxShadow(
          color: Color(0x0A18201C), // ~4%
          blurRadius: 12,
          offset: Offset(0, 4),
        ),
      ];

  static List<BoxShadow> floating(Color tint) => [
        BoxShadow(
          color: tint.withValues(alpha: 0.28),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ];
}

class AppDurations {
  AppDurations._();
  static const fast = Duration(milliseconds: 180);
  static const normal = Duration(milliseconds: 260);
}
