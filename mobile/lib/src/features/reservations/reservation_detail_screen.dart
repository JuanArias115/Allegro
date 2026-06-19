import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/formatters.dart';
import '../../core/whatsapp.dart';
import '../../core/widgets/common_widgets.dart';
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reserva'),
        actions: [
          async.maybeWhen(
            data: (r) => _Menu(reservation: r, onChanged: () => _refresh(ref)),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorRetry(error: e, onRetry: () => _refresh(ref)),
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
    final scheme = Theme.of(context).colorScheme;
    final repo = ref.read(reservationRepositoryProvider);
    final canEdit = r.status == ReservationStatus.confirmed || r.status == ReservationStatus.checkedIn;

    Future<void> guard(Future<void> Function() action) async {
      try {
        await action();
        onChanged();
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
        }
      }
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 32),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(r.guestName,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                    ),
                    StatusChip(r.status),
                  ],
                ),
                const SizedBox(height: 12),
                _InfoRow(Icons.cabin_rounded, 'Domo', r.domeName),
                _InfoRow(Icons.calendar_today_rounded, 'Fechas',
                    '${Formatters.date(r.checkIn)} → ${Formatters.date(r.checkOut)} (${Formatters.nights(r.checkIn, r.checkOut)} noches)'),
                _InfoRow(Icons.people_alt_rounded, 'Huéspedes', '${r.guestCount}'),
                _InfoRow(Icons.phone_rounded, 'Teléfono', r.phone),
                if (r.notes != null && r.notes!.isNotEmpty)
                  _InfoRow(Icons.notes_rounded, 'Notas', r.notes!),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        _MoneyCard(reservation: r),
        SectionHeader('Abonos (${r.payments.length})'),
        if (r.payments.isEmpty)
          _MutedTile('Aún no hay abonos registrados.')
        else
          ...r.payments.map((p) => Card(
                child: ListTile(
                  leading: const Icon(Icons.payments_outlined),
                  title: Text(Formatters.money(p.amount)),
                  subtitle: Text('${p.method.label} · ${Formatters.dateTime(p.paidAt)}'
                      '${p.note != null && p.note!.isNotEmpty ? '\n${p.note}' : ''}'),
                  isThreeLine: p.note != null && p.note!.isNotEmpty,
                ),
              )),
        SectionHeader('Consumos (${r.consumptions.length})'),
        if (r.consumptions.isEmpty)
          _MutedTile('Sin consumos adicionales.')
        else
          ...r.consumptions.map((c) => Card(
                child: ListTile(
                  leading: const Icon(Icons.local_cafe_outlined),
                  title: Text('${c.quantity}x ${c.productName}'),
                  subtitle: Text('${Formatters.money(c.unitPrice)} c/u'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(Formatters.money(c.subtotal),
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      if (canEdit)
                        IconButton(
                          icon: Icon(Icons.close, size: 18, color: scheme.error),
                          onPressed: () => guard(() => repo.removeConsumption(r.id, c.id)),
                        ),
                    ],
                  ),
                ),
              )),
        const SizedBox(height: 20),
        if (canEdit) ...[
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.add_card),
                  label: const Text('Abono'),
                  onPressed: () async {
                    final result = await showAddPaymentSheet(context);
                    if (result != null) {
                      await guard(() => repo.addPayment(r.id,
                          amount: result.amount, method: result.method, note: result.note));
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.local_cafe_outlined),
                  label: const Text('Consumo'),
                  onPressed: () async {
                    final result = await showAddConsumptionSheet(context, ref);
                    if (result != null) {
                      await guard(() => repo.addConsumption(r.id,
                          productId: result.productId, quantity: result.quantity));
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            icon: const Icon(Icons.point_of_sale_rounded),
            label: const Text('Checkout'),
            onPressed: () => context.push('/reservations/${r.id}/checkout'),
          ),
        ],
      ],
    );
  }
}

class _MoneyCard extends StatelessWidget {
  final Reservation reservation;
  const _MoneyCard({required this.reservation});

  @override
  Widget build(BuildContext context) {
    final r = reservation;
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _MoneyRow('Alojamiento', r.lodgingPrice),
            _MoneyRow('Consumos', r.totalConsumptions),
            const Divider(),
            _MoneyRow('Total', r.totalDue, bold: true),
            _MoneyRow('Abonado', r.totalPaid, color: scheme.primary),
            _MoneyRow('Saldo pendiente', r.balance,
                bold: true, color: r.balance > 0 ? scheme.error : scheme.primary),
          ],
        ),
      ),
    );
  }
}

class _MoneyRow extends StatelessWidget {
  final String label;
  final double value;
  final bool bold;
  final Color? color;
  const _MoneyRow(this.label, this.value, {this.bold = false, this.color});

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
      color: color,
      fontSize: bold ? 16 : 14,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(label, style: style), Text(Formatters.money(value), style: style)],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: scheme.outline),
          const SizedBox(width: 10),
          SizedBox(
            width: 86,
            child: Text(label, style: TextStyle(color: scheme.outline)),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}

class _MutedTile extends StatelessWidget {
  final String text;
  const _MutedTile(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Text(text, style: TextStyle(color: Theme.of(context).colorScheme.outline)),
      );
}

/// Menú de acciones: editar, cambiar estado y compartir por WhatsApp.
class _Menu extends ConsumerWidget {
  final Reservation reservation;
  final VoidCallback onChanged;
  const _Menu({required this.reservation, required this.onChanged});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(reservationRepositoryProvider);
    final r = reservation;

    return PopupMenuButton<String>(
      onSelected: (value) async {
        if (value == 'edit') {
          context.push('/reservations/${r.id}/edit');
          return;
        }
        if (value.startsWith('status:')) {
          final status = ReservationStatus.fromWire(value.substring(7));
          try {
            await repo.changeStatus(r.id, status);
            onChanged();
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
            }
          }
          return;
        }
        if (value.startsWith('wa:')) {
          final template = WhatsAppTemplate.values.firstWhere((t) => t.name == value.substring(3));
          if (context.mounted) await showWhatsAppPreview(context, r, initial: template);
        }
      },
      itemBuilder: (context) => [
        if (r.status != ReservationStatus.completed && r.status != ReservationStatus.cancelled)
          const PopupMenuItem(value: 'edit', child: Text('Editar')),
        const PopupMenuDivider(),
        for (final s in ReservationStatus.values)
          if (s != r.status)
            PopupMenuItem(value: 'status:${s.wire}', child: Text('Marcar: ${s.label}')),
        const PopupMenuDivider(),
        for (final t in WhatsAppTemplate.values)
          PopupMenuItem(value: 'wa:${t.name}', child: Text('WhatsApp: ${t.label}')),
      ],
    );
  }
}
