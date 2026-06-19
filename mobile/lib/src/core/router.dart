import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/login_screen.dart';
import '../features/calendar/calendar_screen.dart';
import '../features/checkout/checkout_screen.dart';
import '../features/history/history_screen.dart';
import '../features/more/more_screen.dart';
import '../features/products/products_screen.dart';
import '../features/reservations/reservation_detail_screen.dart';
import '../features/reservations/reservation_form_screen.dart';
import '../features/reservations/reservations_list_screen.dart';
import '../features/shell/home_shell.dart';
import '../features/today/today_screen.dart';
import '../providers.dart';
import 'config.dart';

final _rootKey = GlobalKey<NavigatorState>();
final _shellKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  // ref.read (no watch): el GoRouter se crea una sola vez. Reaccionamos a los
  // cambios de sesión con refreshListenable, no recreando el router (lo que
  // duplicaría las GlobalKey de navegación).
  final auth = ref.read(authServiceProvider);

  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/today',
    refreshListenable: auth,
    redirect: (context, state) {
      if (!AppConfig.isFirebaseAuth) return null; // modo local: sin login
      final loggingIn = state.matchedLocation == '/login';
      if (!auth.isAuthenticated) return loggingIn ? null : '/login';
      if (loggingIn) return '/today';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      ShellRoute(
        navigatorKey: _shellKey,
        builder: (context, state, child) => HomeShell(child: child),
        routes: [
          GoRoute(path: '/today', builder: (c, s) => const TodayScreen()),
          GoRoute(path: '/reservations', builder: (c, s) => const ReservationsListScreen()),
          GoRoute(path: '/calendar', builder: (c, s) => const CalendarScreen()),
          GoRoute(path: '/more', builder: (c, s) => const MoreScreen()),
        ],
      ),
      // Productos vive fuera del navbar (accesible desde "Más").
      GoRoute(
        path: '/products',
        parentNavigatorKey: _rootKey,
        builder: (c, s) => const ProductsScreen(),
      ),
      GoRoute(
        path: '/history',
        parentNavigatorKey: _rootKey,
        builder: (c, s) => const HistoryScreen(),
      ),
      GoRoute(
        path: '/reservations/new',
        parentNavigatorKey: _rootKey,
        builder: (c, s) => ReservationFormScreen(
          initialDate: s.uri.queryParameters['date'],
          initialDomeId: s.uri.queryParameters['domeId'],
        ),
      ),
      GoRoute(
        path: '/reservations/:id',
        parentNavigatorKey: _rootKey,
        builder: (c, s) => ReservationDetailScreen(id: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/reservations/:id/edit',
        parentNavigatorKey: _rootKey,
        builder: (c, s) => ReservationFormScreen(editId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/reservations/:id/checkout',
        parentNavigatorKey: _rootKey,
        builder: (c, s) => CheckoutScreen(id: s.pathParameters['id']!),
      ),
    ],
  );
});
