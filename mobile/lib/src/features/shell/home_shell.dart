import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/app_bottom_nav.dart';

class HomeShell extends StatelessWidget {
  final Widget child;
  const HomeShell({super.key, required this.child});

  static const _routes = ['/today', '/reservations', '/calendar', '/more'];
  static const _items = [
    AppNavItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      label: 'Inicio',
    ),
    AppNavItem(
      icon: Icons.event_note_outlined,
      activeIcon: Icons.event_note_rounded,
      label: 'Reservas',
    ),
    AppNavItem(
      icon: Icons.calendar_month_outlined,
      activeIcon: Icons.calendar_month_rounded,
      label: 'Calendario',
    ),
    AppNavItem(
      icon: Icons.grid_view_outlined,
      activeIcon: Icons.grid_view_rounded,
      label: 'Más',
    ),
  ];

  int _indexFor(String location) {
    final i = _routes.indexWhere((p) => location.startsWith(p));
    return i < 0 ? 0 : i;
  }

  @override
  Widget build(BuildContext context) {
    final index = _indexFor(GoRouterState.of(context).uri.path);
    return Scaffold(
      // Transición sutil al cambiar de sección. Usamos un único hijo montado
      // (clave por índice) para no duplicar la GlobalKey del shell de go_router.
      body: TweenAnimationBuilder<double>(
        key: ValueKey(index),
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        child: child,
        builder: (context, v, child) => Opacity(
          opacity: v.clamp(0, 1),
          child: Transform.translate(
            offset: Offset(0, (1 - v) * 8),
            child: child,
          ),
        ),
      ),
      bottomNavigationBar: AppBottomNavigation(
        currentIndex: index,
        items: _items,
        onSelect: (i) => context.go(_routes[i]),
      ),
    );
  }
}
