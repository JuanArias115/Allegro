import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/tokens.dart';
import '../../core/formatters.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/cards.dart';
import '../../core/widgets/state_views.dart';
import '../../models/reservation.dart';
import '../../models/today.dart';
import '../../providers.dart';

class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todayAsync = ref.watch(todayProvider);
    final domes = ref.watch(domesProvider).valueOrNull ?? const [];

    return AppScaffold(
      header: AppHeader(
        eyebrow: Formatters.weekdayDate(DateTime.now()),
        title: 'Hoy en Allegro',
        actions: [
          AppIconButton(
            icon: Icons.refresh_rounded,
            tooltip: 'Actualizar',
            onTap: () => ref.invalidate(todayProvider),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.forest,
        foregroundColor: AppColors.white,
        onPressed: () => context.push('/reservations/new'),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nueva reserva', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: todayAsync.when(
        loading: () => const LoadingState(),
        error: (e, _) => ErrorState(error: e, onRetry: () => ref.invalidate(todayProvider)),
        data: (today) => RefreshIndicator(
          color: AppColors.forest,
          onRefresh: () async => ref.invalidate(todayProvider),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(AppSpacing.x5, AppSpacing.x2, AppSpacing.x5, 120),
            children: [
              _OccupancyCard(today: today, totalDomes: domes.isEmpty ? 2 : domes.length),
              const SizedBox(height: AppSpacing.x3),
              Row(
                children: [
                  Expanded(child: MiniStat(icon: Icons.login_rounded, color: AppColors.blue, count: today.arrivals.length, label: 'Llegadas')),
                  const SizedBox(width: AppSpacing.x3),
                  Expanded(child: MiniStat(icon: Icons.logout_rounded, color: AppColors.coral, count: today.departures.length, label: 'Salidas')),
                  const SizedBox(width: AppSpacing.x3),
                  Expanded(child: MiniStat(icon: Icons.upcoming_rounded, color: AppColors.violet, count: today.upcoming.length, label: 'Próximas')),
                ],
              ),
              if (today.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 40),
                  child: EmptyState(
                    icon: Icons.wb_sunny_rounded,
                    title: 'Un día tranquilo',
                    message: 'No hay llegadas, salidas ni domos ocupados hoy.',
                    accent: AppColors.yellow,
                  ),
                ),
              _Section(title: 'Llegadas', items: today.arrivals),
              _Section(title: 'Domos ocupados', items: today.currentlyHosted),
              _Section(title: 'Próximas reservas', items: today.upcoming),
            ],
          ),
        ),
      ),
    );
  }
}

class _OccupancyCard extends StatelessWidget {
  final TodayState today;
  final int totalDomes;
  const _OccupancyCard({required this.today, required this.totalDomes});

  @override
  Widget build(BuildContext context) {
    final occupiedDomes = today.currentlyHosted.map((r) => r.domeId).toSet().length;
    return AppearAnimation(
      child: SummaryCard(
        title: 'Ocupación de hoy',
        value: '$occupiedDomes de $totalDomes',
        subtitle: occupiedDomes == 0
            ? 'domos ocupados · todo libre'
            : 'domos ocupados',
        trailing: Row(
          children: [
            for (var i = 0; i < totalDomes; i++)
              Padding(
                padding: const EdgeInsets.only(left: 6),
                child: Icon(
                  i < occupiedDomes ? Icons.cabin_rounded : Icons.cabin_outlined,
                  color: i < occupiedDomes ? AppColors.white : Colors.white60,
                  size: 28,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<ReservationSummary> items;
  const _Section({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: '$title · ${items.length}', padding: const EdgeInsets.fromLTRB(2, AppSpacing.x6, 2, AppSpacing.x3)),
        for (var i = 0; i < items.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.x3),
            child: AppearAnimation(
              index: i,
              child: ReservationCard(
                reservation: items[i],
                onTap: () => context.push('/reservations/${items[i].id}'),
              ),
            ),
          ),
      ],
    );
  }
}
