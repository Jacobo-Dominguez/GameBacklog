import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/backlog_provider.dart';
import '../../../domain/entities/game.dart';
import '../../../domain/entities/game_backlog_entry.dart';

class GameDetailScreen extends StatefulWidget {
  final String gameId;

  const GameDetailScreen({
    super.key,
    required this.gameId,
  });

  @override
  State<GameDetailScreen> createState() => _GameDetailScreenState();
}

class _GameDetailScreenState extends State<GameDetailScreen> {
  final _notesController = TextEditingController();
  bool _isEditingNotes = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BacklogProvider>(
      builder: (context, backlogProvider, child) {
        // Buscar el juego y su entrada en el backlog
        final game = backlogProvider.gamesMap[widget.gameId];
        final entry = backlogProvider.backlogEntries.firstWhere(
          (e) => e.gameId == widget.gameId,
          orElse: () => throw Exception('Game not found'),
        );

        if (game == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Juego no encontrado')),
            body: const Center(child: Text('El juego no existe')),
          );
        }

        // Inicializar notas
        if (_notesController.text.isEmpty && entry.notes != null) {
          _notesController.text = entry.notes!;
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(game.title),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.pop(),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _showDeleteConfirmation(context, entry.id),
                tooltip: 'Eliminar juego',
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Icono del juego
                    Center(
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: _getStatusColor(entry.status).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          Icons.games,
                          size: 64,
                          color: _getStatusColor(entry.status),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Título y plataforma
                    Text(
                      game.title,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    if (game.platform != null)
                      Text(
                        '🎮 ${game.platform}',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Colors.grey[600],
                            ),
                        textAlign: TextAlign.center,
                      ),
                    if (game.genre != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        '📁 ${game.genre}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 32),

                    // Estado
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Estado',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              value: entry.status,
                              decoration: InputDecoration(
                                border: const OutlineInputBorder(),
                                prefixIcon: Icon(
                                  _getStatusIcon(entry.status),
                                  color: _getStatusColor(entry.status),
                                ),
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
                                  _updateStatus(context, entry.id, value);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Horas jugadas
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Horas Jugadas',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton.filled(
                                  onPressed: entry.hoursPlayed > 0
                                      ? () => _updateHours(context, entry.id, entry.hoursPlayed - 1)
                                      : null,
                                  icon: const Icon(Icons.remove),
                                ),
                                const SizedBox(width: 24),
                                Text(
                                  '${entry.hoursPlayed}h',
                                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                const SizedBox(width: 24),
                                IconButton.filled(
                                  onPressed: () => _updateHours(context, entry.id, entry.hoursPlayed + 1),
                                  icon: const Icon(Icons.add),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Calificación
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Calificación',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 12),
                            Center(
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                alignment: WrapAlignment.center,
                                children: List.generate(11, (index) {
                                  return ChoiceChip(
                                    label: Text(index.toString()),
                                    selected: entry.rating == index,
                                    onSelected: (selected) {
                                      _updateRating(context, entry.id, selected ? index : null);
                                    },
                                  );
                                }),
                              ),
                            ),
                            if (entry.rating != null) ...[
                              const SizedBox(height: 12),
                              Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    ...List.generate(
                                      5,
                                      (index) => Icon(
                                        index < (entry.rating! / 2).round()
                                            ? Icons.star
                                            : Icons.star_border,
                                        color: Colors.amber,
                                        size: 32,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${entry.rating}/10',
                                      style: Theme.of(context).textTheme.titleLarge,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Notas
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Notas',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                if (_isEditingNotes)
                                  TextButton(
                                    onPressed: () {
                                      _updateNotes(context, entry.id, _notesController.text);
                                      setState(() {
                                        _isEditingNotes = false;
                                      });
                                    },
                                    child: const Text('Guardar'),
                                  )
                                else
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: () {
                                      setState(() {
                                        _isEditingNotes = true;
                                      });
                                    },
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            if (_isEditingNotes)
                              TextField(
                                controller: _notesController,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  hintText: 'Escribe tus notas aquí...',
                                ),
                                maxLines: 5,
                                autofocus: true,
                              )
                            else
                              Text(
                                entry.notes?.isEmpty ?? true
                                    ? 'Sin notas'
                                    : entry.notes!,
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Información adicional
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Información',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 12),
                            _buildInfoRow('Agregado', _formatDate(entry.addedDate)),
                            const Divider(),
                            _buildInfoRow('Última actualización', _formatDate(entry.lastUpdated)),
                            if (entry.completedDate != null) ...[
                              const Divider(),
                              _buildInfoRow('Completado', _formatDate(entry.completedDate!)),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.grey),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Future<void> _updateStatus(BuildContext context, String entryId, String status) async {
    final backlogProvider = context.read<BacklogProvider>();
    final success = await backlogProvider.updateGameEntry(
      entryId: entryId,
      status: status,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Estado actualizado')),
      );
    }
  }

  Future<void> _updateHours(BuildContext context, String entryId, int hours) async {
    final backlogProvider = context.read<BacklogProvider>();
    final success = await backlogProvider.updateGameEntry(
      entryId: entryId,
      hoursPlayed: hours,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Horas actualizadas')),
      );
    }
  }

  Future<void> _updateRating(BuildContext context, String entryId, int? rating) async {
    final backlogProvider = context.read<BacklogProvider>();
    final success = await backlogProvider.updateGameEntry(
      entryId: entryId,
      rating: rating,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Calificación actualizada')),
      );
    }
  }

  Future<void> _updateNotes(BuildContext context, String entryId, String notes) async {
    final backlogProvider = context.read<BacklogProvider>();
    final success = await backlogProvider.updateGameEntry(
      entryId: entryId,
      notes: notes.isEmpty ? null : notes,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notas guardadas')),
      );
    }
  }

  void _showDeleteConfirmation(BuildContext context, String entryId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar juego'),
        content: const Text('¿Estás seguro de que quieres eliminar este juego del backlog?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final backlogProvider = context.read<BacklogProvider>();
              final success = await backlogProvider.removeGame(entryId);

              if (success && mounted) {
                context.pop(); // Volver a la lista
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Juego eliminado')),
                );
              }
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'playing':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'on_hold':
        return Colors.amber;
      case 'dropped':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'playing':
        return Icons.play_arrow;
      case 'completed':
        return Icons.check;
      case 'pending':
        return Icons.schedule;
      case 'on_hold':
        return Icons.pause;
      case 'dropped':
        return Icons.close;
      default:
        return Icons.help;
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'ene', 'feb', 'mar', 'abr', 'may', 'jun',
      'jul', 'ago', 'sep', 'oct', 'nov', 'dic'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
