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
/// El escalado de texto se acota localmente para que nunca desborde, aunque el
/// teléfono use una fuente muy grande.
class _PillNavBar extends StatelessWidget {
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
          padding: const EdgeInsets.fromLTRB(14, 6, 14, 8),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1C1F1D) : Colors.white,
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
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
                      color: scheme,
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
  final ColorScheme color;
  final VoidCallback onTap;

  const _NavItem({
    required this.spec,
    required this.active,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fg = active ? color.primary : color.onSurfaceVariant;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: active ? color.primary.withValues(alpha: 0.12) : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(active ? spec.selectedIcon : spec.icon, size: 24, color: fg),
                const SizedBox(height: 3),
                Text(
                  spec.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    height: 1.0,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    color: fg,
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
