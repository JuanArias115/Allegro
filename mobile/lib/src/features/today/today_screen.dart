import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/formatters.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/reservation_card.dart';
import '../../models/reservation.dart';
import '../../providers.dart';

class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todayAsync = ref.watch(todayProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hoy'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(todayProvider),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/reservations/new'),
        icon: const Icon(Icons.add),
        label: const Text('Nueva reserva'),
      ),
      body: todayAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorRetry(error: e, onRetry: () => ref.invalidate(todayProvider)),
        data: (today) {
          if (today.isEmpty) {
            return const EmptyState(
              icon: Icons.wb_sunny_outlined,
              title: 'Sin actividad para hoy',
              message: 'No hay llegadas, salidas ni domos ocupados.',
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(todayProvider),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 96),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(Formatters.date(today.date),
                      style: TextStyle(color: Theme.of(context).colorScheme.outline)),
                ),
                _Section(title: 'Llegadas', icon: Icons.login_rounded, items: today.arrivals),
                _Section(title: 'Salidas', icon: Icons.logout_rounded, items: today.departures),
                _Section(title: 'Domos ocupados', icon: Icons.cabin_rounded, items: today.currentlyHosted),
                _Section(title: 'Próximas reservas', icon: Icons.upcoming_rounded, items: today.upcoming),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<ReservationSummary> items;
  const _Section({required this.title, required this.icon, required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader('$title (${items.length})'),
        for (final r in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: ReservationCard(
              reservation: r,
              onTap: () => context.push('/reservations/${r.id}'),
            ),
          ),
      ],
    );
  }
}
