import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../../domain/entities/game.dart';
import '../../../../../domain/entities/game_backlog_entry.dart';

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

  Color _getStatusColor(String status) {
    switch (status) {
      case 'playing': return Colors.blue;
      case 'completed': return Colors.green;
      case 'dropped': return Colors.red;
      case 'on_hold': return Colors.amber;
      default: return Colors.orange;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'playing': return 'Jugando';
      case 'completed': return 'Completado';
      case 'dropped': return 'Abandonado';
      case 'on_hold': return 'En pausa';
      default: return 'Pendiente';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onEdit,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, // Ajuste al contenido
          children: [
            // IMAGEN DE PORTADA
            SizedBox(
              height: 120,
              width: double.infinity,
              child: game.coverUrl != null && game.coverUrl!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: game.coverUrl!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.grey[200],
                        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[200],
                        child: const Icon(Icons.broken_image, size: 40, color: Colors.grey),
                      ),
                    )
                  : Container(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      child: Center(
                        child: Icon(
                          Icons.videogame_asset,
                          size: 64,
                          color: theme.colorScheme.primary.withOpacity(0.5),
                        ),
                      ),
                    ),
            ),
            
            // CONTENIDO
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // TÍTULO Y OPCIONES
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          game.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'edit') onEdit();
                          if (value == 'delete') onDelete();
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
                                Icon(Icons.delete, color: Colors.red, size: 20),
                                SizedBox(width: 8),
                                Text('Eliminar', style: TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                        ],
                        padding: EdgeInsets.zero,
                        icon: const Icon(Icons.more_vert, size: 20),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 4),
                  
                  // PLATAFORMA
                  if (game.platform != null)
                    Text(
                      game.platform!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                  const SizedBox(height: 12),
                  
                  // ESTADO Y RATING
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded( // Usar Expanded para el estado si es largo, o mejor dejarlo fijo y mover info a la derecha
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getStatusColor(entry.status).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _getStatusColor(entry.status).withOpacity(0.5),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            _getStatusLabel(entry.status),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: _getStatusColor(entry.status),
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // INFO (Horas y Rating)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (entry.hoursPlayed > 0) ...[
                            const Icon(Icons.access_time, size: 14, color: Colors.grey),
                            const SizedBox(width: 2),
                            Text(
                              '${entry.hoursPlayed}h',
                              style: theme.textTheme.bodySmall,
                            ),
                            const SizedBox(width: 6),
                          ],
                          if (entry.rating != null) ...[
                            const Icon(Icons.star, size: 14, color: Colors.amber),
                            const SizedBox(width: 2),
                            Text(
                              entry.rating.toString(),
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
