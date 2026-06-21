import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/formatters.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/buttons.dart';
import '../../models/product.dart';
import '../../providers.dart';

typedef ConsumptionResult = ({String productId, int quantity});

Future<ConsumptionResult?> showAddConsumptionSheet(
  BuildContext context,
  WidgetRef ref,
) {
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
  ConsumerState<_AddConsumptionSheet> createState() =>
      _AddConsumptionSheetState();
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
          Text(
            'Agregar consumo',
            style: Theme.of(context).textTheme.titleLarge,
          ),
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
              final subtotal = _product!.currentPrice * _quantity;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppSelectField<Product>(
                    label: 'Producto',
                    icon: Icons.local_cafe_rounded,
                    value: _product!,
                    options: [
                      for (final p in products)
                        SelectOption(
                          p,
                          '${p.name} · ${Formatters.money(p.currentPrice)}',
                        ),
                    ],
                    onChanged: (p) => setState(() => _product = p),
                  ),
                  const SizedBox(height: 16),
                  StepperField(
                    label: 'Cantidad',
                    caption: 'Subtotal ${Formatters.money(subtotal)}',
                    value: _quantity,
                    onMinus: _quantity > 1
                        ? () => setState(() => _quantity--)
                        : null,
                    onPlus: () => setState(() => _quantity++),
                  ),
                  const SizedBox(height: 24),
                  PrimaryButton(
                    label: 'Agregar consumo',
                    icon: Icons.add_rounded,
                    onPressed: () => Navigator.pop(context, (
                      productId: _product!.id,
                      quantity: _quantity,
                    )),
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
