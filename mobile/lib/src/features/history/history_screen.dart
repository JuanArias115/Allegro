import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/reservation_card.dart';
import '../../models/enums.dart';
import '../../providers.dart';

/// Historial: muestra finalizadas y canceladas, separadas de las activas.
class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  String _text = '';
  ReservationStatus _status = ReservationStatus.completed;

  @override
  Widget build(BuildContext context) {
    final filter = ReservationFilter(
      text: _text.trim().isEmpty ? null : _text.trim(),
      status: _status,
    );
    final listAsync = ref.watch(reservationListProvider(filter));

    return Scaffold(
      appBar: AppBar(title: const Text('Historial')),
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
          Padding(
            padding: const EdgeInsets.all(12),
            child: SegmentedButton<ReservationStatus>(
              segments: const [
                ButtonSegment(value: ReservationStatus.completed, label: Text('Finalizadas')),
                ButtonSegment(value: ReservationStatus.cancelled, label: Text('Canceladas')),
              ],
              selected: {_status},
              onSelectionChanged: (s) => setState(() => _status = s.first),
            ),
          ),
          Expanded(
            child: listAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => ErrorRetry(
                  error: e, onRetry: () => ref.invalidate(reservationListProvider(filter))),
              data: (items) {
                if (items.isEmpty) {
                  return EmptyState(
                    icon: Icons.inventory_2_outlined,
                    title: _status == ReservationStatus.completed
                        ? 'Sin reservas finalizadas'
                        : 'Sin reservas canceladas',
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                  itemCount: items.length,
                  itemBuilder: (c, i) => ReservationCard(
                    reservation: items[i],
                    onTap: () => context.push('/reservations/${items[i].id}'),
                  ),
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
