import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/backlog_provider.dart';
import '../../domain/entities/game_session.dart';

class SessionDialog extends StatefulWidget {
  final String gameId;
  final GameSession? existingSession;
  final DateTime? initialDate;

  const SessionDialog({
    super.key,
    required this.gameId,
    this.existingSession,
    this.initialDate,
  });

  @override
  State<SessionDialog> createState() => _SessionDialogState();
}

class _SessionDialogState extends State<SessionDialog> {
  late TextEditingController _hoursController;
  late TextEditingController _minsController;
  late TextEditingController _descController;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    final hours = widget.existingSession != null 
        ? (widget.existingSession!.durationMinutes / 60).floor() 
        : 0;
    final mins = widget.existingSession != null 
        ? widget.existingSession!.durationMinutes % 60 
        : 0;
    
    _hoursController = TextEditingController(text: hours > 0 ? hours.toString() : '');
    _minsController = TextEditingController(text: mins > 0 ? mins.toString() : '');
    _descController = TextEditingController(text: widget.existingSession?.description ?? '');
    _selectedDate = widget.existingSession?.sessionDate ?? widget.initialDate ?? DateTime.now();
  }

  @override
  void dispose() {
    _hoursController.dispose();
    _minsController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        widget.existingSession == null ? 'Registrar Sesión' : 'Editar Sesión',
        style: const TextStyle(color: Colors.white),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                'Fecha: ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                style: const TextStyle(color: Colors.white),
              ),
              trailing: const Icon(Icons.calendar_today, color: Colors.blueAccent),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now(),
                );
                if (picked != null) {
                  setState(() => _selectedDate = picked);
                }
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _hoursController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Horas',
                      labelStyle: TextStyle(color: Colors.white54),
                      border: OutlineInputBorder(),
                      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white12)),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _minsController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Minutos',
                      labelStyle: TextStyle(color: Colors.white54),
                      border: OutlineInputBorder(),
                      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white12)),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Descripción (opcional)',
                labelStyle: TextStyle(color: Colors.white54),
                border: OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white12)),
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar', style: TextStyle(color: Colors.white54)),
        ),
        ElevatedButton(
          onPressed: () async {
            final h = int.tryParse(_hoursController.text) ?? 0;
            final m = int.tryParse(_minsController.text) ?? 0;
            final totalMinutes = (h * 60) + m;

            if (totalMinutes > 0) {
              final provider = context.read<BacklogProvider>();
              bool success;
              if (widget.existingSession == null) {
                success = await provider.addGameSession(
                  gameId: widget.gameId,
                  date: _selectedDate,
                  durationMinutes: totalMinutes,
                  description: _descController.text,
                );
              } else {
                success = await provider.updateGameSession(
                  sessionId: widget.existingSession!.id,
                  date: _selectedDate,
                  durationMinutes: totalMinutes,
                  description: _descController.text,
                );
              }

              if (success && context.mounted) {
                Navigator.pop(context, true);
              }
            }
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
