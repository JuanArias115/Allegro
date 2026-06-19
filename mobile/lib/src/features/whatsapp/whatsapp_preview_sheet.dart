import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/whatsapp.dart';
import '../../models/reservation.dart';

/// Abre una hoja para previsualizar y editar el mensaje antes de enviarlo.
Future<void> showWhatsAppPreview(
  BuildContext context,
  Reservation reservation, {
  WhatsAppTemplate initial = WhatsAppTemplate.confirmation,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _WhatsAppPreviewSheet(reservation: reservation, initial: initial),
  );
}

class _WhatsAppPreviewSheet extends StatefulWidget {
  final Reservation reservation;
  final WhatsAppTemplate initial;

  const _WhatsAppPreviewSheet({required this.reservation, required this.initial});

  @override
  State<_WhatsAppPreviewSheet> createState() => _WhatsAppPreviewSheetState();
}

class _WhatsAppPreviewSheetState extends State<_WhatsAppPreviewSheet> {
  late WhatsAppTemplate _template = widget.initial;
  late final TextEditingController _controller =
      TextEditingController(text: WhatsAppMessages.build(_template, widget.reservation));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _regenerate(WhatsAppTemplate t) {
    setState(() {
      _template = t;
      _controller.text = WhatsAppMessages.build(t, widget.reservation);
    });
  }

  Future<void> _sendWhatsApp() async {
    final ok = await WhatsAppMessages.openWhatsApp(widget.reservation.phone, _controller.text);
    if (!ok && mounted) {
      // Si no se pudo abrir WhatsApp, usamos el menú nativo de compartir.
      await WhatsAppMessages.share(_controller.text);
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 4,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Mensaje de WhatsApp', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text('Para ${widget.reservation.guestName} · ${widget.reservation.phone}',
              style: TextStyle(color: scheme.outline)),
          const SizedBox(height: 16),
          DropdownButtonFormField<WhatsAppTemplate>(
            initialValue: _template,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Tipo de mensaje'),
            items: [
              for (final t in WhatsAppTemplate.values)
                DropdownMenuItem(value: t, child: Text(t.label, overflow: TextOverflow.ellipsis)),
            ],
            onChanged: (t) => _regenerate(t ?? _template),
          ),
          const SizedBox(height: 12),
          Text('Vista previa (editable)',
              style: TextStyle(color: scheme.outline, fontSize: 13)),
          const SizedBox(height: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 260),
            child: TextField(
              controller: _controller,
              maxLines: null,
              minLines: 5,
              keyboardType: TextInputType.multiline,
              decoration: const InputDecoration(),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: _controller.text));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Mensaje copiado')),
                    );
                  }
                },
                icon: const Icon(Icons.copy_rounded, size: 18),
                label: const Text('Copiar'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => WhatsAppMessages.share(_controller.text),
                  icon: const Icon(Icons.ios_share_rounded, size: 18),
                  label: const Text('Compartir'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: _sendWhatsApp,
            icon: const Icon(Icons.send_rounded, size: 18),
            label: const Text('Enviar por WhatsApp'),
          ),
        ],
      ),
    );
  }
}
