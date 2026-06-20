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
/// foco verde claramente visible, botón ✕ (o mostrar/ocultar en contraseñas) y
/// mensajes de validación amables.
class AppTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final String? helper;
  final String? prefixText;
  final IconData? icon;
  final bool required;
  final bool enabled;
  final bool obscure;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final int maxLines;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

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
    this.obscure = false,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.maxLines = 1,
    this.validator,
    this.onChanged,
    this.onSubmitted,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _obscured = widget.obscure;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Label(widget.label, widget.required),
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: widget.controller,
          builder: (context, value, _) => TextFormField(
            controller: widget.controller,
            enabled: widget.enabled,
            obscureText: _obscured,
            keyboardType: widget.keyboardType,
            textCapitalization: widget.textCapitalization,
            maxLines: widget.obscure ? 1 : widget.maxLines,
            validator: widget.validator,
            onChanged: widget.onChanged,
            onFieldSubmitted: widget.onSubmitted,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              hintText: widget.hint,
              prefixText: widget.prefixText,
              prefixStyle: TextStyle(
                  fontFamily: 'Manrope', fontSize: 16, fontWeight: FontWeight.w700, color: scheme.onSurface),
              prefixIcon: widget.icon != null ? Icon(widget.icon, size: 20) : null,
              suffixIcon: _suffix(scheme, value.text),
            ),
          ),
        ),
        if (widget.helper != null)
          Padding(
            padding: const EdgeInsets.only(left: 4, top: 6),
            child: Text(widget.helper!, style: Theme.of(context).textTheme.bodySmall),
          ),
      ],
    );
  }

  Widget? _suffix(ColorScheme scheme, String text) {
    if (widget.obscure) {
      return IconButton(
        icon: Icon(_obscured ? Icons.visibility_rounded : Icons.visibility_off_rounded,
            size: 20, color: scheme.outline),
        onPressed: () => setState(() => _obscured = !_obscured),
        splashRadius: 18,
      );
    }
    if (widget.maxLines == 1 && widget.enabled && text.isNotEmpty) {
      return IconButton(
        icon: Icon(Icons.cancel_rounded, size: 19, color: scheme.outline),
        onPressed: widget.controller.clear,
        splashRadius: 18,
      );
    }
    return null;
  }
}

class PhoneCountry {
  final String flag;
  final String name;
  final String dial; // ej. +57
  const PhoneCountry(this.flag, this.name, this.dial);
}

const List<PhoneCountry> kPhoneCountries = [
  PhoneCountry('🇨🇴', 'Colombia', '+57'),
  PhoneCountry('🇺🇸', 'Estados Unidos', '+1'),
  PhoneCountry('🇲🇽', 'México', '+52'),
  PhoneCountry('🇪🇸', 'España', '+34'),
  PhoneCountry('🇦🇷', 'Argentina', '+54'),
  PhoneCountry('🇨🇱', 'Chile', '+56'),
  PhoneCountry('🇵🇪', 'Perú', '+51'),
  PhoneCountry('🇧🇷', 'Brasil', '+55'),
];

/// Campo de teléfono con selector de país (bandera + código) y número local.
/// El [controller] del padre conserva el valor completo (ej. +573001234567).
class PhoneField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final bool required;
  final ValueChanged<String>? onChanged;
  final String? Function(String?)? validator;

  const PhoneField({
    super.key,
    required this.controller,
    this.label = 'Teléfono / WhatsApp',
    this.required = false,
    this.onChanged,
    this.validator,
  });

  @override
  State<PhoneField> createState() => _PhoneFieldState();
}

class _PhoneFieldState extends State<PhoneField> {
  late PhoneCountry _country;
  late final TextEditingController _local;

  @override
  void initState() {
    super.initState();
    final (country, local) = _parse(widget.controller.text);
    _country = country;
    _local = TextEditingController(text: local);
  }

  @override
  void dispose() {
    _local.dispose();
    super.dispose();
  }

  static (PhoneCountry, String) _parse(String full) {
    final trimmed = full.trim();
    final byLength = [...kPhoneCountries]..sort((a, b) => b.dial.length.compareTo(a.dial.length));
    for (final c in byLength) {
      if (trimmed.startsWith(c.dial)) {
        return (c, trimmed.substring(c.dial.length).replaceAll(RegExp(r'[^0-9]'), ''));
      }
    }
    return (kPhoneCountries.first, trimmed.replaceAll(RegExp(r'[^0-9]'), ''));
  }

  void _sync() {
    final digits = _local.text.replaceAll(RegExp(r'[^0-9]'), '');
    widget.controller.text = digits.isEmpty ? '' : '${_country.dial}$digits';
    widget.onChanged?.call(widget.controller.text);
  }

  Future<void> _pickCountry() async {
    final picked = await showModalBottomSheet<PhoneCountry>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(sheetContext).size.height * 0.6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.x5, 0, AppSpacing.x5, AppSpacing.x2),
                child: Align(alignment: Alignment.centerLeft, child: Text('País', style: Theme.of(context).textTheme.titleLarge)),
              ),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final c in kPhoneCountries)
                      ListTile(
                        leading: Text(c.flag, style: const TextStyle(fontSize: 24)),
                        title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                        trailing: Text(c.dial, style: TextStyle(color: Theme.of(context).colorScheme.outline, fontWeight: FontWeight.w700)),
                        onTap: () => Navigator.pop(sheetContext, c),
                      ),
                    const SizedBox(height: AppSpacing.x2),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (picked != null) {
      setState(() => _country = picked);
      _sync();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Label(widget.label, widget.required),
        TextFormField(
          controller: _local,
          keyboardType: TextInputType.phone,
          validator: widget.validator,
          onChanged: (_) => _sync(),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            hintText: '300 000 0000',
            prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
            prefixIcon: InkWell(
              onTap: _pickCountry,
              borderRadius: AppRadii.all(AppRadii.md),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 10, 0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_country.flag, style: const TextStyle(fontSize: 19)),
                    const SizedBox(width: 6),
                    Text(_country.dial, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: scheme.outline),
                    const SizedBox(width: 10),
                    Container(width: 1, height: 24, color: scheme.outlineVariant),
                    const SizedBox(width: 4),
                  ],
                ),
              ),
            ),
          ),
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
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(sheetContext).size.height * 0.6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.x5, 0, AppSpacing.x5, AppSpacing.x2),
                child: Align(alignment: Alignment.centerLeft, child: Text(label, style: Theme.of(context).textTheme.titleLarge)),
              ),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final o in options)
                      ListTile(
                        leading: o.icon != null ? Icon(o.icon, color: o.color ?? scheme.primary) : null,
                        title: Text(o.label, style: const TextStyle(fontWeight: FontWeight.w600)),
                        trailing: o.value == value ? Icon(Icons.check_rounded, color: scheme.primary) : null,
                        onTap: () => Navigator.pop(sheetContext, o.value),
                      ),
                    const SizedBox(height: AppSpacing.x2),
                  ],
                ),
              ),
            ],
          ),
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
