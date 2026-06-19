import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/reservation.dart';
import 'formatters.dart';

/// Tipos de mensaje listos para compartir por WhatsApp.
enum WhatsAppTemplate {
  confirmation('Confirmación de reserva'),
  paymentReminder('Recordatorio de abono'),
  preArrival('Información previa a la llegada'),
  accountSummary('Resumen de cuenta'),
  reviewRequest('Solicitud de reseña');

  const WhatsAppTemplate(this.label);
  final String label;
}

/// Genera los textos. No realiza ninguna acción de negocio (no cierra reservas).
class WhatsAppMessages {
  static String build(WhatsAppTemplate template, Reservation r) {
    return switch (template) {
      WhatsAppTemplate.confirmation => _confirmation(r),
      WhatsAppTemplate.paymentReminder => _paymentReminder(r),
      WhatsAppTemplate.preArrival => _preArrival(r),
      WhatsAppTemplate.accountSummary => _accountSummary(r),
      WhatsAppTemplate.reviewRequest => _reviewRequest(r),
    };
  }

  static String _confirmation(Reservation r) => '''
¡Hola ${r.guestName}! 🌿
Tu reserva en el glamping está confirmada:

🏕️ Domo: ${r.domeName}
📅 Llegada: ${Formatters.date(r.checkIn)}
📅 Salida: ${Formatters.date(r.checkOut)}
👥 Huéspedes: ${r.guestCount}

💵 Precio total: ${Formatters.money(r.lodgingPrice)}
✅ Abono recibido: ${Formatters.money(r.totalPaid)}
🧾 Saldo pendiente: ${Formatters.money(r.balance)}

¡Te esperamos!''';

  static String _paymentReminder(Reservation r) => '''
¡Hola ${r.guestName}! 🌿
Te recordamos el saldo pendiente de tu reserva:

🏕️ ${r.domeName} · ${Formatters.dateRange(r.checkIn, r.checkOut)}
🧾 Saldo pendiente: ${Formatters.money(r.balance)}

Cualquier inquietud, con gusto te ayudamos. ¡Gracias!''';

  static String _preArrival(Reservation r) => '''
¡Hola ${r.guestName}! 🌿
Falta poco para tu llegada al glamping:

🏕️ Domo: ${r.domeName}
📅 Llegada: ${Formatters.date(r.checkIn)}
🕒 Check-in desde las 3:00 p. m.

Por favor confírmanos tu hora aproximada de llegada. ¡Nos vemos pronto!''';

  static String _accountSummary(Reservation r) {
    final buffer = StringBuffer()
      ..writeln('Resumen de cuenta — ${r.guestName} 🌿')
      ..writeln('🏕️ ${r.domeName} · ${Formatters.dateRange(r.checkIn, r.checkOut)}')
      ..writeln('')
      ..writeln('Alojamiento: ${Formatters.money(r.lodgingPrice)}');
    if (r.consumptions.isNotEmpty) {
      buffer.writeln('Consumos:');
      for (final c in r.consumptions) {
        buffer.writeln('  • ${c.quantity}x ${c.productName} — ${Formatters.money(c.subtotal)}');
      }
      buffer.writeln('Total consumos: ${Formatters.money(r.totalConsumptions)}');
    }
    buffer
      ..writeln('')
      ..writeln('Total: ${Formatters.money(r.totalDue)}')
      ..writeln('Abonado: ${Formatters.money(r.totalPaid)}')
      ..writeln('Saldo pendiente: ${Formatters.money(r.balance)}');
    return buffer.toString();
  }

  static String _reviewRequest(Reservation r) => '''
¡Hola ${r.guestName}! 🌿
Esperamos que hayas disfrutado tu estadía en ${r.domeName}.

Nos encantaría conocer tu experiencia: ¿nos dejarías una reseña? 💚
¡Gracias por elegirnos!''';

  /// Comparte por el mecanismo nativo del teléfono.
  static Future<void> share(String text) => Share.share(text);

  /// Intenta abrir WhatsApp directamente con el número del huésped.
  static Future<bool> openWhatsApp(String phone, String text) async {
    final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final uri = Uri.parse('https://wa.me/$digits?text=${Uri.encodeComponent(text)}');
    if (await canLaunchUrl(uri)) {
      return launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    return false;
  }
}
