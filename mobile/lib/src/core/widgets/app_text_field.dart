import 'package:flutter/material.dart';

import '../design/tokens.dart';

class _Label extends StatelessWidget {
  final String label;
  final bool required;
  const _Label(this.label, this.required);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(left: 2, bottom: 8),
      child: RichText(
        text: TextSpan(
          text: label,
          style: TextStyle(
            fontFamily: 'Manrope',
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: scheme.onSurface,
          ),
          children: required ? [TextSpan(text: ' *', style: TextStyle(color: AppColors.coral))] : const [],
        ),
      ),
    );
  }
}

/// Campo de texto personalizado: etiqueta arriba, ícono contextual, fondo suave,
/// foco verde claramente visible, botón ✕ y mensajes de validación amables.
class AppTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final String? helper;
  final String? prefixText;
  final IconData? icon;
  final bool required;
  final bool enabled;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final int maxLines;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;

  const AppTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.helper,
    this.prefixText,
    this.icon,
    this.required = false,
    this.enabled = true,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.maxLines = 1,
    this.validator,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Label(label, required),
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (context, value, _) => TextFormField(
            controller: controller,
            enabled: enabled,
            keyboardType: keyboardType,
            textCapitalization: textCapitalization,
            maxLines: maxLines,
            validator: validator,
            onChanged: onChanged,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              hintText: hint,
              prefixText: prefixText,
              prefixStyle: TextStyle(
                  fontFamily: 'Manrope', fontSize: 16, fontWeight: FontWeight.w700, color: scheme.onSurface),
              icon: null,
              prefixIcon: icon != null ? Icon(icon, size: 20) : null,
              suffixIcon: (maxLines == 1 && enabled && value.text.isNotEmpty)
                  ? IconButton(
                      icon: Icon(Icons.cancel_rounded, size: 19, color: scheme.outline),
                      onPressed: controller.clear,
                      splashRadius: 18,
                    )
                  : null,
            ),
          ),
        ),
        if (helper != null)
          Padding(
            padding: const EdgeInsets.only(left: 4, top: 6),
            child: Text(helper!, style: Theme.of(context).textTheme.bodySmall),
          ),
      ],
    );
  }
}

/// Contenedor con aspecto de campo (para selectores, fechas, steppers).
class AppFieldBox extends StatelessWidget {
  final String? label;
  final bool required;
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  const AppFieldBox({
    super.key,
    this.label,
    this.required = false,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final box = Material(
      color: scheme.surface,
      borderRadius: AppRadii.all(AppRadii.md),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
    if (label == null) return box;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [_Label(label!, required), box],
    );
  }
}

/// Opción para [AppSelectField].
class SelectOption<T> {
  final T value;
  final String label;
  final IconData? icon;
  final Color? color;
  const SelectOption(this.value, this.label, {this.icon, this.color});
}

/// Selector visual: abre una hoja con las opciones (en vez de un dropdown gris).
class AppSelectField<T> extends StatelessWidget {
  final String label;
  final T value;
  final List<SelectOption<T>> options;
  final ValueChanged<T> onChanged;
  final bool required;
  final IconData? icon;

  const AppSelectField({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    this.required = false,
    this.icon,
  });

  SelectOption<T> get _current =>
      options.firstWhere((o) => o.value == value, orElse: () => options.first);

  Future<void> _open(BuildContext context) async {
    final scheme = Theme.of(context).colorScheme;
    final selected = await showModalBottomSheet<T>(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.x5, 0, AppSpacing.x5, AppSpacing.x2),
              child: Align(alignment: Alignment.centerLeft, child: Text(label, style: Theme.of(context).textTheme.titleLarge)),
            ),
            for (final o in options)
              ListTile(
                leading: o.icon != null
                    ? Icon(o.icon, color: o.color ?? scheme.primary)
                    : null,
                title: Text(o.label, style: const TextStyle(fontWeight: FontWeight.w600)),
                trailing: o.value == value ? Icon(Icons.check_rounded, color: scheme.primary) : null,
                onTap: () => Navigator.pop(context, o.value),
              ),
            const SizedBox(height: AppSpacing.x2),
          ],
        ),
      ),
    );
    if (selected != null) onChanged(selected);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final current = _current;
    return AppFieldBox(
      label: label,
      required: required,
      onTap: () => _open(context),
      child: Row(
        children: [
          if (icon != null || current.icon != null) ...[
            Icon(current.icon ?? icon, size: 20, color: current.color ?? scheme.outline),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Text(current.label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
          Icon(Icons.keyboard_arrow_down_rounded, color: scheme.outline),
        ],
      ),
    );
  }
}

/// Campo de fecha: muestra el valor y abre el selector nativo (localizado).
class DateField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final String hint;
  final VoidCallback onTap;
  final bool required;

  const DateField({
    super.key,
    required this.label,
    required this.value,
    required this.onTap,
    this.hint = 'Elegir',
    this.required = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasValue = value != null;
    return AppFieldBox(
      label: label,
      required: required,
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
      child: Row(
        children: [
          Icon(Icons.calendar_today_rounded, size: 18, color: scheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              hasValue ? _fmt(value!) : hint,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.w600,
                color: hasValue ? scheme.onSurface : scheme.outline,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _fmt(DateTime d) {
    const months = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }
}

/// Selector numérico (− valor +) para huéspedes y similares.
class StepperField extends StatelessWidget {
  final String label;
  final int value;
  final VoidCallback? onMinus;
  final VoidCallback onPlus;
  final IconData? icon;
  final String? caption;

  const StepperField({
    super.key,
    required this.label,
    required this.value,
    required this.onMinus,
    required this.onPlus,
    this.icon,
    this.caption,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppFieldBox(
      label: label,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: [
          if (icon != null) ...[Icon(icon, size: 20, color: scheme.outline), const SizedBox(width: 10)],
          Expanded(child: Text(caption ?? '', style: Theme.of(context).textTheme.bodyMedium)),
          _RoundBtn(icon: Icons.remove_rounded, onTap: onMinus),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text('$value', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          ),
          _RoundBtn(icon: Icons.add_rounded, onTap: onPlus),
        ],
      ),
    );
  }
}

class _RoundBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _RoundBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final c = enabled ? AppColors.forest : AppColors.textSecondary;
    return Material(
      color: c.withValues(alpha: 0.12),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(width: 40, height: 40, child: Icon(icon, size: 20, color: c)),
      ),
    );
  }
}
