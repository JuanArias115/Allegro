import 'package:flutter/material.dart';

import '../design/tokens.dart';

class AppNavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const AppNavItem({required this.icon, required this.activeIcon, required this.label});
}

/// Navegación inferior tipo píldora, integrada con el fondo crema.
/// Altura fija (sin expandirse), indicador activo claro y SafeArea respetada.
class AppBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final List<AppNavItem> items;
  final ValueChanged<int> onSelect;

  const AppBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.items,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      top: false,
      child: MediaQuery.withClampedTextScaling(
        maxScaleFactor: 1.1,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.x4, 0, AppSpacing.x4, AppSpacing.x2),
          child: Container(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.white,
              borderRadius: AppRadii.all(AppRadii.xl),
              boxShadow: AppShadows.card,
            ),
            child: Row(
              children: [
                for (var i = 0; i < items.length; i++)
                  Expanded(
                    child: _NavButton(
                      item: items[i],
                      active: i == currentIndex,
                      primary: scheme.primary,
                      idle: scheme.outline,
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

class _NavButton extends StatelessWidget {
  final AppNavItem item;
  final bool active;
  final Color primary;
  final Color idle;
  final VoidCallback onTap;

  const _NavButton({
    required this.item,
    required this.active,
    required this.primary,
    required this.idle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fg = active ? primary : idle;
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadii.all(AppRadii.lg),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: AppDurations.fast,
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: active ? AppColors.mint : Colors.transparent,
                borderRadius: AppRadii.all(AppRadii.pill),
              ),
              child: Icon(active ? item.activeIcon : item.icon, size: 22, color: fg),
            ),
            const SizedBox(height: 3),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                item.label,
                maxLines: 1,
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 11.5,
                  height: 1,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                  color: fg,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
