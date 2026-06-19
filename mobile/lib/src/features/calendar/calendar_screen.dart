import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/reservation_card.dart';
import '../../models/enums.dart';
import '../../models/reservation.dart';
import '../../providers.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  DateTime _key(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Reservas activas que cubren un día dado (intervalo [llegada, salida)).
  List<ReservationSummary> _forDay(List<ReservationSummary> all, DateTime day) {
    final d = _key(day);
    return all.where((r) {
      final inDay = _key(r.checkIn);
      final outDay = _key(r.checkOut);
      return !d.isBefore(inDay) && d.isBefore(outDay);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    const filter = ReservationFilter();
    final async = ref.watch(reservationListProvider(filter));
    final domes = ref.watch(domesProvider).valueOrNull ?? [];
    int domeIndex(String id) {
      final i = domes.indexWhere((d) => d.id == id);
      return i < 0 ? 0 : i;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Calendario')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          final iso = _selectedDay.toIso8601String().substring(0, 10);
          context.push('/reservations/new?date=$iso');
        },
        icon: const Icon(Icons.add),
        label: const Text('Reservar'),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorRetry(error: e, onRetry: () => ref.invalidate(reservationListProvider(filter))),
        data: (allRaw) {
          final all = allRaw.where((r) => r.status != ReservationStatus.cancelled).toList();
          final dayItems = _forDay(all, _selectedDay);

          return Column(
            children: [
              Card(
                margin: const EdgeInsets.all(12),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: TableCalendar<ReservationSummary>(
                    locale: 'es',
                    firstDay: DateTime.utc(2023, 1, 1),
                    lastDay: DateTime.utc(2030, 12, 31),
                    focusedDay: _focusedDay,
                    selectedDayPredicate: (d) => isSameDay(d, _selectedDay),
                    eventLoader: (day) => _forDay(all, day),
                    startingDayOfWeek: StartingDayOfWeek.monday,
                    availableCalendarFormats: const {CalendarFormat.month: 'Mes'},
                    onDaySelected: (selected, focused) => setState(() {
                      _selectedDay = selected;
                      _focusedDay = focused;
                    }),
                    calendarBuilders: CalendarBuilders(
                      markerBuilder: (context, day, events) {
                        if (events.isEmpty) return null;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              for (final e in events.take(3))
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 1),
                                  child: DomeDot(domeIndex(e.domeId)),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              _Legend(domes: domes),
              const Divider(height: 1),
              Expanded(
                child: dayItems.isEmpty
                    ? const EmptyState(
                        icon: Icons.event_available_outlined,
                        title: 'Día libre',
                        message: 'No hay reservas para este día.',
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
                        itemCount: dayItems.length,
                        itemBuilder: (c, i) => ReservationCard(
                          reservation: dayItems[i],
                          onTap: () => context.push('/reservations/${dayItems[i].id}'),
                        ),
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final List domes;
  const _Legend({required this.domes});

  @override
  Widget build(BuildContext context) {
    if (domes.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Wrap(
        spacing: 16,
        children: [
          for (var i = 0; i < domes.length; i++)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                DomeDot(i),
                const SizedBox(width: 6),
                Text(domes[i].name, style: TextStyle(color: Theme.of(context).colorScheme.outline)),
              ],
            ),
        ],
      ),
    );
  }
}
