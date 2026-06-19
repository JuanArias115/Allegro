import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/tokens.dart';
import '../../core/formatters.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/cards.dart';
import '../../core/widgets/state_views.dart';
import '../../models/enums.dart';
import '../../models/product.dart';
import '../../providers.dart';
import 'product_form_sheet.dart';

class ProductsScreen extends ConsumerWidget {
  const ProductsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(productsProvider);

    return AppScaffold(
      header: AppHeader(title: 'Productos', onBack: () => context.pop()),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.forest,
        foregroundColor: AppColors.white,
        onPressed: () async {
          if (await showProductFormSheet(context, ref)) ref.invalidate(productsProvider);
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nuevo', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: async.when(
        loading: () => const LoadingState(),
        error: (e, _) => ErrorState(error: e, onRetry: () => ref.invalidate(productsProvider)),
        data: (products) {
          if (products.isEmpty) {
            return EmptyState(
              icon: Icons.local_cafe_rounded,
              title: 'Catálogo vacío',
              message: 'Agrega productos o servicios para cargarlos a las reservas.',
              accent: AppColors.coral,
            );
          }
          final byCategory = <ProductCategory, List<Product>>{};
          for (final p in products) {
            byCategory.putIfAbsent(p.category, () => []).add(p);
          }
          return RefreshIndicator(
            color: AppColors.forest,
            onRefresh: () async => ref.invalidate(productsProvider),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(AppSpacing.x5, AppSpacing.x2, AppSpacing.x5, 120),
              children: [
                for (final category in ProductCategory.values)
                  if (byCategory[category] != null) ...[
                    _CategoryHeader(category: category, count: byCategory[category]!.length),
                    for (var i = 0; i < byCategory[category]!.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.x2),
                        child: AppearAnimation(
                          index: i,
                          child: _ProductTile(
                            product: byCategory[category]![i],
                            onEdit: () async {
                              if (await showProductFormSheet(context, ref, product: byCategory[category]![i])) {
                                ref.invalidate(productsProvider);
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
  final ProductCategory category;
  final int count;
  const _CategoryHeader({required this.category, required this.count});

  @override
  Widget build(BuildContext context) {
    final color = categoryColor(category);
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, AppSpacing.x5, 2, AppSpacing.x3),
      child: Row(
        children: [
          CategoryIcon(icon: categoryIcon(category), color: color, size: 30),
          const SizedBox(width: 10),
          Text(category.label, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(width: 6),
          Text('· $count', style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _ProductTile extends StatelessWidget {
  final Product product;
  final VoidCallback onEdit;
  const _ProductTile({required this.product, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final color = categoryColor(product.category);
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      onTap: onEdit,
      child: Row(
        children: [
          CategoryIcon(icon: categoryIcon(product.category), color: color, size: 42),
          const SizedBox(width: AppSpacing.x3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.name,
                    maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 2),
                Text(Formatters.money(product.currentPrice), style: Theme.of(context).textTheme.bodyMedium),
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
              child: Text('Inactivo', style: Theme.of(context).textTheme.bodySmall),
            ),
          Icon(Icons.chevron_right_rounded, color: Theme.of(context).colorScheme.outline),
        ],
      ),
    );
  }
}
