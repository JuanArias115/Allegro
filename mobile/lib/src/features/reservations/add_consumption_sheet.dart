import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/formatters.dart';
import '../../models/product.dart';
import '../../providers.dart';

typedef ConsumptionResult = ({String productId, int quantity});

Future<ConsumptionResult?> showAddConsumptionSheet(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet<ConsumptionResult>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => const _AddConsumptionSheet(),
  );
}

class _AddConsumptionSheet extends ConsumerStatefulWidget {
  const _AddConsumptionSheet();

  @override
  ConsumerState<_AddConsumptionSheet> createState() => _AddConsumptionSheetState();
}

class _AddConsumptionSheetState extends ConsumerState<_AddConsumptionSheet> {
  Product? _product;
  int _quantity = 1;

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(activeProductsProvider);

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Agregar consumo', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          productsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Text('Error al cargar productos: $e'),
            data: (products) {
              if (products.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No hay productos activos en el catálogo.'),
                );
              }
              _product ??= products.first;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DropdownButtonFormField<Product>(
                    initialValue: _product,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Producto'),
                    items: [
                      for (final p in products)
                        DropdownMenuItem(
                          value: p,
                          child: Text('${p.name} · ${Formatters.money(p.currentPrice)}',
                              overflow: TextOverflow.ellipsis),
                        ),
                    ],
                    onChanged: (p) => setState(() => _product = p),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text('Cantidad'),
                      const Spacer(),
                      IconButton.filledTonal(
                        onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
                        icon: const Icon(Icons.remove),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text('$_quantity',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                      ),
                      IconButton.filledTonal(
                        onPressed: () => setState(() => _quantity++),
                        icon: const Icon(Icons.add),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_product != null)
                    Text('Subtotal: ${Formatters.money(_product!.currentPrice * _quantity)}',
                        textAlign: TextAlign.end,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _product == null
                        ? null
                        : () => Navigator.pop(
                            context, (productId: _product!.id, quantity: _quantity)),
                    child: const Text('Agregar consumo'),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
