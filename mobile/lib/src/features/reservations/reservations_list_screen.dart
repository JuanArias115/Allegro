import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/tokens.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/cards.dart';
import '../../core/widgets/state_views.dart';
import '../../models/enums.dart';
import '../../providers.dart';

class ReservationsListScreen extends ConsumerStatefulWidget {
  const ReservationsListScreen({super.key});

  @override
  ConsumerState<ReservationsListScreen> createState() => _ReservationsListScreenState();
}

class _ReservationsListScreenState extends ConsumerState<ReservationsListScreen> {
  final _searchCtrl = TextEditingController();
  String _text = '';
  ReservationStatus? _status;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filter = ReservationFilter(
      text: _text.trim().isEmpty ? null : _text.trim(),
      status: _status,
      active: _status == null ? true : null,
    );
    final listAsync = ref.watch(reservationListProvider(filter));

    return AppScaffold(
      header: AppHeader(
        title: 'Reservas',
        actions: [
          AppIconButton(icon: Icons.history_rounded, tooltip: 'Historial', onTap: () => context.push('/history')),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.forest,
        foregroundColor: AppColors.white,
        onPressed: () => context.push('/reservations/new'),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nueva', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.x5, AppSpacing.x1, AppSpacing.x5, AppSpacing.x3),
            child: _SearchBar(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _text = v),
            ),
          ),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x5),
              children: [
                _Chip(label: 'Activas', selected: _status == null, onTap: () => setState(() => _status = null)),
                for (final s in ReservationStatus.values)
                  _Chip(label: s.label, selected: _status == s, onTap: () => setState(() => _status = s)),
              ],
            ),
          ),
          Expanded(
            child: listAsync.when(
              loading: () => const LoadingState(),
              error: (e, _) => ErrorState(error: e, onRetry: () => ref.invalidate(reservationListProvider(filter))),
              data: (items) {
                if (items.isEmpty) {
                  return EmptyState(
                    icon: Icons.event_busy_rounded,
                    title: 'Sin reservas',
                    message: _text.isNotEmpty ? 'Nada coincide con tu búsqueda.' : 'No hay reservas con este filtro.',
                    accent: AppColors.violet,
                  );
                }
                return RefreshIndicator(
                  color: AppColors.forest,
                  onRefresh: () async => ref.invalidate(reservationListProvider(filter)),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.x5, AppSpacing.x3, AppSpacing.x5, 120),
                    itemCount: items.length + 1,
                    separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.x3),
                    itemBuilder: (c, i) {
                      if (i == 0) {
                        return Padding(
                          padding: const EdgeInsets.only(left: 2, bottom: 2),
                          child: Text('${items.length} resultado${items.length == 1 ? '' : 's'}',
                              style: Theme.of(context).textTheme.bodySmall),
                        );
                      }
                      final r = items[i - 1];
                      return AppearAnimation(
                        index: i - 1,
                        child: ReservationCard(reservation: r, onTap: () => context.push('/reservations/${r.id}')),
                      );
                    },
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

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  const _SearchBar({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      style: const TextStyle(fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        hintText: 'Buscar por nombre o teléfono',
        prefixIcon: Icon(Icons.search_rounded, color: scheme.outline),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                icon: Icon(Icons.close_rounded, color: scheme.outline),
                onPressed: () {
                  controller.clear();
                  onChanged('');
                },
              ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _Chip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.x2),
      child: Material(
        color: selected ? AppColors.forest : scheme.surface,
        borderRadius: AppRadii.all(AppRadii.pill),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: selected ? AppColors.white : scheme.onSurface,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
