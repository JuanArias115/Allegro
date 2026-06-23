import 'package:flutter/material.dart';

import '../../../core/design/tokens.dart';
import '../../../models/product_category.dart';

/// Fila horizontal de chips para filtrar por categoría. La primera opción es
/// "Todos" (id null). Las demás vienen del backend (solo activas, ya ordenadas).
/// Sin iconos: las categorías son dinámicas.
class CategoryFilterChips extends StatelessWidget {
  final List<ProductCategory> categories;
  final String? selectedId;
  final ValueChanged<String?> onSelected;

  const CategoryFilterChips({
    super.key,
    required this.categories,
    required this.selectedId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x5),
        itemCount: categories.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.x2),
        itemBuilder: (context, index) {
          if (index == 0) {
            return _Chip(
              label: 'Todos',
              selected: selectedId == null,
              onTap: () => onSelected(null),
            );
          }
          final c = categories[index - 1];
          return _Chip(
            label: c.name,
            selected: selectedId == c.id,
            onTap: () => onSelected(c.id),
          );
        },
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _Chip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: AppRadii.all(AppRadii.pill),
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppDurations.fast,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.x4,
            vertical: AppSpacing.x2,
          ),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.mint : AppColors.surface,
            borderRadius: AppRadii.all(AppRadii.pill),
            border: Border.all(
              color: selected ? Colors.transparent : AppColors.hairline,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: selected ? AppColors.forestDark : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
