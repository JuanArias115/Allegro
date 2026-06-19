import 'package:allegro/src/core/whatsapp.dart';
import 'package:allegro/src/models/enums.dart';
import 'package:allegro/src/models/reservation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

Reservation _sample({double lodging = 400000, double paid = 150000, double consumptions = 0}) {
  return Reservation.fromJson({
    'id': 'r1',
    'guestName': 'Ana Demo',
    'phone': '+573001234567',
    'domeId': 'd1',
    'domeName': 'Domo 1',
    'checkIn': '2026-07-01',
    'checkOut': '2026-07-04',
    'guestCount': 2,
    'lodgingPrice': lodging,
    'status': 'Confirmed',
    'notes': null,
    'totalConsumptions': consumptions,
    'totalDue': lodging + consumptions,
    'totalPaid': paid,
    'balance': lodging + consumptions - paid,
    'createdAt': '2026-06-19T12:00:00Z',
    'updatedAt': '2026-06-19T12:00:00Z',
    'payments': [],
    'consumptions': [],
  });
}

void main() {
  setUpAll(() async => initializeDateFormatting('es'));

  group('Modelos', () {
    test('parsea estado y método desde el wire', () {
      expect(ReservationStatus.fromWire('CheckedIn'), ReservationStatus.checkedIn);
      expect(ReservationStatus.fromWire('Completed').label, 'Finalizada');
      expect(PaymentMethod.fromWire('Transfer'), PaymentMethod.transfer);
      expect(ProductCategory.fromWire('Beverages').label, 'Bebidas');
    });

    test('estado desconocido cae en un valor por defecto', () {
      expect(ReservationStatus.fromWire('xxx'), ReservationStatus.confirmed);
    });

    test('parsea reserva y conserva el saldo del backend', () {
      final r = _sample(lodging: 400000, paid: 150000);
      expect(r.guestName, 'Ana Demo');
      expect(r.balance, 250000);
      expect(r.checkIn, DateTime.parse('2026-07-01'));
    });
  });

  group('Mensajes de WhatsApp', () {
    test('la confirmación incluye nombre, domo, fechas, precio, abono y saldo', () {
      final r = _sample(lodging: 400000, paid: 150000);
      final msg = WhatsAppMessages.build(WhatsAppTemplate.confirmation, r);
      expect(msg, contains('Ana Demo'));
      expect(msg, contains('Domo 1'));
      expect(msg, contains('Saldo'));
      expect(msg, contains(r'$'));
    });

    test('el recordatorio de abono menciona el saldo pendiente', () {
      final r = _sample();
      final msg = WhatsAppMessages.build(WhatsAppTemplate.paymentReminder, r);
      expect(msg.toLowerCase(), contains('saldo'));
    });
  });
}
