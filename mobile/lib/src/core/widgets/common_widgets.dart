import 'package:flutter/material.dart';

import '../../models/enums.dart';

/// Etiqueta pequeña de estado (color suave según el estado).
class StatusChip extends StatelessWidget {
  final ReservationStatus status;
  const StatusChip(this.status, {super.key});

  @override
  Widget build(BuildContext context) {
    final color = status.color(Theme.of(context).colorScheme);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.label,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}

/// Pequeña marca de color para identificar un domo.
class DomeDot extends StatelessWidget {
  final int index;
  const DomeDot(this.index, {super.key});

  static const List<Color> palette = [
    Color(0xFF2E7D52),
    Color(0xFF8E5BB5),
    Color(0xFFC97B2C),
    Color(0xFF1565C0),
  ];

  static Color colorFor(int index) => palette[index % palette.length];

  @override
  Widget build(BuildContext context) => Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(color: colorFor(index), shape: BoxShape.circle),
      );
}

/// Estado vacío claro y discreto.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 56, color: scheme.outline),
            const SizedBox(height: 16),
            Text(title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium),
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(message!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: scheme.outline)),
            ],
            if (action != null) ...[const SizedBox(height: 20), action!],
          ],
        ),
      ),
    );
  }
}

/// Vista de error con opción de reintentar.
class ErrorRetry extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;
  const ErrorRetry({super.key, required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off_rounded,
                size: 56, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 16),
            Text('No se pudieron cargar los datos',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('$error',
                textAlign: TextAlign.center,
                style: TextStyle(color: Theme.of(context).colorScheme.outline)),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Encabezado de sección compacto.
class SectionHeader extends StatelessWidget {
  final String title;
  final String? trailing;
  const SectionHeader(this.title, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
      child: Row(
        children: [
          Text(title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const Spacer(),
          if (trailing != null)
            Text(trailing!,
                style: TextStyle(color: Theme.of(context).colorScheme.outline)),
        ],
      ),
    );
  }
}
