import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../providers/backlog_provider.dart';
import '../../../domain/entities/game_session.dart';

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  List<GameSession> _getSessionsForDay(DateTime day, List<GameSession> allSessions) {
    return allSessions.where((session) {
      return isSameDay(session.sessionDate, day);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<BacklogProvider>(
        builder: (context, provider, child) {
          final sessions = provider.recentSessions;

          return Column(
            children: [
              TableCalendar(
                firstDay: DateTime.utc(2010, 10, 16),
                lastDay: DateTime.now(),
                focusedDay: _focusedDay,
                calendarFormat: _calendarFormat,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                },
                onFormatChanged: (format) {
                  setState(() {
                    _calendarFormat = format;
                  });
                },
                eventLoader: (day) => _getSessionsForDay(day, sessions),
                calendarStyle: CalendarStyle(
                  todayDecoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    shape: BoxShape.circle,
                  ),
                  markerDecoration: const BoxDecoration(
                    color: Colors.blueAccent,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              const SizedBox(height: 8.0),
              const Divider(),
              Expanded(
                child: _buildSessionList(_getSessionsForDay(_selectedDay!, sessions), provider),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSessionList(List<GameSession> sessions, BacklogProvider provider) {
    if (sessions.isEmpty) {
      return const Center(
        child: Text(
          'No hay sesiones registradas para este día.',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      itemCount: sessions.length,
      itemBuilder: (context, index) {
        final session = sessions[index];
        final game = provider.gamesMap[session.gameId];

        return ListTile(
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.videogame_asset, color: Colors.blue),
          ),
          title: Text(
            game?.title ?? 'Juego Desconocido',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            '${session.durationMinutes >= 60 ? '${(session.durationMinutes / 60).floor()}h ' : ''}${session.durationMinutes % 60} min - ${session.description ?? "Sin descripción"}',
          ),
          trailing: IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () => _showSessionOptions(context, session),
          ),
        );
      },
    );
  }

  void _showSessionOptions(BuildContext context, GameSession session) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Editar Sesión'),
              onTap: () {
                Navigator.pop(context);
                _showEditSessionDialog(context, session);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Eliminar Sesión', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirmation(context, session);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, GameSession session) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar sesión?'),
        content: const Text('Esta acción restará el tiempo de esta sesión del total de horas jugadas.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          TextButton(
            onPressed: () async {
              final success = await context.read<BacklogProvider>().deleteGameSession(session.id);
              if (success && context.mounted) {
                Navigator.pop(context);
              }
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showEditSessionDialog(BuildContext context, GameSession session) {
    _showSessionDialog(context, session: session);
  }

  void _showSessionDialog(BuildContext context, {required GameSession session}) {
    final hours = (session.durationMinutes / 60).floor();
    final mins = session.durationMinutes % 60;
    
    final hoursController = TextEditingController(text: hours > 0 ? hours.toString() : '');
    final minsController = TextEditingController(text: mins > 0 ? mins.toString() : '');
    final descController = TextEditingController(text: session.description ?? '');
    DateTime selectedDate = session.sessionDate;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Editar Sesión'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Fecha: ${selectedDate.day}/${selectedDate.month}/${selectedDate.year}'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setDialogState(() => selectedDate = picked);
                    }
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: hoursController,
                        decoration: const InputDecoration(
                          labelText: 'Horas',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: minsController,
                        decoration: const InputDecoration(
                          labelText: 'Minutos',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(
                    labelText: 'Descripción (opcional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () async {
                final h = int.tryParse(hoursController.text) ?? 0;
                final m = int.tryParse(minsController.text) ?? 0;
                final totalMinutes = (h * 60) + m;

                if (totalMinutes > 0) {
                  final success = await context.read<BacklogProvider>().updateGameSession(
                    sessionId: session.id,
                    date: selectedDate,
                    durationMinutes: totalMinutes,
                    description: descController.text,
                  );

                  if (success && context.mounted) {
                    Navigator.pop(context);
                  }
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }
}
