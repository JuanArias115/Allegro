import 'package:flutter/material.dart';

/// Campo de texto estilo Rappi: etiqueta arriba, campo alto y redondeado,
/// botón para borrar (✕) cuando hay texto y texto de ayuda opcional.
class AppTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final String? prefixText;
  final IconData? prefixIcon;
  final Widget? prefix;
  final String? helper;
  final bool helperSuccess;
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
    this.prefixText,
    this.prefixIcon,
    this.prefix,
    this.helper,
    this.helperSuccess = false,
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
    final showClear = maxLines == 1 && enabled;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: RichText(
            text: TextSpan(
              text: label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: scheme.onSurface,
              ),
              children: required
                  ? [TextSpan(text: ' *', style: TextStyle(color: scheme.error))]
                  : const [],
            ),
          ),
        ),
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (context, value, _) {
            return TextFormField(
              controller: controller,
              enabled: enabled,
              keyboardType: keyboardType,
              textCapitalization: textCapitalization,
              maxLines: maxLines,
              validator: validator,
              onChanged: onChanged,
              style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                hintText: hint,
                prefixText: prefixText,
                prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 20) : null,
                prefix: prefix,
                suffixIcon: (showClear && value.text.isNotEmpty)
                    ? IconButton(
                        icon: Icon(Icons.cancel_rounded, size: 20, color: scheme.outlineVariant),
                        onPressed: controller.clear,
                        splashRadius: 20,
                      )
                    : null,
              ),
            );
          },
        ),
        if (helper != null)
          Padding(
            padding: const EdgeInsets.only(left: 4, top: 6),
            child: Text(
              helper!,
              style: TextStyle(
                fontSize: 12.5,
                color: helperSuccess ? scheme.primary : scheme.outline,
              ),
            ),
          ),
      ],
    );
  }
}

/// Tarjeta con el mismo aspecto de un campo, para selects o tiles (fecha, etc.).
class AppFieldBox extends StatelessWidget {
  final String label;
  final Widget child;
  final bool required;
  final EdgeInsetsGeometry padding;

  const AppFieldBox({
    super.key,
    required this.label,
    required this.child,
    this.required = false,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: RichText(
            text: TextSpan(
              text: label,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: scheme.onSurface),
              children: required
                  ? [TextSpan(text: ' *', style: TextStyle(color: scheme.error))]
                  : const [],
            ),
          ),
        ),
        Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppThemeBorder.of(context)),
          ),
          child: child,
        ),
      ],
    );
  }
}

/// Acceso al color de borde de campo sin acoplar a AppTheme directamente.
class AppThemeBorder {
  static Color of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF2E322F)
          : const Color(0xFFE6E8E4);
}
