import 'package:flutter/material.dart';

import '../../models/enums.dart';
import '../design/tokens.dart';

/// Color semántico por estado de reserva (no solo verde):
/// violeta = futura, azul = alojada, verde = finalizada, gris = cancelada.
Color reservationStatusColor(ReservationStatus s) => switch (s) {
  ReservationStatus.confirmed => AppColors.violet,
  ReservationStatus.checkedIn => AppColors.blue,
  ReservationStatus.completed => AppColors.forest,
  ReservationStatus.cancelled => AppColors.textSecondary,
};

IconData reservationStatusIcon(ReservationStatus s) => switch (s) {
  ReservationStatus.confirmed => Icons.event_available_rounded,
  ReservationStatus.checkedIn => Icons.cabin_rounded,
  ReservationStatus.completed => Icons.check_circle_rounded,
  ReservationStatus.cancelled => Icons.cancel_rounded,
};

/// Estado de pago. Vencido = saldo pendiente y la salida ya pasó.
enum PaymentState { paid, pending, overdue }

PaymentState paymentStateOf(double balance, DateTime checkOut, DateTime today) {
  if (balance <= 0) return PaymentState.paid;
  final out = DateTime(checkOut.year, checkOut.month, checkOut.day);
  final t = DateTime(today.year, today.month, today.day);
  return out.isBefore(t) ? PaymentState.overdue : PaymentState.pending;
}

Color paymentColor(PaymentState s) => switch (s) {
  PaymentState.paid => AppColors.forest,
  PaymentState.pending => AppColors.coral,
  PaymentState.overdue => AppColors.red,
};

/// Etiqueta pequeña de estado con ícono — no depende solo del color.
class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  final bool dense;

  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
    this.icon,
    this.dense = false,
  });

  factory StatusBadge.reservation(
    ReservationStatus status, {
    bool dense = false,
  }) => StatusBadge(
    label: status.label,
    color: reservationStatusColor(status),
    icon: reservationStatusIcon(status),
    dense: dense,
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 8 : 10,
        vertical: dense ? 4 : 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: AppRadii.all(AppRadii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: dense ? 13 : 14, color: color),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: dense ? 11.5 : 12.5,
              fontWeight: FontWeight.w700,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}
