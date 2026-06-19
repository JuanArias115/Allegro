import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/formatters.dart';
import '../../core/widgets/common_widgets.dart';
import '../../models/availability.dart';
import '../../models/dome.dart';
import '../../models/reservation.dart';
import '../../providers.dart';

class ReservationFormScreen extends ConsumerStatefulWidget {
  final String? editId;
  final String? initialDate;
  final String? initialDomeId;

  const ReservationFormScreen({super.key, this.editId, this.initialDate, this.initialDomeId});

  @override
  ConsumerState<ReservationFormScreen> createState() => _ReservationFormScreenState();
}

class _ReservationFormScreenState extends ConsumerState<ReservationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _price = TextEditingController();
  final _notes = TextEditingController();

  String? _domeId;
  DateTime? _checkIn;
  DateTime? _checkOut;
  int _guests = 2;

  bool _loaded = false;
  bool _saving = false;
  Availability? _availability;
  bool _checkingAvailability = false;

  bool get _isEdit => widget.editId != null;

  @override
  void initState() {
    super.initState();
    if (widget.initialDate != null) {
      _checkIn = DateTime.tryParse(widget.initialDate!);
      if (_checkIn != null) _checkOut = _checkIn!.add(const Duration(days: 1));
    }
    _domeId = widget.initialDomeId;
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _price.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _prefill(Reservation r) {
    _name.text = r.guestName;
    _phone.text = r.phone;
    _price.text = r.lodgingPrice.toStringAsFixed(0);
    _notes.text = r.notes ?? '';
    _domeId = r.domeId;
    _checkIn = r.checkIn;
    _checkOut = r.checkOut;
    _guests = r.guestCount;
    _loaded = true;
  }

  Future<void> _pickDate({required bool isCheckIn}) async {
    final now = DateTime.now();
    final initial = isCheckIn
        ? (_checkIn ?? now)
        : (_checkOut ?? _checkIn?.add(const Duration(days: 1)) ?? now.add(const Duration(days: 1)));
    final first = isCheckIn ? DateTime(now.year - 1) : (_checkIn ?? now).add(const Duration(days: 1));
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(first) ? first : initial,
      firstDate: first,
      lastDate: DateTime(now.year + 3),
      helpText: isCheckIn ? 'Fecha de llegada' : 'Fecha de salida',
    );
    if (picked == null) return;
    setState(() {
      if (isCheckIn) {
        _checkIn = picked;
        if (_checkOut == null || !_checkOut!.isAfter(picked)) {
          _checkOut = picked.add(const Duration(days: 1));
        }
      } else {
        _checkOut = picked;
      }
    });
    _checkAvailability();
  }

  Future<void> _checkAvailability() async {
    if (_domeId == null || _checkIn == null || _checkOut == null) return;
    if (!_checkOut!.isAfter(_checkIn!)) return;
    setState(() => _checkingAvailability = true);
    try {
      final result = await ref.read(reservationRepositoryProvider).availability(
            _domeId!, _checkIn!, _checkOut!,
            excludeReservationId: widget.editId,
          );
      if (mounted) setState(() => _availability = result);
    } catch (_) {
      if (mounted) setState(() => _availability = null);
    } finally {
      if (mounted) setState(() => _checkingAvailability = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_domeId == null || _checkIn == null || _checkOut == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona domo y fechas.')),
      );
      return;
    }
    if (!_checkOut!.isAfter(_checkIn!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La salida debe ser posterior a la llegada.')),
      );
      return;
    }

    setState(() => _saving = true);
    final repo = ref.read(reservationRepositoryProvider);
    final input = ReservationInput(
      guestName: _name.text.trim(),
      phone: _phone.text.trim(),
      domeId: _domeId!,
      checkIn: _checkIn!,
      checkOut: _checkOut!,
      guestCount: _guests,
      lodgingPrice: double.tryParse(_price.text.replaceAll(',', '')) ?? 0,
      notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
    );

    try {
      final result =
          _isEdit ? await repo.update(widget.editId!, input) : await repo.create(input);
      ref.invalidate(todayProvider);
      if (_isEdit) ref.invalidate(reservationDetailProvider(widget.editId!));
      if (mounted) context.go('/reservations/${result.id}');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final domesAsync = ref.watch(activeDomesProvider);

    if (_isEdit && !_loaded) {
      final detail = ref.watch(reservationDetailProvider(widget.editId!));
      return detail.when(
        loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (e, _) => Scaffold(
          appBar: AppBar(),
          body: ErrorRetry(error: e, onRetry: () => ref.invalidate(reservationDetailProvider(widget.editId!))),
        ),
        data: (r) {
          _prefill(r);
          return _buildForm(domesAsync);
        },
      );
    }
    return _buildForm(domesAsync);
  }

  Widget _buildForm(AsyncValue<List<Dome>> domesAsync) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Editar reserva' : 'Nueva reserva')),
      body: domesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorRetry(error: e, onRetry: () => ref.invalidate(activeDomesProvider)),
        data: (domes) {
          _domeId ??= domes.isNotEmpty ? domes.first.id : null;
          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                const _SectionLabel('Huésped'),
                const _FieldLabel('Nombre'),
                TextFormField(
                  controller: _name,
                  textCapitalization: TextCapitalization.words,
                  decoration: _fieldDecoration(context, hint: 'Nombre del huésped'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                ),
                const _FieldLabel('Teléfono / WhatsApp'),
                TextFormField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  decoration: _fieldDecoration(context, hint: 'Ej. +57 300 000 0000', icon: Icons.phone_outlined),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                ),

                const _SectionLabel('Estadía'),
                const _FieldLabel('Domo'),
                _BoxField(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _domeId,
                      isExpanded: true,
                      borderRadius: BorderRadius.circular(12),
                      items: [
                        for (final d in domes)
                          DropdownMenuItem(value: d.id, child: Text('${d.name} · máx. ${d.maxCapacity}')),
                      ],
                      onChanged: (v) {
                        setState(() => _domeId = v);
                        _checkAvailability();
                      },
                    ),
                  ),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _DateTile(label: 'Llegada', date: _checkIn, onTap: () => _pickDate(isCheckIn: true))),
                    const SizedBox(width: 12),
                    Expanded(child: _DateTile(label: 'Salida', date: _checkOut, onTap: () => _pickDate(isCheckIn: false))),
                  ],
                ),
                if (_checkIn != null && _checkOut != null && _checkOut!.isAfter(_checkIn!))
                  Padding(
                    padding: const EdgeInsets.only(top: 8, left: 2),
                    child: Text('${Formatters.nights(_checkIn!, _checkOut!)} noche(s)',
                        style: TextStyle(color: Theme.of(context).colorScheme.outline)),
                  ),
                const SizedBox(height: 12),
                _AvailabilityBanner(checking: _checkingAvailability, availability: _availability),

                const _FieldLabel('Huéspedes'),
                _Stepper(
                  value: _guests,
                  onMinus: _guests > 1 ? () => setState(() => _guests--) : null,
                  onPlus: () => setState(() => _guests++),
                ),

                const _SectionLabel('Pago'),
                const _FieldLabel('Precio del alojamiento'),
                TextFormField(
                  controller: _price,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: _fieldDecoration(context, hint: '0', prefixText: r'$ '),
                  validator: (v) {
                    final value = double.tryParse((v ?? '').replaceAll(',', ''));
                    if (value == null || value < 0) return 'Ingresa un valor válido';
                    return null;
                  },
                ),
                const _FieldLabel('Notas (opcional)'),
                TextFormField(
                  controller: _notes,
                  maxLines: 3,
                  decoration: _fieldDecoration(context, hint: 'Detalles, peticiones especiales…'),
                ),

                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _saving ? null : _submit,
                  child: _saving
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(_isEdit ? 'Guardar cambios' : 'Crear reserva'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Decoración de campo: blanco con borde suave y foco verde (no el gris relleno).
InputDecoration _fieldDecoration(BuildContext context, {String? hint, String? prefixText, IconData? icon}) {
  final scheme = Theme.of(context).colorScheme;
  OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: c, width: w),
      );
  return InputDecoration(
    hintText: hint,
    prefixText: prefixText,
    prefixIcon: icon == null ? null : Icon(icon, size: 20),
    filled: true,
    fillColor: Theme.of(context).cardColor,
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    border: border(scheme.outlineVariant),
    enabledBorder: border(scheme.outlineVariant),
    focusedBorder: border(scheme.primary, 1.6),
  );
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 18, bottom: 4),
        child: Text(text,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
              color: Theme.of(context).colorScheme.primary,
            )),
      );
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 14, bottom: 7, left: 2),
        child: Text(text, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
      );
}

