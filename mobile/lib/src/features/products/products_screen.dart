import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/formatters.dart';
import '../../core/widgets/common_widgets.dart';
import '../../models/enums.dart';
import '../../models/product.dart';
import '../../providers.dart';
import 'product_form_sheet.dart';

class ProductsScreen extends ConsumerWidget {
  const ProductsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(productsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Productos')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await showProductFormSheet(context, ref);
          if (created) ref.invalidate(productsProvider);
        },
        icon: const Icon(Icons.add),
        label: const Text('Nuevo'),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorRetry(error: e, onRetry: () => ref.invalidate(productsProvider)),
        data: (products) {
          if (products.isEmpty) {
            return const EmptyState(
              icon: Icons.local_cafe_outlined,
              title: 'Sin productos',
              message: 'Agrega productos o servicios al catálogo.',
            );
          }
          final byCategory = <ProductCategory, List<Product>>{};
          for (final p in products) {
            byCategory.putIfAbsent(p.category, () => []).add(p);
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(productsProvider),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 96),
              children: [
                for (final category in ProductCategory.values)
                  if (byCategory[category] != null) ...[
                    SectionHeader(category.label),
                    for (final p in byCategory[category]!)
                      Card(
                        child: ListTile(
                          title: Text(p.name),
                          subtitle: Text(Formatters.money(p.currentPrice)),
                          trailing: p.isActive
                              ? null
                              : const Chip(label: Text('Inactivo'), visualDensity: VisualDensity.compact),
                          onTap: () async {
                            final updated = await showProductFormSheet(context, ref, product: p);
                            if (updated) ref.invalidate(productsProvider);
                          },
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
