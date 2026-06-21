import 'package:flutter/material.dart';

import '../design/tokens.dart';
import 'buttons.dart';

/// Estado vacío bien diseñado: ícono en círculo suave, título y mensaje.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final Color accent;
  final Widget? action;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.accent = AppColors.forest,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.x8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 42, color: accent),
            ),
            const SizedBox(height: AppSpacing.x5),
            Text(title, textAlign: TextAlign.center, style: t.titleLarge),
            if (message != null) ...[
              const SizedBox(height: AppSpacing.x2),
              Text(message!, textAlign: TextAlign.center, style: t.bodyMedium),
            ],
            if (action != null) ...[
              const SizedBox(height: AppSpacing.x6),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Estado de error amable con reintento.
class ErrorState extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;
  const ErrorState({super.key, required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.x8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                color: AppColors.coral.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.cloud_off_rounded,
                size: 40,
                color: AppColors.coral,
              ),
            ),
            const SizedBox(height: AppSpacing.x5),
            Text(
              'No pudimos cargar los datos',
              textAlign: TextAlign.center,
              style: t.titleLarge,
            ),
            const SizedBox(height: AppSpacing.x2),
            Text('$error', textAlign: TextAlign.center, style: t.bodySmall),
            const SizedBox(height: AppSpacing.x6),
            SecondaryButton(
              label: 'Reintentar',
              icon: Icons.refresh_rounded,
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}

/// Bloque skeleton con un pulso de opacidad muy ligero (un solo controlador
/// por bloque, sin barridos de gradiente que sobrecarguen equipos lentos).
class SkeletonBox extends StatefulWidget {
  final double? width;
  final double height;
  final double radius;
  const SkeletonBox({
    super.key,
    this.width,
    required this.height,
    this.radius = 10,
  });

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDark ? AppColors.darkSurfaceMuted : const Color(0xFFECE9E0);
    return FadeTransition(
      opacity: Tween(begin: 0.55, end: 1.0).animate(_c),
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(widget.radius),
        ),
      ),
    );
  }
}

/// Estado de carga: varias tarjetas skeleton.
class LoadingState extends StatelessWidget {
  final int items;
  const LoadingState({super.key, this.items = 3});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.x5,
        AppSpacing.x4,
        AppSpacing.x5,
        AppSpacing.x5,
      ),
      itemCount: items,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.x3),
      itemBuilder: (_, __) => Container(
        padding: const EdgeInsets.all(AppSpacing.x4),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: AppRadii.all(AppRadii.lg),
          boxShadow: AppShadows.soft,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Row(
              children: [
                SkeletonBox(width: 150, height: 16),
                Spacer(),
                SkeletonBox(width: 70, height: 22, radius: 20),
              ],
            ),
            SizedBox(height: 14),
            SkeletonBox(width: 200, height: 12),
            SizedBox(height: 10),
            SkeletonBox(width: 120, height: 12),
          ],
        ),
      ),
    );
  }
}
