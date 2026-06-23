import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design/tokens.dart';
import '../../core/formatters.dart';
import '../../core/widgets/state_views.dart';
import '../../models/product.dart';
import '../../models/product_category.dart';
import '../../providers.dart';
import 'widgets/category_filter_chips.dart';
import 'widgets/consumption_summary_bar.dart';
import 'widgets/product_consumption_card.dart';

typedef ConsumptionResult = ({String productId, int quantity});

/// Menú de consumos: buscador + chips de categoría + tarjetas de producto con
/// control de cantidad y barra de resumen. Devuelve la lista de consumos elegidos.
Future<List<ConsumptionResult>?> showAddConsumptionSheet(
  BuildContext context,
  WidgetRef ref, {
  required String guestName,
}) {
  return showModalBottomSheet<List<ConsumptionResult>>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    builder: (_) => _AddConsumptionSheet(guestName: guestName),
  );
}

class _AddConsumptionSheet extends ConsumerStatefulWidget {
  final String guestName;
  const _AddConsumptionSheet({required this.guestName});

  @override
  ConsumerState<_AddConsumptionSheet> createState() =>
      _AddConsumptionSheetState();
}

class _AddConsumptionSheetState extends ConsumerState<_AddConsumptionSheet> {
  final _search = TextEditingController();
  final Map<String, int> _qty = {};
  String? _categoryId; // null = Todos
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _add(Product p) => setState(() => _qty[p.id] = 1);
  void _inc(Product p) => setState(() => _qty[p.id] = (_qty[p.id] ?? 0) + 1);
  void _dec(Product p) => setState(() {
    final n = (_qty[p.id] ?? 0) - 1;
    if (n <= 0) {
      _qty.remove(p.id);
    } else {
      _qty[p.id] = n;
    }
  });

  /// Productos filtrados por categoría + búsqueda y ordenados por
  /// (DisplayOrder de categoría, nombre).
  List<Product> _visible(List<Product> products, List<ProductCategory> cats) {
    final order = {for (final c in cats) c.id: c.displayOrder};
    final q = _query.trim().toLowerCase();
    final list = products.where((p) {
      if (_categoryId != null && p.categoryId != _categoryId) return false;
      if (q.isNotEmpty && !p.name.toLowerCase().contains(q)) return false;
      return true;
    }).toList();
    list.sort((a, b) {
      final oa = order[a.categoryId] ?? 1 << 30;
      final ob = order[b.categoryId] ?? 1 << 30;
      if (oa != ob) return oa.compareTo(ob);
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return list;
  }

  double _total(List<Product> products) {
    var sum = 0.0;
    for (final p in products) {
      final n = _qty[p.id];
      if (n != null) sum += p.currentPrice * n;
    }
    return sum;
  }

  void _confirm() {
    final result = [
      for (final e in _qty.entries)
        if (e.value > 0) (productId: e.key, quantity: e.value),
    ];
    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(activeProductsProvider);
    final categoriesAsync = ref.watch(productCategoriesProvider);
    final categories = categoriesAsync.asData?.value ?? const <ProductCategory>[];
    final maxHeight = MediaQuery.of(context).size.height * 0.9;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Header(guestName: widget.guestName, total: _selectedTotal(productsAsync)),
            const SizedBox(height: AppSpacing.x3),
            _SearchField(
              controller: _search,
              onChanged: (v) => setState(() => _query = v),
            ),
            const SizedBox(height: AppSpacing.x3),
            if (categories.isNotEmpty)
              CategoryFilterChips(
                categories: categories,
                selectedId: _categoryId,
                onSelected: (id) => setState(() => _categoryId = id),
              ),
            const SizedBox(height: AppSpacing.x2),
            Expanded(
              child: productsAsync.when(
                loading: () => const LoadingState(),
                error: (e, _) => ErrorState(
                  error: e,
                  onRetry: () => ref.invalidate(activeProductsProvider),
                ),
                data: (products) {
                  final visible = _visible(products, categories);
                  if (visible.isEmpty) {
                    return const EmptyState(
                      icon: Icons.search_off_rounded,
                      title: 'Sin resultados',
                      message: 'No hay productos para ese filtro o búsqueda.',
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.x5,
                      AppSpacing.x2,
                      AppSpacing.x5,
                      AppSpacing.x4,
                    ),
                    itemCount: visible.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.x3),
                    itemBuilder: (context, i) {
                      final p = visible[i];
                      return ProductConsumptionCard(
                        product: p,
                        quantity: _qty[p.id] ?? 0,
                        onAdd: () => _add(p),
                        onIncrement: () => _inc(p),
                        onDecrement: () => _dec(p),
                      );
                    },
                  );
                },
              ),
            ),
            ConsumptionSummaryBar(
              count: _count,
              total: _selectedTotal(productsAsync),
              onConfirm: _confirm,
            ),
          ],
        ),
      ),
    );
  }

  int get _count => _qty.values.fold(0, (a, b) => a + b);

  double _selectedTotal(AsyncValue<List<Product>> productsAsync) {
    final products = productsAsync.asData?.value;
    if (products == null) return 0;
    return _total(products);
  }
}

class _Header extends StatelessWidget {
  final String guestName;
  final double total;
  const _Header({
    required this.guestName,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.x5, 0, AppSpacing.x5, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  guestName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 2),
                Text(
                  'Agregar consumos a la reserva',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.x3),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Seleccionado',
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                Formatters.money(total),
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: cs.onPrimaryContainer,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  const _SearchField({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x5),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        style: const TextStyle(
          fontFamily: 'Manrope',
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          isDense: true,
          filled: true,
          fillColor: cs.surface,
          hintText: 'Buscar producto',
          prefixIcon: Icon(Icons.search_rounded, color: cs.onSurfaceVariant),
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          enabledBorder: OutlineInputBorder(
            borderRadius: AppRadii.all(AppRadii.md),
            borderSide: BorderSide(color: cs.outlineVariant),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: AppRadii.all(AppRadii.md),
            borderSide: BorderSide(color: cs.primary, width: 1.6),
          ),
          border: OutlineInputBorder(
            borderRadius: AppRadii.all(AppRadii.md),
            borderSide: BorderSide(color: cs.outlineVariant),
          ),
        ),
      ),
    );
  }
}
