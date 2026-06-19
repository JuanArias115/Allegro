import 'package:flutter/material.dart';

import '../../models/enums.dart';

typedef PaymentResult = ({double amount, PaymentMethod method, String? note});

Future<PaymentResult?> showAddPaymentSheet(BuildContext context) {
  return showModalBottomSheet<PaymentResult>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => const _AddPaymentSheet(),
  );
}

class _AddPaymentSheet extends StatefulWidget {
  const _AddPaymentSheet();

  @override
  State<_AddPaymentSheet> createState() => _AddPaymentSheetState();
}

class _AddPaymentSheetState extends State<_AddPaymentSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _note = TextEditingController();
  PaymentMethod _method = PaymentMethod.cash;

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context, (
      amount: double.parse(_amount.text.replaceAll(',', '')),
      method: _method,
      note: _note.text.trim().isEmpty ? null : _note.text.trim(),
    ));
  }

  @override
  Widget build(BuildContext context) {
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
            Text('Registrar abono', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amount,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Valor', prefixText: r'$ '),
              validator: (v) {
                final value = double.tryParse((v ?? '').replaceAll(',', ''));
                if (value == null || value <= 0) return 'Ingresa un valor mayor que cero';
                return null;
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<PaymentMethod>(
              initialValue: _method,
              decoration: const InputDecoration(labelText: 'Método'),
              items: [
                for (final m in PaymentMethod.values)
                  DropdownMenuItem(value: m, child: Text(m.label)),
              ],
              onChanged: (m) => setState(() => _method = m ?? PaymentMethod.cash),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _note,
              decoration: const InputDecoration(labelText: 'Nota (opcional)'),
            ),
            const SizedBox(height: 20),
            FilledButton(onPressed: _submit, child: const Text('Guardar abono')),
          ],
        ),
      ),
    );
  }
}
