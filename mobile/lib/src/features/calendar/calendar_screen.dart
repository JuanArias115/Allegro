import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/tokens.dart';
import '../../core/formatters.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/cards.dart';
import '../../core/widgets/state_views.dart';
import '../../models/dome.dart';
import '../../models/enums.dart';
import '../../models/reservation.dart';
import '../../providers.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  late DateTime _month = _firstOf(DateTime.now());
  late DateTime _selected = _dayOnly(DateTime.now());

  static DateTime _firstOf(DateTime d) => DateTime(d.year, d.month, 1);
  static DateTime _dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  bool _covers(ReservationSummary r, DateTime day) {
    final inDay = _dayOnly(r.checkIn);
    final outDay = _dayOnly(r.checkOut);
    return !day.isBefore(inDay) && day.isBefore(outDay);
  }

  @override
  Widget build(BuildContext context) {
    const filter = ReservationFilter();
    final async = ref.watch(reservationListProvider(filter));
    final domes = ref.watch(domesProvider).valueOrNull ?? const <Dome>[];

    return AppScaffold(
      header: const AppHeader(title: 'Calendario'),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.forest,
        foregroundColor: AppColors.white,
        onPressed: () => context.push(
          '/reservations/new?date=${_selected.toIso8601String().substring(0, 10)}',
        ),
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Reservar',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: async.when(
        loading: () => const LoadingState(),
        error: (e, _) => ErrorState(
          error: e,
          onRetry: () => ref.invalidate(reservationListProvider(filter)),
        ),
        data: (allRaw) {
          final all = allRaw
              .where((r) => r.status != ReservationStatus.cancelled)
              .toList();
          final domeIndex = {
            for (var i = 0; i < domes.length; i++) domes[i].id: i,
          };
          final dayItems = all.where((r) => _covers(r, _selected)).toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.x5,
              AppSpacing.x2,
              AppSpacing.x5,
              120,
            ),
            children: [
              _MonthCard(
                month: _month,
                selected: _selected,
                reservations: all,
                domeIndex: domeIndex,
                covers: _covers,
                onPrev: () => setState(
                  () => _month = DateTime(_month.year, _month.month - 1, 1),
                ),
                onNext: () => setState(
                  () => _month = DateTime(_month.year, _month.month + 1, 1),
                ),
                onSelect: (d) => setState(() => _selected = d),
              ),
              const SizedBox(height: AppSpacing.x4),
              _Legend(domes: domes),
              SectionHeader(
                title: Formatters.weekdayDate(_selected),
                padding: const EdgeInsets.fromLTRB(
                  2,
                  AppSpacing.x5,
                  2,
                  AppSpacing.x3,
                ),
              ),
              if (dayItems.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: AppSpacing.x4),
                  child: EmptyState(
                    icon: Icons.event_available_rounded,
                    title: 'Día libre',
                    message: 'No hay reservas para este día.',
                    accent: AppColors.blue,
                  ),
                )
              else
                for (var i = 0; i < dayItems.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.x3),
                    child: ReservationCard(
                      reservation: dayItems[i],
                      onTap: () =>
                          context.push('/reservations/${dayItems[i].id}'),
                    ),
                  ),
            ],
          );
        },
      ),
    );
  }
}

class _MonthCard extends StatelessWidget {
  final DateTime month;
  final DateTime selected;
  final List<ReservationSummary> reservations;
  final Map<String, int> domeIndex;
  final bool Function(ReservationSummary, DateTime) covers;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final ValueChanged<DateTime> onSelect;

  const _MonthCard({
    required this.month,
    required this.selected,
    required this.reservations,
    required this.domeIndex,
    required this.covers,
    required this.onPrev,
    required this.onNext,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final leadOffset =
        (DateTime(month.year, month.month, 1).weekday + 6) % 7; // Lun = 0
    final totalCells = ((leadOffset + daysInMonth) / 7).ceil() * 7;
    final today = DateTime.now();

    return AppCard(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.x4,
        AppSpacing.x4,
        AppSpacing.x4,
        AppSpacing.x3,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  Formatters.monthYear(month),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              _NavBtn(icon: Icons.chevron_left_rounded, onTap: onPrev),
              const SizedBox(width: 8),
              _NavBtn(icon: Icons.chevron_right_rounded, onTap: onNext),
            ],
          ),
          const SizedBox(height: AppSpacing.x3),
          Row(
            children: [
              for (final d in const ['L', 'M', 'X', 'J', 'V', 'S', 'D'])
                Expanded(
                  child: Center(
                    child: Text(
                      d,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: scheme.outline,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: totalCells,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 0.72,
            ),
            itemBuilder: (context, i) {
              final dayNum = i - leadOffset + 1;
              if (dayNum < 1 || dayNum > daysInMonth) {
                return const SizedBox.shrink();
              }
              final date = DateTime(month.year, month.month, dayNum);
              final isToday =
                  date.year == today.year &&
                  date.month == today.month &&
                  date.day == today.day;
              final isSelected = date == selected;

              final occupied = <int>{};
              for (final r in reservations) {
                if (covers(r, date)) {
                  occupied.add(domeIndex[r.domeId] ?? 0);
                }
              }
              final domeCount = domeIndex.isEmpty ? 2 : domeIndex.length;

              return _DayCell(
                day: dayNum,
                isToday: isToday,
                isSelected: isSelected,
                occupied: occupied,
                domeCount: domeCount,
                onTap: () => onSelect(date),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  final int day;
  final bool isToday;
  final bool isSelected;
  final Set<int> occupied;
  final int domeCount;
  final VoidCallback onTap;

  const _DayCell({
    required this.day,
    required this.isToday,
    required this.isSelected,
    required this.occupied,
    required this.domeCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final Color numberColor = isSelected
        ? AppColors.white
        : isToday
        ? AppColors.forest
        : scheme.onSurface;

    return InkWell(
      onTap: onTap,
      borderRadius: AppRadii.all(AppRadii.sm),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected
                  ? AppColors.forest
                  : (isToday ? AppColors.mint : Colors.transparent),
            ),
            child: Text(
              '$day',
              style: TextStyle(
                fontSize: 14,
                fontWeight: isToday || isSelected
                    ? FontWeight.w800
                    : FontWeight.w600,
                color: numberColor,
              ),
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 4 * domeCount + (domeCount - 1) * 2,
            child: Column(
              children: [
                for (var d = 0; d < domeCount; d++) ...[
                  if (d > 0) const SizedBox(height: 2),
                  Container(
                    width: 16,
                    height: 4,
                    decoration: BoxDecoration(
                      color: occupied.contains(d)
                          ? domeColor(d)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _NavBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.mint,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 38,
          height: 38,
          child: Icon(icon, color: AppColors.forest, size: 22),
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final List<Dome> domes;
  const _Legend({required this.domes});

  @override
  Widget build(BuildContext context) {
    if (domes.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: AppSpacing.x4,
      runSpacing: AppSpacing.x2,
      children: [
        for (var i = 0; i < domes.length; i++)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 14,
                height: 6,
                decoration: BoxDecoration(
                  color: domeColor(i),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 6),
              Text(domes[i].name, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
      ],
    );
  }
}
