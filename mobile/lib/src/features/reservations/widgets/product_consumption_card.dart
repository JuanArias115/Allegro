import 'package:flutter/material.dart';

import '../../../core/design/tokens.dart';
import '../../../core/formatters.dart';
import '../../../models/product.dart';

/// Tarjeta de producto para el menú de consumos. Muestra nombre, categoría,
/// precio y un control de cantidad. Sin iconos de categoría (dinámicas): si el
/// producto tiene imagen se muestra; si no, se omite el adorno.
class ProductConsumptionCard extends StatelessWidget {
  final Product product;
  final int quantity;
  final VoidCallback onAdd;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const ProductConsumptionCard({
    super.key,
    required this.product,
    required this.quantity,
    required this.onAdd,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    final selected = quantity > 0;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.all(AppRadii.lg),
        border: Border.all(
          color: selected ? AppColors.forest : AppColors.hairline,
          width: selected ? 1.4 : 1,
        ),
        boxShadow: AppShadows.soft,
      ),
      child: Row(
        children: [
          if (product.imageUrl != null && product.imageUrl!.isNotEmpty) ...[
            ClipRRect(
              borderRadius: AppRadii.all(AppRadii.md),
              child: Image.network(
                product.imageUrl!,
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const SizedBox(width: 48, height: 48),
              ),
            ),
            const SizedBox(width: AppSpacing.x3),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (product.categoryName.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    product.categoryName,
                    style: const TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  Formatters.money(product.currentPrice),
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.forest,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.x3),
          selected ? _QuantityControl(
            quantity: quantity,
            onIncrement: onIncrement,
            onDecrement: onDecrement,
          ) : _AddButton(onTap: onAdd),
        ],
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  final VoidCallback onTap;
  const _AddButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.forest,
      borderRadius: AppRadii.all(AppRadii.pill),
      child: InkWell(
        borderRadius: AppRadii.all(AppRadii.pill),
        onTap: onTap,
        child: const SizedBox(
          width: 40,
          height: 40,
          child: Icon(Icons.add_rounded, color: AppColors.white, size: 22),
        ),
      ),
    );
  }
}

class _QuantityControl extends StatelessWidget {
  final int quantity;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const _QuantityControl({
    required this.quantity,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.mint,
        borderRadius: AppRadii.all(AppRadii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _RoundIcon(icon: Icons.remove_rounded, onTap: onDecrement),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 28),
            child: Text(
              '$quantity',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Manrope',
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.forestDark,
              ),
            ),
          ),
          _RoundIcon(icon: Icons.add_rounded, onTap: onIncrement),
        ],
      ),
    );
  }
}

class _RoundIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _RoundIcon({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.forest,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(icon, color: AppColors.white, size: 20),
        ),
      ),
    );
  }
}
