import 'package:flutter/material.dart';

import '../design/tokens.dart';

/// Scaffold base: fondo crema, encabezado opcional fijo arriba y barra inferior
/// opcional. Los componentes del sistema de diseño se apoyan en él.
class AppScaffold extends StatelessWidget {
  final Widget body;
  final Widget? header;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final Widget? bottomBar;
  final Color? background;

  const AppScaffold({
    super.key,
    required this.body,
    this.header,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.bottomBar,
    this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      bottomNavigationBar: bottomBar,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (header != null) header!,
            Expanded(child: body),
          ],
        ),
      ),
    );
  }
}

/// Encabezado de pantalla con título fuerte, línea superior opcional (fecha o
/// contexto), botón de retroceso opcional y acciones.
class AppHeader extends StatelessWidget {
  final String title;
  final String? eyebrow;
  final VoidCallback? onBack;
  final List<Widget> actions;
  final bool large;

  const AppHeader({
    super.key,
    required this.title,
    this.eyebrow,
    this.onBack,
    this.actions = const [],
    this.large = true,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.x5, AppSpacing.x4, AppSpacing.x4, AppSpacing.x3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (onBack != null) ...[
            AppIconButton(icon: Icons.arrow_back_rounded, onTap: onBack!),
            const SizedBox(width: AppSpacing.x3),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (eyebrow != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(eyebrow!, style: t.bodySmall),
                  ),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: large ? t.headlineMedium : t.headlineSmall,
                ),
              ],
            ),
          ),
          for (final a in actions) Padding(padding: const EdgeInsets.only(left: 8), child: a),
        ],
      ),
    );
  }
}

/// Botón de ícono circular sobre un fondo suave (área táctil ≥ 44 px).
class AppIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;
  final Color? background;
  final String? tooltip;

  const AppIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.color,
    this.background,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fg = color ?? scheme.onSurface;
    final widget = Material(
      color: background ?? scheme.surface,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(width: 44, height: 44, child: Icon(icon, size: 21, color: fg)),
      ),
    );
    return tooltip == null ? widget : Tooltip(message: tooltip!, child: widget);
  }
}

/// Encabezado de sección: título y acción/etiqueta opcional a la derecha.
class SectionHeader extends StatelessWidget {
  final String title;
  final String? trailingText;
  final VoidCallback? onTrailingTap;
  final EdgeInsetsGeometry padding;

  const SectionHeader({
    super.key,
    required this.title,
    this.trailingText,
    this.onTrailingTap,
    this.padding = const EdgeInsets.fromLTRB(AppSpacing.x5, AppSpacing.x6, AppSpacing.x5, AppSpacing.x3),
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: padding,
      child: Row(
        children: [
          Expanded(child: Text(title, style: t.titleMedium)),
          if (trailingText != null)
            GestureDetector(
              onTap: onTrailingTap,
              child: Text(
                trailingText!,
                style: t.labelMedium?.copyWith(
                  color: onTrailingTap != null ? Theme.of(context).colorScheme.primary : null,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
