import 'package:flutter/material.dart';

import '../../../core/design/tokens.dart';
import '../../../core/formatters.dart';
import '../../../core/widgets/buttons.dart';

/// Barra inferior fija con el resumen de la selección y el botón principal.
/// El botón se deshabilita si no hay productos seleccionados.
class ConsumptionSummaryBar extends StatelessWidget {
  final int count;
  final double total;
  final String label;
  final bool saving;
  final VoidCallback? onConfirm;

  const ConsumptionSummaryBar({
    super.key,
    required this.count,
    required this.total,
    required this.onConfirm,
    this.label = 'Guardar consumos',
    this.saving = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hasItems = count > 0;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        boxShadow: const [
          BoxShadow(
            color: Color(0x14182018),
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.x5,
            AppSpacing.x3,
            AppSpacing.x5,
            AppSpacing.x3,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      hasItems
                          ? '$count producto${count == 1 ? '' : 's'}'
                          : 'Sin productos',
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      Formatters.money(total),
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: cs.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.x4),
              SizedBox(
                width: 190,
                child: PrimaryButton(
                  label: label,
                  icon: Icons.check_rounded,
                  loading: saving,
                  onPressed: hasItems ? onConfirm : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
