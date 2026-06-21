import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/tokens.dart';
import '../../core/formatters.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/cards.dart';
import '../../core/widgets/feedback.dart';
import '../../core/widgets/state_views.dart';
import '../../models/availability.dart';
import '../../models/dome.dart';
import '../../models/reservation.dart';
import '../../providers.dart';

class ReservationFormScreen extends ConsumerStatefulWidget {
  final String? editId;
  final String? initialDate;
  final String? initialDomeId;

  const ReservationFormScreen({
    super.key,
    this.editId,
    this.initialDate,
    this.initialDomeId,
  });

  @override
  ConsumerState<ReservationFormScreen> createState() =>
      _ReservationFormScreenState();
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
  bool _dirty = false;
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

  void _markDirty() {
    if (!_dirty) setState(() => _dirty = true);
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

  Future<void> _maybePop() async {
    if (!_dirty) {
      if (mounted) context.pop();
      return;
    }
    final leave = await showConfirmationSheet(
      context,
      title: 'Descartar cambios',
      message: 'Tienes cambios sin guardar. ¿Salir de todos modos?',
      confirmLabel: 'Descartar',
      cancelLabel: 'Seguir editando',
      icon: Icons.edit_off_rounded,
      accent: AppColors.coral,
    );
    if (leave && mounted) context.pop();
  }

  Future<void> _pickDate({required bool isCheckIn}) async {
    final now = DateTime.now();
    final initial = isCheckIn
        ? (_checkIn ?? now)
        : (_checkOut ??
              _checkIn?.add(const Duration(days: 1)) ??
              now.add(const Duration(days: 1)));
    final first = isCheckIn
        ? DateTime(now.year - 1)
        : (_checkIn ?? now).add(const Duration(days: 1));
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(first) ? first : initial,
      firstDate: first,
      lastDate: DateTime(now.year + 3),
      helpText: isCheckIn ? 'Fecha de llegada' : 'Fecha de salida',
    );
    if (picked == null) return;
    _markDirty();
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
      final result = await ref
          .read(reservationRepositoryProvider)
          .availability(
            _domeId!,
            _checkIn!,
            _checkOut!,
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
      AppSnackBar.show(
        context,
        'Selecciona domo y fechas.',
        type: AppMessageType.error,
      );
      return;
    }
    if (!_checkOut!.isAfter(_checkIn!)) {
      AppSnackBar.show(
        context,
        'La salida debe ser posterior a la llegada.',
        type: AppMessageType.error,
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
      final result = _isEdit
          ? await repo.update(widget.editId!, input)
          : await repo.create(input);
      ref.invalidate(todayProvider);
      if (_isEdit) ref.invalidate(reservationDetailProvider(widget.editId!));
      if (mounted) {
        _dirty = false;
        AppSnackBar.show(
          context,
          _isEdit ? 'Reserva actualizada' : 'Reserva creada',
          type: AppMessageType.success,
        );
        context.go('/reservations/${result.id}');
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.show(context, '$e', type: AppMessageType.error);
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
        loading: () => const Scaffold(
          body: Center(
            child: CircularProgressIndicator(color: AppColors.forest),
          ),
        ),
        error: (e, _) => AppScaffold(
          header: AppHeader(
            title: 'Editar reserva',
            onBack: () => context.pop(),
          ),
          body: ErrorState(
            error: e,
            onRetry: () =>
                ref.invalidate(reservationDetailProvider(widget.editId!)),
          ),
        ),
        data: (r) {
          _prefill(r);
          return _form(domesAsync);
        },
      );
    }
    return _form(domesAsync);
  }

  Widget _form(AsyncValue<List<Dome>> domesAsync) {
    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _maybePop();
      },
      child: AppScaffold(
        header: AppHeader(
          title: _isEdit ? 'Editar reserva' : 'Nueva reserva',
          onBack: _maybePop,
        ),
        bottomBar: _BottomBar(
          child: PrimaryButton(
            label: _isEdit ? 'Guardar cambios' : 'Crear reserva',
            icon: Icons.check_rounded,
            loading: _saving,
            onPressed: _submit,
          ),
        ),
        body: domesAsync.when(
          loading: () => const LoadingState(),
          error: (e, _) => ErrorState(
            error: e,
            onRetry: () => ref.invalidate(activeDomesProvider),
          ),
          data: (domes) {
            _domeId ??= domes.isNotEmpty ? domes.first.id : null;
            return Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.x5,
                  AppSpacing.x2,
                  AppSpacing.x5,
                  AppSpacing.x6,
                ),
                children: [
                  _FormSection(
                    icon: Icons.person_rounded,
                    color: AppColors.violet,
                    title: 'Huésped',
                    children: [
                      AppTextField(
                        controller: _name,
                        label: 'Nombre',
                        required: true,
                        hint: 'Nombre del huésped',
                        textCapitalization: TextCapitalization.words,
                        onChanged: (_) => _markDirty(),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Ingresa el nombre'
                            : null,
                      ),
                      PhoneField(
                        controller: _phone,
                        label: 'Teléfono / WhatsApp',
                        required: true,
                        onChanged: (_) => _markDirty(),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Ingresa un teléfono'
                            : null,
                      ),
                    ],
                  ),
                  _FormSection(
                    icon: Icons.cabin_rounded,
                    color: AppColors.blue,
                    title: 'Estadía',
                    children: [
                      AppSelectField<String>(
                        label: 'Domo',
                        required: true,
                        icon: Icons.cabin_rounded,
                        value:
                            _domeId ?? (domes.isNotEmpty ? domes.first.id : ''),
                        options: [
                          for (final d in domes)
                            SelectOption(
                              d.id,
                              '${d.name} · máx. ${d.maxCapacity}',
                              icon: Icons.cabin_rounded,
                            ),
                        ],
                        onChanged: (v) {
                          _markDirty();
                          setState(() => _domeId = v);
                          _checkAvailability();
                        },
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: DateField(
                              label: 'Llegada',
                              required: true,
                              value: _checkIn,
                              onTap: () => _pickDate(isCheckIn: true),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.x3),
                          Expanded(
                            child: DateField(
                              label: 'Salida',
                              required: true,
                              value: _checkOut,
                              onTap: () => _pickDate(isCheckIn: false),
                            ),
                          ),
                        ],
                      ),
                      if (_checkIn != null &&
                          _checkOut != null &&
                          _checkOut!.isAfter(_checkIn!))
                        _AvailabilityBanner(
                          checking: _checkingAvailability,
                          availability: _availability,
                          nights: Formatters.nights(_checkIn!, _checkOut!),
                        ),
                      StepperField(
                        label: 'Huéspedes',
                        icon: Icons.people_alt_rounded,
                        caption: 'Número de personas',
                        value: _guests,
                        onMinus: _guests > 1
                            ? () {
                                _markDirty();
                                setState(() => _guests--);
                              }
                            : null,
                        onPlus: () {
                          _markDirty();
                          setState(() => _guests++);
                        },
                      ),
                    ],
                  ),
                  _FormSection(
                    icon: Icons.payments_rounded,
                    color: AppColors.forest,
                    title: 'Pago',
                    children: [
                      AppTextField(
                        controller: _price,
                        label: 'Precio del alojamiento',
                        hint: '0',
                        prefixText: r'$ ',
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        onChanged: (_) => _markDirty(),
                        validator: (v) {
                          final value = double.tryParse(
                            (v ?? '').replaceAll(',', ''),
                          );
                          if (value == null || value < 0) {
                            return 'Ingresa un valor válido';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                  _FormSection(
                    icon: Icons.local_cafe_rounded,
                    color: AppColors.coral,
                    title: 'Productos y servicios',
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.x4),
                        decoration: BoxDecoration(
                          color: AppColors.coral.withValues(alpha: 0.08),
                          borderRadius: AppRadii.all(AppRadii.md),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.info_rounded,
                              color: AppColors.coral,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Los consumos se agregan desde el detalle de la reserva, una vez creada.',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  _FormSection(
                    icon: Icons.notes_rounded,
                    color: AppColors.yellow,
                    title: 'Notas',
                    children: [
                      AppTextField(
                        controller: _notes,
                        label: 'Notas (opcional)',
                        hint: 'Detalles o peticiones especiales…',
                        maxLines: 3,
                        onChanged: (_) => _markDirty(),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _FormSection extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final List<Widget> children;
  const _FormSection({
    required this.icon,
    required this.color,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.x5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 2, bottom: AppSpacing.x3),
            child: Row(
              children: [
                CategoryIcon(icon: icon, color: color, size: 30),
                const SizedBox(width: 10),
                Text(title, style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
          ),
          for (var i = 0; i < children.length; i++)
            Padding(
              padding: EdgeInsets.only(
                bottom: i == children.length - 1 ? 0 : AppSpacing.x3,
              ),
              child: children[i],
            ),
        ],
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final Widget child;
  const _BottomBar({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: AppShadows.soft,
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
          child: child,
        ),
      ),
    );
  }
}

class _AvailabilityBanner extends StatelessWidget {
  final bool checking;
  final Availability? availability;
  final int nights;
  const _AvailabilityBanner({
    required this.checking,
    required this.availability,
    required this.nights,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    Widget wrap(Color c, IconData i, String text) => Container(
      margin: const EdgeInsets.only(top: AppSpacing.x3),
      padding: const EdgeInsets.all(AppSpacing.x3),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: AppRadii.all(AppRadii.md),
      ),
      child: Row(
        children: [
          Icon(i, color: c, size: 19),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: t.bodyMedium?.copyWith(
                color: c,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (checking) {
      return wrap(
        AppColors.blue,
        Icons.hourglass_top_rounded,
        'Verificando disponibilidad…',
      );
    }
    if (availability == null) return const SizedBox.shrink();
    if (availability!.isAvailable) {
      return wrap(
        AppColors.forest,
        Icons.check_circle_rounded,
        'Disponible · $nights noche(s)',
      );
    }
    return wrap(
      AppColors.coral,
      Icons.error_rounded,
      'Cruce con: ${availability!.conflicts.map((c) => c.guestName).join(', ')}',
    );
  }
}
