import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design/tokens.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/buttons.dart';
import '../../models/product.dart';
import '../../models/product_category.dart';
import '../../providers.dart';

/// Devuelve true si se creó/actualizó un producto.
Future<bool> showProductFormSheet(
  BuildContext context,
  WidgetRef ref, {
  Product? product,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _ProductFormSheet(product: product),
  );
  return result ?? false;
}

class _ProductFormSheet extends ConsumerStatefulWidget {
  final Product? product;
  const _ProductFormSheet({this.product});

  @override
  ConsumerState<_ProductFormSheet> createState() => _ProductFormSheetState();
}

class _ProductFormSheetState extends ConsumerState<_ProductFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _price;
  String? _categoryId;
  late bool _active;
  bool _saving = false;

  bool get _isEdit => widget.product != null;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _name = TextEditingController(text: p?.name ?? '');
    _price = TextEditingController(
      text: p != null ? p.currentPrice.toStringAsFixed(0) : '',
    );
    _categoryId =
        p?.categoryId; // null en creación: se fija al cargar categorías
    _active = p?.isActive ?? true;
  }

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_categoryId == null) return;
    setState(() => _saving = true);
    final repo = ref.read(productRepositoryProvider);
    final price = double.parse(_price.text.replaceAll(',', ''));
    try {
      if (_isEdit) {
        await repo.update(
          widget.product!.id,
          name: _name.text.trim(),
          categoryId: _categoryId!,
          currentPrice: price,
          isActive: _active,
        );
      } else {
        await repo.create(
          name: _name.text.trim(),
          categoryId: _categoryId!,
          currentPrice: price,
          isActive: _active,
        );
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(productCategoriesProvider);

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _isEdit ? 'Editar producto' : 'Nuevo producto',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _name,
              label: 'Nombre',
              required: true,
              hint: 'Nombre del producto',
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Requerido' : null,
            ),
            const SizedBox(height: 16),
            categoriesAsync.when(
              loading: () => const _CategoryPlaceholder(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
              ),
              error: (e, _) => _CategoryError(
                onRetry: () => ref.invalidate(productCategoriesProvider),
              ),
              data: (categories) => _buildCategorySelect(categories),
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _price,
              label: 'Precio',
              hint: '0',
              prefixText: r'$ ',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: (v) {
                final value = double.tryParse((v ?? '').replaceAll(',', ''));
                if (value == null || value < 0) return 'Valor inválido';
                return null;
              },
            ),
            const SizedBox(height: 4),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Activo',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              value: _active,
              onChanged: (v) => setState(() => _active = v),
            ),
            const SizedBox(height: 16),
            categoriesAsync.maybeWhen(
              data: (_) => PrimaryButton(
                label: 'Guardar',
                icon: Icons.check_rounded,
                loading: _saving,
                onPressed: _categoryId == null ? null : _submit,
              ),
              orElse: () => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySelect(List<ProductCategory> active) {
    // Opciones = categorías activas. Al editar, si la categoría actual del
    // producto está inactiva (no viene en la lista activa), se agrega para poder
    // mostrarla y conservarla.
    final options = <SelectOption<String>>[
      for (final c in active) SelectOption(c.id, c.name),
    ];
    final current = widget.product;
    if (current != null && !active.any((c) => c.id == current.categoryId)) {
      options.insert(
        0,
        SelectOption(current.categoryId, '${current.categoryName} (inactiva)'),
      );
    }

    if (options.isEmpty) {
      return const _CategoryPlaceholder(
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Text('No hay categorías disponibles.'),
        ),
      );
    }

    // Fija el valor por defecto (creación) en el primer build con datos.
    _categoryId ??= options.first.value;
    if (!options.any((o) => o.value == _categoryId)) {
      _categoryId = options.first.value;
    }

    return AppSelectField<String>(
      label: 'Categoría',
      required: true,
      icon: Icons.sell_rounded,
      value: _categoryId!,
      options: options,
      onChanged: (id) => setState(() => _categoryId = id),
    );
  }
}

class _CategoryPlaceholder extends StatelessWidget {
  final Widget child;
  const _CategoryPlaceholder({required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 2, bottom: 8),
          child: Text(
            'Categoría',
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: AppRadii.all(AppRadii.md),
          ),
          child: child,
        ),
      ],
    );
  }
}

class _CategoryError extends StatelessWidget {
  final VoidCallback onRetry;
  const _CategoryError({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return _CategoryPlaceholder(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(Icons.error_rounded, color: AppColors.coral, size: 20),
            const SizedBox(width: 8),
            const Expanded(
              child: Text('No se pudieron cargar las categorías.'),
            ),
            TextButton(onPressed: onRetry, child: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }
}
