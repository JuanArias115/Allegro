import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/api/api_client.dart';
import 'core/auth/auth_service.dart';
import 'core/config.dart';
import 'data/dome_repository.dart';
import 'data/product_repository.dart';
import 'data/reservation_repository.dart';
import 'models/dome.dart';
import 'models/enums.dart';
import 'models/product.dart';
import 'models/reservation.dart';
import 'models/today.dart';

// ----- Infraestructura -----

final authServiceProvider = ChangeNotifierProvider<AuthService>((ref) {
  return AppConfig.isFirebaseAuth ? FirebaseAuthService() : LocalAuthService();
});

final apiClientProvider = Provider<ApiClient>((ref) {
  final auth = ref.watch(authServiceProvider);
  return ApiClient(auth);
});

final reservationRepositoryProvider = Provider<ReservationRepository>(
    (ref) => ReservationRepository(ref.watch(apiClientProvider)));

final productRepositoryProvider = Provider<ProductRepository>(
    (ref) => ProductRepository(ref.watch(apiClientProvider)));

final domeRepositoryProvider = Provider<DomeRepository>(
    (ref) => DomeRepository(ref.watch(apiClientProvider)));

// ----- Datos -----

final todayProvider = FutureProvider.autoDispose<TodayState>(
    (ref) => ref.watch(reservationRepositoryProvider).today());

final domesProvider = FutureProvider<List<Dome>>(
    (ref) => ref.watch(domeRepositoryProvider).getAll());

final activeDomesProvider = FutureProvider<List<Dome>>(
    (ref) => ref.watch(domeRepositoryProvider).getAll(onlyActive: true));

final productsProvider = FutureProvider.autoDispose<List<Product>>(
    (ref) => ref.watch(productRepositoryProvider).getAll());

final activeProductsProvider = FutureProvider.autoDispose<List<Product>>(
    (ref) => ref.watch(productRepositoryProvider).getAll(onlyActive: true));

/// Filtros del listado/historial de reservas.
class ReservationFilter {
  final String? text;
  final String? domeId;
  final ReservationStatus? status;
  final bool? active;

  const ReservationFilter({this.text, this.domeId, this.status, this.active});

  ReservationFilter copyWith({
    String? text,
    String? domeId,
    ReservationStatus? status,
    bool? active,
    bool clearDome = false,
    bool clearStatus = false,
  }) =>
      ReservationFilter(
        text: text ?? this.text,
        domeId: clearDome ? null : (domeId ?? this.domeId),
        status: clearStatus ? null : (status ?? this.status),
        active: active ?? this.active,
      );
}

final reservationListProvider = FutureProvider.autoDispose
    .family<List<ReservationSummary>, ReservationFilter>((ref, filter) {
  final repo = ref.watch(reservationRepositoryProvider);
  final isPhone = (filter.text ?? '').isNotEmpty &&
      RegExp(r'^[0-9+\s-]+$').hasMatch(filter.text!);
  return repo.list(
    name: isPhone ? null : filter.text,
    phone: isPhone ? filter.text : null,
    domeId: filter.domeId,
    status: filter.status,
    active: filter.active,
  );
});

final reservationDetailProvider =
    FutureProvider.autoDispose.family<Reservation, String>((ref, id) {
  return ref.watch(reservationRepositoryProvider).getById(id);
});
