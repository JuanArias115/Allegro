import 'reservation.dart';

class TodayState {
  final DateTime date;
  final List<ReservationSummary> arrivals;
  final List<ReservationSummary> departures;
  final List<ReservationSummary> currentlyHosted;
  final List<ReservationSummary> upcoming;

  const TodayState({
    required this.date,
    required this.arrivals,
    required this.departures,
    required this.currentlyHosted,
    required this.upcoming,
  });

  bool get isEmpty =>
      arrivals.isEmpty &&
      departures.isEmpty &&
      currentlyHosted.isEmpty &&
      upcoming.isEmpty;

  static List<ReservationSummary> _list(dynamic raw) => (raw as List<dynamic>)
      .map((e) => ReservationSummary.fromJson(e as Map<String, dynamic>))
      .toList();

  factory TodayState.fromJson(Map<String, dynamic> j) => TodayState(
    date: DateTime.parse(j['date'] as String),
    arrivals: _list(j['arrivals']),
    departures: _list(j['departures']),
    currentlyHosted: _list(j['currentlyHosted']),
    upcoming: _list(j['upcoming']),
  );
}
