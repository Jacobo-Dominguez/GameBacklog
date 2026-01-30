import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../domain/entities/game.dart';
import '../../../../domain/entities/game_backlog_entry.dart';

class GameCard extends StatelessWidget {
  final GameBacklogEntry entry;
  final Game game;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const GameCard({
    super.key,
    required this.entry,
    required this.game,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () {
          // TODO: Navegar a detalle del juego
          context.push('/game/${game.id}');
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Icono del juego
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: _getStatusColor(entry.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.games,
                  size: 28,
                  color: _getStatusColor(entry.status),
                ),
              ),
              const SizedBox(width: 12),

              // Información del juego
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      game.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    if (game.platform != null)
                      Text(
                        '🎮 ${game.platform}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    const SizedBox(height: 2),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _buildStatusChip(context),
                        Text(
                          '⏱️ ${entry.hoursPlayed}h',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        if (entry.rating != null)
                          Text(
                            '⭐ ${entry.rating}/10',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // Menú de acciones
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) {
                  if (value == 'edit') {
                    onEdit();
                  } else if (value == 'delete') {
                    onDelete();
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 20),
                        SizedBox(width: 8),
                        Text('Editar'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 20, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Eliminar', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getStatusColor(entry.status).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _getStatusLabel(entry.status),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: _getStatusColor(entry.status),
        ),
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

  String _getStatusLabel(String status) {
    switch (status) {
      case 'playing':
        return 'Jugando';
      case 'completed':
        return 'Completado';
      case 'pending':
        return 'Pendiente';
      case 'on_hold':
        return 'En pausa';
      case 'dropped':
        return 'Abandonado';
      default:
        return status;
    }
  }
}
