import 'enums.dart';
import 'reservation.dart';

class CheckoutSummary {
  final String reservationId;
  final String guestName;
  final String domeName;
  final DateTime checkIn;
  final DateTime checkOut;
  final double lodgingPrice;
  final List<Consumption> consumptions;
  final double totalConsumptions;
  final double totalDue;
  final double totalPaid;
  final double balance;
  final ReservationStatus status;

  const CheckoutSummary({
    required this.reservationId,
    required this.guestName,
    required this.domeName,
    required this.checkIn,
    required this.checkOut,
    required this.lodgingPrice,
    required this.consumptions,
    required this.totalConsumptions,
    required this.totalDue,
    required this.totalPaid,
    required this.balance,
    required this.status,
  });

  factory CheckoutSummary.fromJson(Map<String, dynamic> j) => CheckoutSummary(
    reservationId: j['reservationId'] as String,
    guestName: j['guestName'] as String,
    domeName: (j['domeName'] as String?) ?? '',
    checkIn: DateTime.parse(j['checkIn'] as String),
    checkOut: DateTime.parse(j['checkOut'] as String),
    lodgingPrice: (j['lodgingPrice'] as num).toDouble(),
    consumptions: (j['consumptions'] as List<dynamic>)
        .map((e) => Consumption.fromJson(e as Map<String, dynamic>))
        .toList(),
    totalConsumptions: (j['totalConsumptions'] as num).toDouble(),
    totalDue: (j['totalDue'] as num).toDouble(),
    totalPaid: (j['totalPaid'] as num).toDouble(),
    balance: (j['balance'] as num).toDouble(),
    status: ReservationStatus.fromWire(j['status'] as String),
  );
}
