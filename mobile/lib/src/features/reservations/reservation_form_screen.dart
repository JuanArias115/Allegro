import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/formatters.dart';
import '../../core/widgets/app_text_field.dart';
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
                AppTextField(
                  controller: _name,
                  label: 'Nombre',
                  required: true,
                  hint: 'Nombre del huésped',
                  textCapitalization: TextCapitalization.words,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _phone,
                  label: 'Teléfono / WhatsApp',
                  required: true,
                  hint: 'Ej. +57 300 000 0000',
                  prefixIcon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                ),

                const _SectionLabel('Estadía'),
                AppFieldBox(
                  label: 'Domo',
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _domeId,
                      isExpanded: true,
                      borderRadius: BorderRadius.circular(16),
                      style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w500),
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
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _DateField(label: 'Llegada', date: _checkIn, onTap: () => _pickDate(isCheckIn: true))),
                    const SizedBox(width: 12),
                    Expanded(child: _DateField(label: 'Salida', date: _checkOut, onTap: () => _pickDate(isCheckIn: false))),
                  ],
                ),
                if (_checkIn != null && _checkOut != null && _checkOut!.isAfter(_checkIn!))
                  Padding(
                    padding: const EdgeInsets.only(top: 8, left: 4),
                    child: Text('${Formatters.nights(_checkIn!, _checkOut!)} noche(s)',
                        style: TextStyle(color: Theme.of(context).colorScheme.outline)),
                  ),
                const SizedBox(height: 12),
                _AvailabilityBanner(checking: _checkingAvailability, availability: _availability),
                const SizedBox(height: 16),
                AppFieldBox(
                  label: 'Huéspedes',
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      Icon(Icons.people_alt_outlined, size: 20, color: Theme.of(context).colorScheme.outline),
                      const SizedBox(width: 10),
                      const Expanded(child: Text('Número de huéspedes')),
                      IconButton.filledTonal(
                        onPressed: _guests > 1 ? () => setState(() => _guests--) : null,
                        icon: const Icon(Icons.remove),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text('$_guests', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                      ),
                      IconButton.filledTonal(
                        onPressed: () => setState(() => _guests++),
                        icon: const Icon(Icons.add),
                      ),
                    ],
                  ),
                ),

                const _SectionLabel('Pago'),
                AppTextField(
                  controller: _price,
                  label: 'Precio del alojamiento',
                  hint: '0',
                  prefixText: r'$ ',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) {
                    final value = double.tryParse((v ?? '').replaceAll(',', ''));
                    if (value == null || value < 0) return 'Ingresa un valor válido';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _notes,
                  label: 'Notas (opcional)',
                  hint: 'Detalles, peticiones especiales…',
                  maxLines: 3,
                ),

                const SizedBox(height: 28),
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

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 8),
        child: Text(text,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
              color: Theme.of(context).colorScheme.primary,
            )),
      );
}

class _DateField extends StatelessWidget {
  final String label;
  final DateTime? date;
  final VoidCallback onTap;
  const _DateField({required this.label, required this.date, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: scheme.onSurface)),
        ),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 17),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppThemeBorder.of(context)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    date != null ? Formatters.date(date!) : 'Elegir',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16,
                      color: date != null ? null : scheme.outline,
                      fontWeight: date != null ? FontWeight.w500 : FontWeight.w400,
                    ),
                  ),
                ),
                Icon(Icons.calendar_month_rounded, size: 20, color: scheme.primary),
              ],
            ),
          ),
        ),
      ],
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
