import 'package:flutter/material.dart';

class AddGameDialog extends StatefulWidget {
  final Function(String title, String platform, String status, String? genre) onAdd;

  const AddGameDialog({
    super.key,
    required this.onAdd,
  });

  @override
  State<AddGameDialog> createState() => _AddGameDialogState();
}

class _AddGameDialogState extends State<AddGameDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _platformController = TextEditingController();
  final _genreController = TextEditingController();
  String _selectedStatus = 'pending';

  @override
  void dispose() {
    _titleController.dispose();
    _platformController.dispose();
    _genreController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Agregar Juego'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Título del juego *',
                  prefixIcon: Icon(Icons.games),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa el título';
                  }
                  return null;
                },
                autofocus: true,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _platformController,
                decoration: const InputDecoration(
                  labelText: 'Plataforma *',
                  prefixIcon: Icon(Icons.devices),
                  border: OutlineInputBorder(),
                  hintText: 'PC, PS5, Switch, etc.',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa la plataforma';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _genreController,
                decoration: const InputDecoration(
                  labelText: 'Género (opcional)',
                  prefixIcon: Icon(Icons.category),
                  border: OutlineInputBorder(),
                  hintText: 'RPG, Acción, etc.',
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedStatus,
                decoration: const InputDecoration(
                  labelText: 'Estado inicial',
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
              widget.onAdd(
                _titleController.text.trim(),
                _platformController.text.trim(),
                _selectedStatus,
                _genreController.text.trim().isEmpty
                    ? null
                    : _genreController.text.trim(),
              );
              Navigator.pop(context);
            }
          },
          child: const Text('Agregar'),
        ),
      ],
    );
  }
}
