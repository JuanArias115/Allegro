import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/cards.dart';
import '../../models/enums.dart';
import '../../models/product.dart';
import '../../providers.dart';

/// Devuelve true si se creó/actualizó un producto.
Future<bool> showProductFormSheet(BuildContext context, WidgetRef ref, {Product? product}) async {
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
  late ProductCategory _category;
  late bool _active;
  bool _saving = false;

  bool get _isEdit => widget.product != null;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _name = TextEditingController(text: p?.name ?? '');
    _price = TextEditingController(text: p != null ? p.currentPrice.toStringAsFixed(0) : '');
    _category = p?.category ?? ProductCategory.beverages;
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
    setState(() => _saving = true);
    final repo = ref.read(productRepositoryProvider);
    final price = double.parse(_price.text.replaceAll(',', ''));
    try {
      if (_isEdit) {
        await repo.update(widget.product!.id,
            name: _name.text.trim(), category: _category, currentPrice: price, isActive: _active);
      } else {
        await repo.create(
            name: _name.text.trim(), category: _category, currentPrice: price, isActive: _active);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16, right: 16, top: 8, bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(_isEdit ? 'Editar producto' : 'Nuevo producto',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            AppTextField(
              controller: _name,
              label: 'Nombre',
              required: true,
              hint: 'Nombre del producto',
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
            ),
            const SizedBox(height: 16),
            AppSelectField<ProductCategory>(
              label: 'Categoría',
              value: _category,
              options: [
                for (final c in ProductCategory.values)
                  SelectOption(c, c.label, icon: categoryIcon(c), color: categoryColor(c)),
              ],
              onChanged: (c) => setState(() => _category = c),
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _price,
              label: 'Precio',
              hint: '0',
              prefixText: r'$ ',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (v) {
                final value = double.tryParse((v ?? '').replaceAll(',', ''));
                if (value == null || value < 0) return 'Valor inválido';
                return null;
              },
            ),
            const SizedBox(height: 4),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Activo', style: TextStyle(fontWeight: FontWeight.w600)),
              value: _active,
              onChanged: (v) => setState(() => _active = v),
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              label: 'Guardar',
              icon: Icons.check_rounded,
              loading: _saving,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
