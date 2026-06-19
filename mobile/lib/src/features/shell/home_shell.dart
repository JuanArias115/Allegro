import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeShell extends StatelessWidget {
  final Widget child;
  const HomeShell({super.key, required this.child});

  static const _tabs = [
    (path: '/today', icon: Icons.today_outlined, selected: Icons.today, label: 'Hoy'),
    (path: '/calendar', icon: Icons.calendar_month_outlined, selected: Icons.calendar_month, label: 'Calendario'),
    (path: '/reservations', icon: Icons.event_note_outlined, selected: Icons.event_note, label: 'Reservas'),
    (path: '/products', icon: Icons.local_cafe_outlined, selected: Icons.local_cafe, label: 'Productos'),
    (path: '/more', icon: Icons.more_horiz, selected: Icons.more_horiz, label: 'Más'),
  ];

  int _indexFor(String location) {
    final i = _tabs.indexWhere((t) => location.startsWith(t.path));
    return i < 0 ? 0 : i;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final index = _indexFor(location);

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => context.go(_tabs[i].path),
        destinations: [
          for (final t in _tabs)
            NavigationDestination(
              icon: Icon(t.icon),
              selectedIcon: Icon(t.selected),
              label: t.label,
            ),
        ],
      ),
    );
  }
}
