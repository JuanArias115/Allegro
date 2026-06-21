import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/tokens.dart';
import '../../core/formatters.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/cards.dart';
import '../../core/widgets/feedback.dart';
import '../../core/widgets/state_views.dart';
import '../../core/widgets/status_badge.dart';
import '../../core/whatsapp.dart';
import '../../models/enums.dart';
import '../../models/reservation.dart';
import '../../providers.dart';
import '../whatsapp/whatsapp_preview_sheet.dart';
import 'add_consumption_sheet.dart';
import 'add_payment_sheet.dart';

class ReservationDetailScreen extends ConsumerWidget {
  final String id;
  const ReservationDetailScreen({super.key, required this.id});

  void _refresh(WidgetRef ref) {
    ref.invalidate(reservationDetailProvider(id));
    ref.invalidate(todayProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(reservationDetailProvider(id));

    return AppScaffold(
      header: AppHeader(
        title: 'Reserva',
        onBack: () => context.pop(),
        actions: [
          async.maybeWhen(
            data: (r) => _Menu(reservation: r, onChanged: () => _refresh(ref)),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: async.when(
        loading: () => const LoadingState(),
        error: (e, _) => ErrorState(error: e, onRetry: () => _refresh(ref)),
        data: (r) => _Detail(reservation: r, onChanged: () => _refresh(ref)),
      ),
    );
  }
}

class _Detail extends ConsumerWidget {
  final Reservation reservation;
  final VoidCallback onChanged;
  const _Detail({required this.reservation, required this.onChanged});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = reservation;
    final repo = ref.read(reservationRepositoryProvider);
    final canEdit =
        r.status == ReservationStatus.confirmed ||
        r.status == ReservationStatus.checkedIn;
    final payState = paymentStateOf(r.balance, r.checkOut, DateTime.now());
    final payColor = paymentColor(payState);

    Future<void> guard(Future<void> Function() action, String okMsg) async {
      try {
        await action();
        onChanged();
        if (context.mounted) {
          AppSnackBar.show(context, okMsg, type: AppMessageType.success);
        }
      } catch (e) {
        if (context.mounted) {
          AppSnackBar.show(context, '$e', type: AppMessageType.error);
        }
      }
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.x5,
        AppSpacing.x2,
        AppSpacing.x5,
        AppSpacing.x8,
      ),
      children: [
        AppCard(
          padding: const EdgeInsets.all(AppSpacing.x5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      r.guestName,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  const SizedBox(width: 8),
                  StatusBadge.reservation(r.status),
                ],
              ),
              const SizedBox(height: AppSpacing.x4),
              _info(context, Icons.cabin_rounded, 'Domo', r.domeName),
              _info(
                context,
                Icons.calendar_today_rounded,
                'Fechas',
                '${Formatters.date(r.checkIn)} → ${Formatters.date(r.checkOut)} · ${Formatters.nights(r.checkIn, r.checkOut)} noche(s)',
              ),
              _info(
                context,
                Icons.people_alt_rounded,
                'Huéspedes',
                '${r.guestCount}',
              ),
              _info(context, Icons.phone_rounded, 'Teléfono', r.phone),
              if (r.notes != null && r.notes!.isNotEmpty)
                _info(context, Icons.notes_rounded, 'Notas', r.notes!),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.x3),
        _MoneyCard(reservation: r, payColor: payColor),
        SectionHeader(
          title: 'Abonos · ${r.payments.length}',
          padding: const EdgeInsets.fromLTRB(
            2,
            AppSpacing.x6,
            2,
            AppSpacing.x3,
          ),
        ),
        if (r.payments.isEmpty)
          _muted(context, 'Aún no hay abonos registrados.')
        else
          for (final p in r.payments)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.x2),
              child: AppCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    const CategoryIcon(
                      icon: Icons.payments_rounded,
                      color: AppColors.forest,
                      size: 40,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            Formatters.money(p.amount),
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${p.method.label} · ${Formatters.dateTime(p.paidAt)}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        SectionHeader(
          title: 'Consumos · ${r.consumptions.length}',
          padding: const EdgeInsets.fromLTRB(
            2,
            AppSpacing.x5,
            2,
            AppSpacing.x3,
          ),
        ),
        if (r.consumptions.isEmpty)
          _muted(context, 'Sin consumos adicionales.')
        else
          for (final c in r.consumptions)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.x2),
              child: AppCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    const CategoryIcon(
                      icon: Icons.local_cafe_rounded,
                      color: AppColors.blue,
                      size: 40,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${c.quantity}x ${c.productName}',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${Formatters.money(c.unitPrice)} c/u',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    Text(
                      Formatters.money(c.subtotal),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    if (canEdit)
                      IconButton(
                        icon: const Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: AppColors.coral,
                        ),
                        onPressed: () => guard(
                          () => repo.removeConsumption(r.id, c.id),
                          'Consumo eliminado',
                        ),
                      ),
                  ],
                ),
              ),
            ),
        if (canEdit) ...[
          const SizedBox(height: AppSpacing.x6),
          Row(
            children: [
              Expanded(
                child: SecondaryButton(
                  label: 'Abono',
                  icon: Icons.add_card_rounded,
                  expand: true,
                  onPressed: () async {
                    final res = await showAddPaymentSheet(context);
                    if (res != null) {
                      await guard(
                        () => repo.addPayment(
                          r.id,
                          amount: res.amount,
                          method: res.method,
                          note: res.note,
                        ),
                        'Abono registrado',
                      );
                    }
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.x3),
              Expanded(
                child: SecondaryButton(
                  label: 'Consumo',
                  icon: Icons.local_cafe_rounded,
                  expand: true,
                  color: AppColors.blue,
                  onPressed: () async {
                    final res = await showAddConsumptionSheet(context, ref);
                    if (res != null) {
                      await guard(
                        () => repo.addConsumption(
                          r.id,
                          productId: res.productId,
                          quantity: res.quantity,
                        ),
                        'Consumo agregado',
                      );
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.x3),
          PrimaryButton(
            label: 'Checkout',
            icon: Icons.point_of_sale_rounded,
            onPressed: () => context.push('/reservations/${r.id}/checkout'),
          ),
        ],
      ],
    );
  }

  Widget _info(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: scheme.outline),
          const SizedBox(width: 12),
          SizedBox(
            width: 84,
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _muted(BuildContext context, String text) => Padding(
    padding: const EdgeInsets.only(left: 4),
    child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
  );
}

class _MoneyCard extends StatelessWidget {
  final Reservation reservation;
  final Color payColor;
  const _MoneyCard({required this.reservation, required this.payColor});

  @override
  Widget build(BuildContext context) {
    final r = reservation;
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.x5),
      child: Column(
        children: [
          _row(context, 'Alojamiento', Formatters.money(r.lodgingPrice)),
          const SizedBox(height: 8),
          _row(context, 'Consumos', Formatters.money(r.totalConsumptions)),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Divider(
              height: 1,
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
          _row(context, 'Total', Formatters.money(r.totalDue), bold: true),
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
            r.balance > 0 ? 'Saldo pendiente' : 'Saldo',
            Formatters.money(r.balance),
            bold: true,
            color: payColor,
          ),
        ],
      ),
    );
  }

  Widget _row(
    BuildContext context,
    String label,
    String value, {
    bool bold = false,
    Color? color,
  }) {
    final style = TextStyle(
      fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
      fontSize: bold ? 17 : 15,
      color: color,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: bold ? 16 : 14.5,
            color: color ?? Theme.of(context).colorScheme.onSurface,
          ),
        ),
        Text(value, style: style),
      ],
    );
  }
}

