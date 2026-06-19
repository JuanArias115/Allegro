import 'package:flutter/material.dart';

import '../../models/enums.dart';
import '../../models/reservation.dart';
import '../design/tokens.dart';
import '../formatters.dart';
import 'status_badge.dart';

/// Color distintivo y accesible por domo (orden estable).
Color domeColor(int index) {
  const palette = [AppColors.blue, AppColors.coral, AppColors.violet, AppColors.yellow];
  return palette[index % palette.length];
}

Color categoryColor(ProductCategory c) => switch (c) {
      ProductCategory.beverages => AppColors.blue,
      ProductCategory.food => AppColors.yellow,
      ProductCategory.services => AppColors.coral,
      ProductCategory.other => AppColors.forest,
    };

IconData categoryIcon(ProductCategory c) => switch (c) {
      ProductCategory.beverages => Icons.local_bar_rounded,
      ProductCategory.food => Icons.restaurant_rounded,
      ProductCategory.services => Icons.room_service_rounded,
      ProductCategory.other => Icons.category_rounded,
    };

/// Ícono en contenedor de color suave (categorías, indicadores, secciones).
class CategoryIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;

  const CategoryIcon({super.key, required this.icon, required this.color, this.size = 44});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: AppRadii.all(size >= 44 ? AppRadii.sm : 10),
      ),
      child: Icon(icon, size: size * 0.5, color: color),
    );
  }
}

/// Tarjeta blanca base con sombra muy suave (sin bordes grises).
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.x4),
    this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color ?? Theme.of(context).colorScheme.surface,
        borderRadius: AppRadii.all(AppRadii.lg),
        boxShadow: AppShadows.soft,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadii.all(AppRadii.lg),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// Tarjeta destacada de resumen (ocupación) con fondo de color y texto claro.
class SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final Widget? trailing;
  final Color color;

  const SummaryCard({
    super.key,
    required this.title,
    required this.value,
    required this.subtitle,
    this.trailing,
    this.color = AppColors.forest,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: AppRadii.all(AppRadii.xl),
        boxShadow: AppShadows.floating(color),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 13.5, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Text(value,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 30, fontWeight: FontWeight.w800, height: 1.05)),
                const SizedBox(height: 4),
                Text(subtitle,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Indicador pequeño: ícono de color + número + etiqueta.
class MiniStat extends StatelessWidget {
  final IconData icon;
  final Color color;
  final int count;
  final String label;
  final VoidCallback? onTap;

  const MiniStat({
    super.key,
    required this.icon,
    required this.color,
    required this.count,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CategoryIcon(icon: icon, color: color, size: 36),
          const SizedBox(height: 10),
          Text('$count',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, height: 1)),
          const SizedBox(height: 2),
          Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

/// Tarjeta de reserva con acento lateral por estado y jerarquía clara.
class ReservationCard extends StatelessWidget {
  final ReservationSummary reservation;
  final VoidCallback onTap;

  const ReservationCard({super.key, required this.reservation, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final r = reservation;
    final scheme = Theme.of(context).colorScheme;
    final accent = reservationStatusColor(r.status);
    final payState = paymentStateOf(r.balance, r.checkOut, DateTime.now());
    final payColor = paymentColor(payState);
    final payLabel = switch (payState) {
      PaymentState.paid => 'Pagado',
      PaymentState.pending => 'Saldo ${Formatters.money(r.balance)}',
      PaymentState.overdue => 'Vencido ${Formatters.money(r.balance)}',
    };

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: AppRadii.all(AppRadii.lg),
        boxShadow: AppShadows.soft,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadii.all(AppRadii.lg),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 5,
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: const BorderRadius.horizontal(left: Radius.circular(AppRadii.lg)),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(r.guestName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.titleMedium),
                            ),
                            const SizedBox(width: 8),
                            StatusBadge.reservation(r.status, dense: true),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 14,
                          runSpacing: 6,
                          children: [
                            _meta(context, Icons.cabin_rounded, r.domeName),
                            _meta(context, Icons.calendar_today_rounded,
                                Formatters.dateRange(r.checkIn, r.checkOut)),
                            _meta(context, Icons.person_rounded, '${r.guestCount}'),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(
                              payState == PaymentState.paid
                                  ? Icons.check_circle_rounded
                                  : Icons.account_balance_wallet_rounded,
                              size: 15,
                              color: payColor,
                            ),
                            const SizedBox(width: 6),
                            Text(payLabel,
                                style: TextStyle(
                                    color: payColor, fontWeight: FontWeight.w700, fontSize: 13.5)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _meta(BuildContext context, IconData icon, String text) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: scheme.outline),
        const SizedBox(width: 5),
        Text(text, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

/// Animación discreta de aparición (fade + leve subida), con retraso por índice.
class AppearAnimation extends StatelessWidget {
  final int index;
  final Widget child;
  const AppearAnimation({super.key, this.index = 0, required this.child});

  @override
  Widget build(BuildContext context) {
    final delay = (index.clamp(0, 8)) * 45;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 320 + delay),
      curve: Curves.easeOutCubic,
      builder: (context, v, child) => Opacity(
        opacity: v.clamp(0, 1),
        child: Transform.translate(offset: Offset(0, (1 - v) * 12), child: child),
      ),
      child: child,
    );
  }
}
