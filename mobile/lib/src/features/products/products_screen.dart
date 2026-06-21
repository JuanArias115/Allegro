import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/tokens.dart';
import '../../core/formatters.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/cards.dart';
import '../../core/widgets/state_views.dart';
import '../../models/product.dart';
import '../../providers.dart';
import 'product_form_sheet.dart';
import 'product_grouping.dart';

class ProductsScreen extends ConsumerWidget {
  const ProductsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsProvider);
    final categoriesAsync = ref.watch(productCategoriesProvider);

    void refresh() {
      ref.invalidate(productsProvider);
      ref.invalidate(productCategoriesProvider);
    }

    return AppScaffold(
      header: AppHeader(title: 'Productos', onBack: () => context.pop()),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.forest,
        foregroundColor: AppColors.white,
        onPressed: () async {
          if (await showProductFormSheet(context, ref)) refresh();
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Nuevo',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: Builder(
        builder: (context) {
          // Sin categorías no se puede mostrar el catálogo: error claro, sin asumir valores fijos.
          if (categoriesAsync.hasError) {
            return ErrorState(error: categoriesAsync.error!, onRetry: refresh);
          }
          if (productsAsync.hasError) {
            return ErrorState(error: productsAsync.error!, onRetry: refresh);
          }
          if (productsAsync.isLoading || categoriesAsync.isLoading) {
            return const LoadingState();
          }

          final groups = groupProductsByCategory(
            productsAsync.value!,
            categoriesAsync.value!,
          );
          if (groups.isEmpty) {
            return EmptyState(
              icon: Icons.local_cafe_rounded,
              title: 'Catálogo vacío',
              message:
                  'Agrega productos o servicios para cargarlos a las reservas.',
              accent: AppColors.coral,
            );
          }

          return RefreshIndicator(
            color: AppColors.forest,
            onRefresh: () async => refresh(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.x5,
                AppSpacing.x2,
                AppSpacing.x5,
                120,
              ),
              children: [
                for (var g = 0; g < groups.length; g++) ...[
                  _CategoryHeader(
                    name: groups[g].categoryName,
                    count: groups[g].products.length,
                    colorIndex: g,
                  ),
                  for (var i = 0; i < groups[g].products.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.x2),
                      child: AppearAnimation(
                        index: i,
                        child: _ProductTile(
                          product: groups[g].products[i],
                          colorIndex: g,
                          onEdit: () async {
                            if (await showProductFormSheet(
                              context,
                              ref,
                              product: groups[g].products[i],
                            )) {
                              refresh();
                            }
                          },
                        ),
                      ),
                    ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CategoryHeader extends StatelessWidget {
  final String name;
  final int count;
  final int colorIndex;
  const _CategoryHeader({
    required this.name,
    required this.count,
    required this.colorIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, AppSpacing.x5, 2, AppSpacing.x3),
      child: Row(
        children: [
          CategoryIcon(
            icon: categoryGenericIcon,
            color: categoryColorByIndex(colorIndex),
            size: 30,
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              name,
              style: Theme.of(context).textTheme.titleMedium,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 6),
          Text('· $count', style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _ProductTile extends StatelessWidget {
  final Product product;
  final int colorIndex;
  final VoidCallback onEdit;
  const _ProductTile({
    required this.product,
    required this.colorIndex,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final color = categoryColorByIndex(colorIndex);
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      onTap: onEdit,
      child: Row(
        children: [
          CategoryIcon(icon: categoryGenericIcon, color: color, size: 42),
          const SizedBox(width: AppSpacing.x3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 2),
                Text(
                  Formatters.money(product.currentPrice),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          if (!product.isActive)
            Container(
              margin: const EdgeInsets.only(right: 6),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.textSecondary.withValues(alpha: 0.12),
                borderRadius: AppRadii.all(AppRadii.pill),
              ),
              child: Text(
                'Inactivo',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          Icon(
            Icons.chevron_right_rounded,
            color: Theme.of(context).colorScheme.outline,
          ),
        ],
      ),
    );
  }
}
