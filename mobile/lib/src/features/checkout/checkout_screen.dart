import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/tokens.dart';
import '../../core/formatters.dart';
import '../../core/whatsapp.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/cards.dart';
import '../../core/widgets/feedback.dart';
import '../../core/widgets/state_views.dart';
import '../../core/widgets/status_badge.dart';
import '../../models/enums.dart';
import '../../models/reservation.dart';
import '../../providers.dart';
import '../whatsapp/whatsapp_preview_sheet.dart';

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
    final ok = await showConfirmationSheet(
      context,
      title: 'Finalizar reserva',
      message: amount > 0
          ? 'Se registrará un pago final de ${Formatters.money(amount)} y la reserva quedará finalizada.'
          : 'La reserva quedará marcada como finalizada.',
      confirmLabel: 'Finalizar',
      icon: Icons.point_of_sale_rounded,
    );
    if (!ok) return;

    setState(() => _submitting = true);
    try {
      await ref
          .read(reservationRepositoryProvider)
          .checkout(
            r.id,
            finalAmount: amount > 0 ? amount : null,
            finalMethod: _method,
            finalNote: 'Pago final de checkout',
          );
      ref.invalidate(reservationDetailProvider(r.id));
      ref.invalidate(todayProvider);
      if (mounted) {
        AppSnackBar.show(
          context,
          'Reserva finalizada',
          type: AppMessageType.success,
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.show(context, '$e', type: AppMessageType.error);
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(reservationDetailProvider(widget.id));

    return AppScaffold(
      header: AppHeader(title: 'Checkout', onBack: () => context.pop()),
      body: async.when(
        loading: () => const LoadingState(),
        error: (e, _) => ErrorState(
          error: e,
          onRetry: () => ref.invalidate(reservationDetailProvider(widget.id)),
        ),
        data: (r) {
          final closed =
              r.status == ReservationStatus.completed ||
              r.status == ReservationStatus.cancelled;
          final payColor = paymentColor(
            paymentStateOf(r.balance, r.checkOut, DateTime.now()),
          );
          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.x5,
              AppSpacing.x2,
              AppSpacing.x5,
              AppSpacing.x8,
            ),
            children: [
              Text(r.guestName, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 2),
              Text(
                '${r.domeName} · ${Formatters.dateRange(r.checkIn, r.checkOut)}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.x4),
              AppCard(
                padding: const EdgeInsets.all(AppSpacing.x5),
                child: Column(
                  children: [
                    _row(
                      context,
                      'Alojamiento',
                      Formatters.money(r.lodgingPrice),
                    ),
                    if (r.consumptions.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      ...r.consumptions.map(
                        (c) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: _row(
                            context,
                            '${c.quantity}x ${c.productName}',
                            Formatters.money(c.subtotal),
                            muted: true,
                          ),
                        ),
                      ),
                    ],
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Divider(
                        height: 1,
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                    _row(
                      context,
                      'Total cuenta',
                      Formatters.money(r.totalDue),
                      bold: true,
                    ),
                    const SizedBox(height: 8),
                    _row(
                      context,
                      'Abonado',
                      Formatters.money(r.totalPaid),
                      color: AppColors.forest,
                    ),
                    const SizedBox(height: 8),
                    _row(
                      context,
                      'Saldo pendiente',
                      Formatters.money(r.balance),
                      bold: true,
                      color: payColor,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.x3),
              SecondaryButton(
                label: 'Compartir resumen por WhatsApp',
                icon: Icons.chat_rounded,
                expand: true,
                onPressed: () => showWhatsAppPreview(
                  context,
                  r,
                  initial: WhatsAppTemplate.accountSummary,
                ),
              ),
              const SizedBox(height: AppSpacing.x5),
              if (closed)
                Container(
                  padding: const EdgeInsets.all(AppSpacing.x4),
                  decoration: BoxDecoration(
                    color: AppColors.forest.withValues(alpha: 0.10),
                    borderRadius: AppRadii.all(AppRadii.md),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.forest,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Esta reserva ya está ${r.status.label.toLowerCase()}.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                )
              else ...[
                Text(
                  'Registrar pago final (opcional)',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.x3),
                AppTextField(
                  controller: _finalAmount,
                  label: 'Valor',
                  hint: '0',
                  prefixText: r'$ ',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  helper: r.balance > 0
                      ? 'Saldo pendiente: ${Formatters.money(r.balance)}'
                      : null,
                ),
                const SizedBox(height: AppSpacing.x3),
                AppSelectField<PaymentMethod>(
                  label: 'Método',
                  icon: Icons.account_balance_wallet_rounded,
                  value: _method,
                  options: const [
                    SelectOption(
                      PaymentMethod.cash,
                      'Efectivo',
                      icon: Icons.payments_rounded,
                    ),
                    SelectOption(
                      PaymentMethod.transfer,
                      'Transferencia',
                      icon: Icons.swap_horiz_rounded,
                    ),
                    SelectOption(
                      PaymentMethod.other,
                      'Otro',
                      icon: Icons.more_horiz_rounded,
                    ),
                  ],
                  onChanged: (m) => setState(() => _method = m),
                ),
                const SizedBox(height: AppSpacing.x6),
                PrimaryButton(
                  label: 'Finalizar reserva',
                  icon: Icons.check_circle_rounded,
                  loading: _submitting,
                  onPressed: () => _confirm(r),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _row(
    BuildContext context,
    String label,
    String value, {
    bool bold = false,
    bool muted = false,
    Color? color,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            label,
            style: TextStyle(
              fontSize: bold ? 16 : 14.5,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              color: muted ? scheme.outline : (color ?? scheme.onSurface),
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: bold ? 17 : 14.5,
            fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
            color: muted ? scheme.outline : color,
          ),
        ),
      ],
    );
  }
}
