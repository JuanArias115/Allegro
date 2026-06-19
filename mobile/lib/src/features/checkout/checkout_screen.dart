import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/formatters.dart';
import '../../core/whatsapp.dart';
import '../../core/widgets/common_widgets.dart';
import '../../models/enums.dart';
import '../../models/reservation.dart';
import '../../providers.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  final String id;
  const CheckoutScreen({super.key, required this.id});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _finalAmount = TextEditingController();
  PaymentMethod _method = PaymentMethod.cash;
  bool _submitting = false;

  @override
  void dispose() {
    _finalAmount.dispose();
    super.dispose();
  }

  Future<void> _confirm(Reservation r) async {
    final amount = double.tryParse(_finalAmount.text.replaceAll(',', '')) ?? 0;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirmar cierre'),
        content: Text(amount > 0
            ? 'Se registrará un pago final de ${Formatters.money(amount)} y la reserva quedará finalizada.'
            : 'La reserva quedará finalizada. ¿Continuar?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Finalizar')),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _submitting = true);
    try {
      await ref.read(reservationRepositoryProvider).checkout(
            r.id,
            finalAmount: amount > 0 ? amount : null,
            finalMethod: _method,
            finalNote: 'Pago final de checkout',
          );
      ref.invalidate(reservationDetailProvider(r.id));
      ref.invalidate(todayProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reserva finalizada.')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(reservationDetailProvider(widget.id));
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorRetry(error: e, onRetry: () => ref.invalidate(reservationDetailProvider(widget.id))),
        data: (r) {
          final alreadyClosed = r.status == ReservationStatus.completed || r.status == ReservationStatus.cancelled;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: [
              Text(r.guestName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              Text('${r.domeName} · ${Formatters.dateRange(r.checkIn, r.checkOut)}',
                  style: TextStyle(color: scheme.outline)),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _row('Alojamiento', Formatters.money(r.lodgingPrice)),
                      const SizedBox(height: 8),
                      if (r.consumptions.isEmpty)
                        Text('Sin consumos', style: TextStyle(color: scheme.outline))
                      else
                        ...r.consumptions.map((c) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: _row('${c.quantity}x ${c.productName}', Formatters.money(c.subtotal),
                                  muted: true),
                            )),
                      const Divider(),
                      _row('Total consumos', Formatters.money(r.totalConsumptions)),
                      _row('Total cuenta', Formatters.money(r.totalDue), bold: true),
                      _row('Abonado', Formatters.money(r.totalPaid)),
                      _row('Saldo pendiente', Formatters.money(r.balance),
                          bold: true, color: r.balance > 0 ? scheme.error : scheme.primary),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                icon: const Icon(Icons.share),
                label: const Text('Compartir resumen por WhatsApp'),
                onPressed: () => WhatsAppMessages.share(
                    WhatsAppMessages.build(WhatsAppTemplate.accountSummary, r)),
              ),
              const SizedBox(height: 16),
              if (alreadyClosed)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(children: [
                    const Icon(Icons.info_outline),
                    const SizedBox(width: 8),
                    Expanded(child: Text('Esta reserva ya está ${r.status.label.toLowerCase()}.')),
                  ]),
                )
              else ...[
                Text('Registrar pago final (opcional)',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                TextField(
                  controller: _finalAmount,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Valor',
                    prefixText: r'$ ',
                    helperText: r.balance > 0 ? 'Saldo pendiente: ${Formatters.money(r.balance)}' : null,
                  ),
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
                const SizedBox(height: 20),
                FilledButton.icon(
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Finalizar reserva'),
                  onPressed: _submitting ? null : () => _confirm(r),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _row(String label, String value, {bool bold = false, bool muted = false, Color? color}) {
    final scheme = Theme.of(context).colorScheme;
    final style = TextStyle(
      fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
      color: color ?? (muted ? scheme.outline : null),
      fontSize: bold ? 16 : 14,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [Flexible(child: Text(label, style: style)), Text(value, style: style)],
    );
  }
}
