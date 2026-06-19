import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeShell extends StatelessWidget {
  final Widget child;
  const HomeShell({super.key, required this.child});

  static const _tabs = <_TabSpec>[
    _TabSpec('/today', Icons.today_outlined, Icons.today, 'Hoy'),
    _TabSpec('/calendar', Icons.calendar_month_outlined, Icons.calendar_month, 'Calendario'),
    _TabSpec('/reservations', Icons.event_note_outlined, Icons.event_note, 'Reservas'),
    _TabSpec('/products', Icons.local_cafe_outlined, Icons.local_cafe, 'Productos'),
    _TabSpec('/more', Icons.more_horiz_outlined, Icons.more_horiz, 'Más'),
  ];

  int _indexFor(String location) {
    final i = _tabs.indexWhere((t) => location.startsWith(t.path));
    return i < 0 ? 0 : i;
  }

  @override
  Widget build(BuildContext context) {
    final index = _indexFor(GoRouterState.of(context).uri.path);
    return Scaffold(
      body: child,
      bottomNavigationBar: _PillNavBar(
        currentIndex: index,
        tabs: _tabs,
        onSelect: (i) => context.go(_tabs[i].path),
      ),
    );
  }
}

class _TabSpec {
  final String path;
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  const _TabSpec(this.path, this.icon, this.selectedIcon, this.label);
}

/// Barra inferior tipo "píldora" flotante, inspirada en interfaces limpias.
/// Altura fija para que no se expanda, y escalado de texto acotado para que las
/// etiquetas no se deformen ni se corten aunque el teléfono use fuente grande.
class _PillNavBar extends StatelessWidget {
  static const double _barHeight = 62;

  final int currentIndex;
  final List<_TabSpec> tabs;
  final ValueChanged<int> onSelect;

  const _PillNavBar({
    required this.currentIndex,
    required this.tabs,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      top: false,
      child: MediaQuery.withClampedTextScaling(
        maxScaleFactor: 1.15,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
          child: Container(
            height: _barHeight,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1C1F1D) : Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.10),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                for (var i = 0; i < tabs.length; i++)
                  Expanded(
                    child: _NavItem(
                      spec: tabs[i],
                      active: i == currentIndex,
                      scheme: scheme,
                      onTap: () => onSelect(i),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final _TabSpec spec;
  final bool active;
  final ColorScheme scheme;
  final VoidCallback onTap;

  const _NavItem({
    required this.spec,
    required this.active,
    required this.scheme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fg = active ? scheme.primary : scheme.onSurfaceVariant;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: active ? scheme.primary.withValues(alpha: 0.14) : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(active ? spec.selectedIcon : spec.icon, size: 23, color: fg),
          ),
          const SizedBox(height: 3),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                spec.label,
                maxLines: 1,
                style: TextStyle(
                  fontSize: 11,
                  height: 1.0,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  color: fg,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
