import 'enums.dart';

DateTime _date(String s) => DateTime.parse(s);
String _fmtDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

class Payment {
  final String id;
  final double amount;
  final DateTime paidAt;
  final PaymentMethod method;
  final String? note;

  const Payment({
    required this.id,
    required this.amount,
    required this.paidAt,
    required this.method,
    this.note,
  });

  factory Payment.fromJson(Map<String, dynamic> j) => Payment(
    id: j['id'] as String,
    amount: (j['amount'] as num).toDouble(),
    paidAt: _date(j['paidAt'] as String),
    method: PaymentMethod.fromWire(j['method'] as String),
    note: j['note'] as String?,
  );
}

class Consumption {
  final String id;
  final String productId;
  final String productName;
  final int quantity;
  final double unitPrice;
  final double subtotal;
  final DateTime consumedAt;

  const Consumption({
    required this.id,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
    required this.consumedAt,
  });

  factory Consumption.fromJson(Map<String, dynamic> j) => Consumption(
    id: j['id'] as String,
    productId: j['productId'] as String,
    productName: j['productName'] as String,
    quantity: j['quantity'] as int,
    unitPrice: (j['unitPrice'] as num).toDouble(),
    subtotal: (j['subtotal'] as num).toDouble(),
    consumedAt: _date(j['consumedAt'] as String),
  );
}

/// Resumen para listados (Hoy, Calendario, Historial).
class ReservationSummary {
  final String id;
  final String guestName;
  final String phone;
  final String domeId;
  final String domeName;
  final DateTime checkIn;
  final DateTime checkOut;
  final int guestCount;
  final ReservationStatus status;
  final double lodgingPrice;
  final double totalConsumptions;
  final double totalPaid;
  final double balance;

  const ReservationSummary({
    required this.id,
    required this.guestName,
    required this.phone,
    required this.domeId,
    required this.domeName,
    required this.checkIn,
    required this.checkOut,
    required this.guestCount,
    required this.status,
    required this.lodgingPrice,
    required this.totalConsumptions,
    required this.totalPaid,
    required this.balance,
  });

  factory ReservationSummary.fromJson(Map<String, dynamic> j) =>
      ReservationSummary(
        id: j['id'] as String,
        guestName: j['guestName'] as String,
        phone: j['phone'] as String,
        domeId: j['domeId'] as String,
        domeName: (j['domeName'] as String?) ?? '',
        checkIn: _date(j['checkIn'] as String),
        checkOut: _date(j['checkOut'] as String),
        guestCount: j['guestCount'] as int,
        status: ReservationStatus.fromWire(j['status'] as String),
        lodgingPrice: (j['lodgingPrice'] as num).toDouble(),
        totalConsumptions: (j['totalConsumptions'] as num).toDouble(),
        totalPaid: (j['totalPaid'] as num).toDouble(),
        balance: (j['balance'] as num).toDouble(),
      );
}

/// Detalle completo de una reserva.
class Reservation {
  final String id;
  final String guestName;
  final String phone;
  final String domeId;
  final String domeName;
  final DateTime checkIn;
  final DateTime checkOut;
  final int guestCount;
  final double lodgingPrice;
  final ReservationStatus status;
  final String? notes;
  final double totalConsumptions;
  final double totalDue;
  final double totalPaid;
  final double balance;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<Payment> payments;
  final List<Consumption> consumptions;

  const Reservation({
    required this.id,
    required this.guestName,
    required this.phone,
    required this.domeId,
    required this.domeName,
    required this.checkIn,
    required this.checkOut,
    required this.guestCount,
    required this.lodgingPrice,
    required this.status,
    required this.notes,
    required this.totalConsumptions,
    required this.totalDue,
    required this.totalPaid,
    required this.balance,
    required this.createdAt,
    required this.updatedAt,
    required this.payments,
    required this.consumptions,
  });

  factory Reservation.fromJson(Map<String, dynamic> j) => Reservation(
    id: j['id'] as String,
    guestName: j['guestName'] as String,
    phone: j['phone'] as String,
    domeId: j['domeId'] as String,
    domeName: (j['domeName'] as String?) ?? '',
    checkIn: _date(j['checkIn'] as String),
    checkOut: _date(j['checkOut'] as String),
    guestCount: j['guestCount'] as int,
    lodgingPrice: (j['lodgingPrice'] as num).toDouble(),
    status: ReservationStatus.fromWire(j['status'] as String),
    notes: j['notes'] as String?,
    totalConsumptions: (j['totalConsumptions'] as num).toDouble(),
    totalDue: (j['totalDue'] as num).toDouble(),
    totalPaid: (j['totalPaid'] as num).toDouble(),
    balance: (j['balance'] as num).toDouble(),
    createdAt: _date(j['createdAt'] as String),
    updatedAt: _date(j['updatedAt'] as String),
    payments: (j['payments'] as List<dynamic>)
        .map((e) => Payment.fromJson(e as Map<String, dynamic>))
        .toList(),
    consumptions: (j['consumptions'] as List<dynamic>)
        .map((e) => Consumption.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}

/// Datos para crear/editar una reserva.
class ReservationInput {
  final String guestName;
  final String phone;
  final String domeId;
  final DateTime checkIn;
  final DateTime checkOut;
  final int guestCount;
  final double lodgingPrice;
  final String? notes;

  const ReservationInput({
    required this.guestName,
    required this.phone,
    required this.domeId,
    required this.checkIn,
    required this.checkOut,
    required this.guestCount,
    required this.lodgingPrice,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
    'guestName': guestName,
    'phone': phone,
    'domeId': domeId,
    'checkIn': _fmtDate(checkIn),
    'checkOut': _fmtDate(checkOut),
    'guestCount': guestCount,
    'lodgingPrice': lodgingPrice,
    'notes': notes,
  };
}