class _Menu extends ConsumerWidget {
  final Reservation reservation;
  final VoidCallback onChanged;
  const _Menu({required this.reservation, required this.onChanged});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(reservationRepositoryProvider);
    final r = reservation;
    final active =
        r.status != ReservationStatus.completed &&
        r.status != ReservationStatus.cancelled;

    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert_rounded),
      shape: RoundedRectangleBorder(borderRadius: AppRadii.all(AppRadii.md)),
      onSelected: (value) async {
        if (value == 'edit') {
          context.push('/reservations/${r.id}/edit');
        } else if (value.startsWith('status:')) {
          final status = ReservationStatus.fromWire(value.substring(7));
          try {
            await repo.changeStatus(r.id, status);
            onChanged();
            if (context.mounted) {
              AppSnackBar.show(
                context,
                'Estado actualizado',
                type: AppMessageType.success,
              );
            }
          } catch (e) {
            if (context.mounted) {
              AppSnackBar.show(context, '$e', type: AppMessageType.error);
            }
          }
        } else if (value.startsWith('wa:')) {
          final t = WhatsAppTemplate.values.firstWhere(
            (t) => t.name == value.substring(3),
          );
          if (context.mounted) {
            await showWhatsAppPreview(context, r, initial: t);
          }
        }
      },
      itemBuilder: (context) => [
        if (active)
          const PopupMenuItem(
            value: 'edit',
            child: _MenuRow(icon: Icons.edit_rounded, label: 'Editar'),
          ),
        for (final s in ReservationStatus.values)
          if (s != r.status)
            PopupMenuItem(
              value: 'status:${s.wire}',
              child: _MenuRow(
                icon: reservationStatusIcon(s),
                label: 'Marcar: ${s.label}',
              ),
            ),
        const PopupMenuDivider(),
        for (final t in WhatsAppTemplate.values)
          PopupMenuItem(
            value: 'wa:${t.name}',
            child: _MenuRow(icon: Icons.chat_rounded, label: t.label),
          ),
      ],
    );
  }
}

class _MenuRow extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MenuRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Theme.of(context).colorScheme.outline),
        const SizedBox(width: 12),
        Flexible(child: Text(label)),
      ],
    );
  }
}
