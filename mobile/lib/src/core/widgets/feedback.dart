import 'package:flutter/material.dart';

import '../design/tokens.dart';
import 'buttons.dart';

enum AppMessageType { success, error, info }

/// SnackBar personalizado (no genérico): ícono, color de acento y forma suave.
class AppSnackBar {
  static void show(BuildContext context, String message, {AppMessageType type = AppMessageType.info}) {
    final (color, icon) = switch (type) {
      AppMessageType.success => (AppColors.forest, Icons.check_circle_rounded),
      AppMessageType.error => (AppColors.coral, Icons.error_rounded),
      AppMessageType.info => (AppColors.blue, Icons.info_rounded),
    };
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.textPrimary,
        elevation: 0,
        duration: const Duration(seconds: 3),
        shape: RoundedRectangleBorder(borderRadius: AppRadii.all(AppRadii.md)),
        content: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(message,
                  style: const TextStyle(
                      color: Colors.white, fontFamily: 'Manrope', fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Hoja de confirmación con ícono, título, mensaje y dos acciones.
Future<bool> showConfirmationSheet(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Confirmar',
  String cancelLabel = 'Cancelar',
  IconData icon = Icons.help_rounded,
  Color accent = AppColors.forest,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.x5, AppSpacing.x2, AppSpacing.x5, AppSpacing.x5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(color: accent.withValues(alpha: 0.14), shape: BoxShape.circle),
                child: Icon(icon, color: accent, size: 30),
              ),
            ),
            const SizedBox(height: AppSpacing.x4),
            Text(title, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.x2),
            Text(message, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: AppSpacing.x6),
            PrimaryButton(label: confirmLabel, color: accent, onPressed: () => Navigator.pop(context, true)),
            const SizedBox(height: AppSpacing.x2),
            SecondaryButton(
              label: cancelLabel,
              expand: true,
              color: AppColors.textSecondary,
              onPressed: () => Navigator.pop(context, false),
            ),
          ],
        ),
      ),
    ),
  );
  return result ?? false;
}
