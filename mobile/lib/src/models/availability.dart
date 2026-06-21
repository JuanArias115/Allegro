import 'reservation.dart';

class Availability {
  final String domeId;
  final DateTime checkIn;
  final DateTime checkOut;
  final bool isAvailable;
  final List<ReservationSummary> conflicts;

  const Availability({
    required this.domeId,
    required this.checkIn,
    required this.checkOut,
    required this.isAvailable,
    required this.conflicts,
  });

  factory Availability.fromJson(Map<String, dynamic> j) => Availability(
    domeId: j['domeId'] as String,
    checkIn: DateTime.parse(j['checkIn'] as String),
    checkOut: DateTime.parse(j['checkOut'] as String),
    isAvailable: j['isAvailable'] as bool,
    conflicts: (j['conflicts'] as List<dynamic>)
        .map((e) => ReservationSummary.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}
