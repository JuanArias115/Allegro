import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/reservation_card.dart';
import '../../models/enums.dart';
import '../../providers.dart';

class ReservationsListScreen extends ConsumerStatefulWidget {
  const ReservationsListScreen({super.key});

  @override
  ConsumerState<ReservationsListScreen> createState() => _ReservationsListScreenState();
}

class _ReservationsListScreenState extends ConsumerState<ReservationsListScreen> {
  String _text = '';
  ReservationStatus? _status;

  @override
  Widget build(BuildContext context) {
    final filter = ReservationFilter(
      text: _text.trim().isEmpty ? null : _text.trim(),
      status: _status,
      active: _status == null ? true : null, // por defecto, solo activas
    );
    final listAsync = ref.watch(reservationListProvider(filter));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reservas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Historial',
            onPressed: () => context.push('/history'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/reservations/new'),
        icon: const Icon(Icons.add),
        label: const Text('Nueva'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Buscar por nombre o teléfono',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (v) => setState(() => _text = v),
            ),
          ),
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: [
                _StatusFilterChip(
                  label: 'Activas',
                  selected: _status == null,
                  onTap: () => setState(() => _status = null),
                ),
                for (final s in ReservationStatus.values)
                  _StatusFilterChip(
                    label: s.label,
                    selected: _status == s,
                    onTap: () => setState(() => _status = s),
                  ),
              ],
            ),
          ),
          Expanded(
            child: listAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => ErrorRetry(
                  error: e, onRetry: () => ref.invalidate(reservationListProvider(filter))),
              data: (items) {
                if (items.isEmpty) {
                  return const EmptyState(
                    icon: Icons.event_busy_outlined,
                    title: 'Sin reservas',
                    message: 'No hay reservas que coincidan con el filtro.',
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(reservationListProvider(filter)),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 96),
                    itemCount: items.length,
                    itemBuilder: (c, i) => ReservationCard(
                      reservation: items[i],
                      onTap: () => context.push('/reservations/${items[i].id}'),
                    ),
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _StatusFilterChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
      ),
    );
  }
}
