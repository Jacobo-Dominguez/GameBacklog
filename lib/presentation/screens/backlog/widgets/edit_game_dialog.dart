import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../domain/entities/game.dart';
import '../../../../domain/entities/game_backlog_entry.dart';

class EditGameDialog extends StatefulWidget {
  final GameBacklogEntry entry;
  final Game game;
  final Function({
    String? status,
    int? hoursPlayed,
    int? rating,
    String? notes,
  }) onUpdate;

  const EditGameDialog({
    super.key,
    required this.entry,
    required this.game,
    required this.onUpdate,
  });

  @override
  State<EditGameDialog> createState() => _EditGameDialogState();
}

class _EditGameDialogState extends State<EditGameDialog> {
  final _formKey = GlobalKey<FormState>();
  final _hoursController = TextEditingController();
  final _notesController = TextEditingController();
  late String _selectedStatus;
  int? _selectedRating;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.entry.status;
    _hoursController.text = widget.entry.hoursPlayed.toString();
    _notesController.text = widget.entry.notes ?? '';
    _selectedRating = widget.entry.rating;
  }

  @override
  void dispose() {
    _hoursController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Editar: ${widget.game.title}'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Estado
              DropdownButtonFormField<String>(
                value: _selectedStatus,
                decoration: const InputDecoration(
                  labelText: 'Estado',
                  prefixIcon: Icon(Icons.flag),
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'pending', child: Text('⏳ Pendiente')),
                  DropdownMenuItem(value: 'playing', child: Text('🎮 Jugando')),
                  DropdownMenuItem(value: 'completed', child: Text('✅ Completado')),
                  DropdownMenuItem(value: 'on_hold', child: Text('⏸️ En pausa')),
                  DropdownMenuItem(value: 'dropped', child: Text('❌ Abandonado')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedStatus = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              // Horas jugadas
              TextFormField(
                controller: _hoursController,
                decoration: const InputDecoration(
                  labelText: 'Horas jugadas',
                  prefixIcon: Icon(Icons.access_time),
                  border: OutlineInputBorder(),
                  suffixText: 'horas',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa las horas';
                  }
                  final hours = int.tryParse(value);
                  if (hours == null || hours < 0) {
                    return 'Ingresa un número válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Calificación
              const Text(
                'Calificación',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: List.generate(11, (index) {
                  return ChoiceChip(
                    label: Text(index.toString()),
                    selected: _selectedRating == index,
                    onSelected: (selected) {
                      setState(() {
                        _selectedRating = selected ? index : null;
                      });
                    },
                  );
                }),
              ),
              const SizedBox(height: 16),

              // Notas
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notas (opcional)',
                  prefixIcon: Icon(Icons.note),
                  border: OutlineInputBorder(),
                  hintText: 'Tus impresiones sobre el juego...',
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              widget.onUpdate(
                status: _selectedStatus,
                hoursPlayed: int.parse(_hoursController.text),
                rating: _selectedRating,
                notes: _notesController.text.trim().isEmpty
                    ? null
                    : _notesController.text.trim(),
              );
              Navigator.pop(context);
            }
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
