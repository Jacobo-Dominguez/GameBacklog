import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/backlog_provider.dart';
import 'widgets/game_card.dart';
import 'widgets/edit_game_dialog.dart';

class BacklogDesktopView extends StatelessWidget {
  const BacklogDesktopView({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<BacklogProvider>(
      builder: (context, backlogProvider, child) {
        if (backlogProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final entries = backlogProvider.filteredEntries;

        return Column(
          children: [
            _buildFilterChips(context, backlogProvider),
            Expanded(
              child: entries.isEmpty
                  ? _buildEmptyState(context)
                  : GridView.builder(
                      padding: const EdgeInsets.all(24),
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 220,
                        childAspectRatio: 0.65,
                        crossAxisSpacing: 24,
                        mainAxisSpacing: 24,
                      ),
                      itemCount: entries.length,
                      itemBuilder: (context, index) {
                        final entry = entries[index];
                        final game = backlogProvider.gamesMap[entry.gameId];

                        if (game == null) return const SizedBox.shrink();

                        return GameCard(
                          entry: entry,
                          game: game,
                          onEdit: () => _showEditGameDialog(context, entry, game),
                          onDelete: () => _showDeleteConfirmation(context, entry.id),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFilterChips(BuildContext context, BacklogProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          _buildFilterChip(provider, 'all', 'Todos', Icons.apps),
          const SizedBox(width: 8),
          _buildFilterChip(provider, 'playing', 'Jugando', Icons.play_arrow),
          const SizedBox(width: 8),
          _buildFilterChip(provider, 'completed', 'Completados', Icons.check),
          const SizedBox(width: 8),
          _buildFilterChip(provider, 'pending', 'Pendientes', Icons.schedule),
          const SizedBox(width: 8),
          _buildFilterChip(provider, 'on_hold', 'En pausa', Icons.pause),
          const SizedBox(width: 8),
          _buildFilterChip(provider, 'dropped', 'Abandonados', Icons.close),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: () => context.push('/search'),
            icon: const Icon(Icons.add),
            label: const Text('Agregar Juego'),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    BacklogProvider provider,
    String value,
    String label,
    IconData icon,
  ) {
    final isSelected = provider.selectedFilter == value;
    return FilterChip(
      selected: isSelected,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
      onSelected: (_) => provider.setFilter(value),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.games_outlined, size: 100, color: Colors.grey[300]),
          const SizedBox(height: 24),
          Text('Tu backlog está vacío', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () => context.push('/search'),
            icon: const Icon(Icons.search),
            label: const Text('Buscar juegos para agregar'),
          ),
        ],
      ),
    );
  }

  void _showEditGameDialog(BuildContext context, entry, game) {
    showDialog(
      context: context,
      builder: (context) => EditGameDialog(
        entry: entry,
        game: game,
        onUpdate: ({status, hoursPlayed, rating, notes}) async {
          final backlogProvider = context.read<BacklogProvider>();
          await backlogProvider.updateGameEntry(
            entryId: entry.id,
            status: status,
            hoursPlayed: hoursPlayed,
            rating: rating,
            notes: notes,
          );
        },
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, String entryId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar juego'),
        content: const Text('¿Estás seguro de que quieres eliminar este juego?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await context.read<BacklogProvider>().removeGame(entryId);
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
