import '../core/api/api_client.dart';
import '../models/availability.dart';
import '../models/checkout.dart';
import '../models/enums.dart';
import '../models/reservation.dart';
import '../models/today.dart';

class ReservationRepository {
  final ApiClient _api;
  ReservationRepository(this._api);

  String _date(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<TodayState> today() async {
    final data = await _api.get<Map<String, dynamic>>('/api/today');
    return TodayState.fromJson(data);
  }

  Future<Availability> availability(
    String domeId,
    DateTime checkIn,
    DateTime checkOut, {
    String? excludeReservationId,
  }) async {
    final data = await _api.get<Map<String, dynamic>>('/api/availability', query: {
      'domeId': domeId,
      'checkIn': _date(checkIn),
      'checkOut': _date(checkOut),
      if (excludeReservationId != null) 'excludeReservationId': excludeReservationId,
    });
    return Availability.fromJson(data);
  }

  Future<List<ReservationSummary>> list({
    String? name,
    String? phone,
    String? domeId,
    ReservationStatus? status,
    DateTime? from,
    DateTime? to,
    bool? active,
  }) async {
    final data = await _api.get<List<dynamic>>('/api/reservations', query: {
      if (name != null && name.isNotEmpty) 'name': name,
      if (phone != null && phone.isNotEmpty) 'phone': phone,
      if (domeId != null) 'domeId': domeId,
      if (status != null) 'status': status.wire,
      if (from != null) 'from': _date(from),
      if (to != null) 'to': _date(to),
      if (active != null) 'active': active,
    });
    return data.map((e) => ReservationSummary.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Reservation> getById(String id) async {
    final data = await _api.get<Map<String, dynamic>>('/api/reservations/$id');
    return Reservation.fromJson(data);
  }

  Future<Reservation> create(ReservationInput input) async {
    final data = await _api.post<Map<String, dynamic>>('/api/reservations', body: input.toJson());
    return Reservation.fromJson(data);
  }

  Future<Reservation> update(String id, ReservationInput input) async {
    final data = await _api.put<Map<String, dynamic>>('/api/reservations/$id', body: input.toJson());
    return Reservation.fromJson(data);
  }

  Future<Reservation> changeStatus(String id, ReservationStatus status) async {
    final data = await _api.patch<Map<String, dynamic>>('/api/reservations/$id/status',
        body: {'status': status.wire});
    return Reservation.fromJson(data);
  }

  Future<Reservation> addPayment(
    String id, {
    required double amount,
    required PaymentMethod method,
    String? note,
    DateTime? paidAt,
  }) async {
    final data = await _api.post<Map<String, dynamic>>('/api/reservations/$id/payments', body: {
      'amount': amount,
      'method': method.wire,
      'note': note,
      'paidAt': paidAt?.toUtc().toIso8601String(),
    });
    return Reservation.fromJson(data);
  }

  Future<Reservation> addConsumption(
    String id, {
    required String productId,
    required int quantity,
    DateTime? consumedAt,
  }) async {
    final data = await _api.post<Map<String, dynamic>>('/api/reservations/$id/consumptions', body: {
      'productId': productId,
      'quantity': quantity,
      'consumedAt': consumedAt?.toUtc().toIso8601String(),
    });
    return Reservation.fromJson(data);
  }

  Future<Reservation> removeConsumption(String id, String consumptionId) async {
    final data = await _api.delete<Map<String, dynamic>>('/api/reservations/$id/consumptions/$consumptionId');
    return Reservation.fromJson(data);
  }

  Future<CheckoutSummary> checkoutSummary(String id) async {
    final data = await _api.get<Map<String, dynamic>>('/api/reservations/$id/checkout');
    return CheckoutSummary.fromJson(data);
  }

  Future<Reservation> checkout(
    String id, {
    double? finalAmount,
    PaymentMethod? finalMethod,
    String? finalNote,
  }) async {
    final Object? body = finalAmount != null && finalAmount > 0
        ? {
            'amount': finalAmount,
            'method': (finalMethod ?? PaymentMethod.cash).wire,
            'note': finalNote,
          }
        : null;
    final data = await _api.post<Map<String, dynamic>>('/api/reservations/$id/checkout', body: body);
    return Reservation.fromJson(data);
  }
}