/// Contenedor con el mismo estilo que un campo (para dropdown / tiles).
class _BoxField extends StatelessWidget {
  final Widget child;
  const _BoxField({required this.child});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: child,
    );
  }
}

class _DateTile extends StatelessWidget {
  final String label;
  final DateTime? date;
  final VoidCallback onTap;
  const _DateTile({required this.label, required this.date, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(label),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: scheme.outlineVariant),
            ),
            child: Row(
              children: [
                Icon(Icons.event_outlined, size: 19, color: scheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    date != null ? Formatters.date(date!) : 'Elegir',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: date != null ? null : scheme.outline,
                      fontWeight: date != null ? FontWeight.w500 : FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Stepper extends StatelessWidget {
  final int value;
  final VoidCallback? onMinus;
  final VoidCallback onPlus;
  const _Stepper({required this.value, required this.onMinus, required this.onPlus});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(Icons.people_alt_outlined, size: 20, color: scheme.outline),
          const SizedBox(width: 10),
          const Expanded(child: Text('Número de huéspedes')),
          IconButton.filledTonal(onPressed: onMinus, icon: const Icon(Icons.remove)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Text('$value', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          ),
          IconButton.filledTonal(onPressed: onPlus, icon: const Icon(Icons.add)),
        ],
      ),
    );
  }
}

class _AvailabilityBanner extends StatelessWidget {
  final bool checking;
  final Availability? availability;
  const _AvailabilityBanner({required this.checking, required this.availability});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (checking) {
      return Row(children: [
        const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
        const SizedBox(width: 8),
        Text('Verificando disponibilidad…', style: TextStyle(color: scheme.outline)),
      ]);
    }
    if (availability == null) return const SizedBox.shrink();
    final ok = availability!.isAvailable;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (ok ? scheme.primary : scheme.error).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(ok ? Icons.check_circle_outline : Icons.error_outline,
              color: ok ? scheme.primary : scheme.error),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              ok
                  ? 'Disponible en esas fechas.'
                  : 'Cruce con: ${availability!.conflicts.map((c) => c.guestName).join(', ')}',
              style: TextStyle(color: ok ? scheme.primary : scheme.error),
            ),
          ),
        ],
      ),
    );
  }
}
