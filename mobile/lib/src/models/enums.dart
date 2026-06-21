import 'package:flutter/material.dart';

/// Estados de reserva. Los nombres coinciden con los del backend (JSON por nombre).
enum ReservationStatus {
  confirmed('Confirmed', 'Confirmada'),
  checkedIn('CheckedIn', 'Hospedada'),
  completed('Completed', 'Finalizada'),
  cancelled('Cancelled', 'Cancelada');

  const ReservationStatus(this.wire, this.label);
  final String wire;
  final String label;

  static ReservationStatus fromWire(String v) => values.firstWhere(
    (e) => e.wire == v,
    orElse: () => ReservationStatus.confirmed,
  );

  bool get isActive =>
      this == ReservationStatus.confirmed ||
      this == ReservationStatus.checkedIn;
}

enum PaymentMethod {
  cash('Cash', 'Efectivo'),
  transfer('Transfer', 'Transferencia'),
  other('Other', 'Otro');

  const PaymentMethod(this.wire, this.label);
  final String wire;
  final String label;

  static PaymentMethod fromWire(String v) =>
      values.firstWhere((e) => e.wire == v, orElse: () => PaymentMethod.cash);
}

// Las categorías de producto ya no son un enum: ahora son dinámicas y vienen del
// backend (ver models/product_category.dart y GET /api/product-categories).

/// Color suave asociado a cada estado (etiquetas pequeñas).
extension ReservationStatusColors on ReservationStatus {
  Color color(ColorScheme scheme) => switch (this) {
    ReservationStatus.confirmed => const Color(0xFF2E7D52),
    ReservationStatus.checkedIn => const Color(0xFF1565C0),
    ReservationStatus.completed => const Color(0xFF616161),
    ReservationStatus.cancelled => const Color(0xFFB3261E),
  };
}
