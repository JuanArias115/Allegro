import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/tokens.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/cards.dart';
import '../../core/widgets/state_views.dart';
import '../../models/enums.dart';
import '../../providers.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  final _searchCtrl = TextEditingController();
  String _text = '';
  ReservationStatus _status = ReservationStatus.completed;

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
    );
    final listAsync = ref.watch(reservationListProvider(filter));

    return AppScaffold(
      header: AppHeader(title: 'Historial', onBack: () => context.pop()),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.x5,
              AppSpacing.x1,
              AppSpacing.x5,
              AppSpacing.x3,
            ),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _text = v),
              style: const TextStyle(fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                hintText: 'Buscar por nombre o teléfono',
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.x5,
              0,
              AppSpacing.x5,
              AppSpacing.x2,
            ),
            child: Row(
              children: [
                Expanded(
                  child: _Tab(
                    label: 'Finalizadas',
                    selected: _status == ReservationStatus.completed,
                    onTap: () =>
                        setState(() => _status = ReservationStatus.completed),
                  ),
                ),
                const SizedBox(width: AppSpacing.x2),
                Expanded(
                  child: _Tab(
                    label: 'Canceladas',
                    selected: _status == ReservationStatus.cancelled,
                    onTap: () =>
                        setState(() => _status = ReservationStatus.cancelled),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: listAsync.when(
              loading: () => const LoadingState(),
              error: (e, _) => ErrorState(
                error: e,
                onRetry: () => ref.invalidate(reservationListProvider(filter)),
              ),
              data: (items) {
                if (items.isEmpty) {
                  return EmptyState(
                    icon: Icons.inventory_2_rounded,
                    title: _status == ReservationStatus.completed
                        ? 'Sin finalizadas'
                        : 'Sin canceladas',
                    accent: AppColors.textSecondary,
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.x5,
                    AppSpacing.x2,
                    AppSpacing.x5,
                    AppSpacing.x8,
                  ),
                  itemCount: items.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.x3),
                  itemBuilder: (c, i) => ReservationCard(
                    reservation: items[i],
                    onTap: () => context.push('/reservations/${items[i].id}'),
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

class _Tab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _Tab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? AppColors.forest
          : Theme.of(context).colorScheme.surface,
      borderRadius: AppRadii.all(AppRadii.md),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: selected
                    ? AppColors.white
                    : Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
