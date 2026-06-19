import 'package:flutter/material.dart';

import '../../models/reservation.dart';
import '../formatters.dart';
import 'common_widgets.dart';

/// Tarjeta compacta de reserva, reutilizada en Hoy, Reservas e Historial.
class ReservationCard extends StatelessWidget {
  final ReservationSummary reservation;
  final VoidCallback onTap;

  const ReservationCard({super.key, required this.reservation, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final r = reservation;
    final hasBalance = r.balance > 0;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(r.guestName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
                  StatusChip(r.status),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 4,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.cabin_rounded, size: 16, color: scheme.outline),
                      const SizedBox(width: 4),
                      Text(r.domeName, style: TextStyle(color: scheme.outline)),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.calendar_today_rounded, size: 14, color: scheme.outline),
                      const SizedBox(width: 4),
                      Text(Formatters.dateRange(r.checkIn, r.checkOut),
                          style: TextStyle(color: scheme.outline)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.people_alt_rounded, size: 15, color: scheme.outline),
                  const SizedBox(width: 4),
                  Text('${r.guestCount}', style: TextStyle(color: scheme.outline)),
                  const Spacer(),
                  if (hasBalance)
                    Text('Saldo ${Formatters.money(r.balance)}',
                        style: TextStyle(
                            color: scheme.error, fontWeight: FontWeight.w600))
                  else
                    Text('Pagado',
                        style: TextStyle(
                            color: scheme.primary, fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
