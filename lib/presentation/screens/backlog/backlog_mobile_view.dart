import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/backlog_provider.dart';
import 'widgets/game_card.dart';
import 'widgets/edit_game_dialog.dart';
import '../../../core/theme/app_theme.dart';

class BacklogMobileView extends StatelessWidget {
  const BacklogMobileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<BacklogProvider>(
      builder: (context, backlogProvider, child) {
        if (backlogProvider.isLoading) {
          return const Center(child: CircularProgressIndicator(color: AppColors.accentCyan));
        }

        final entries = backlogProvider.filteredEntries;

        return Column(
          children: [
            // Filtros rápidos horizontales
            _buildMobileFilters(backlogProvider),
            
            // Lista de juegos
            Expanded(
              child: entries.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: entries.length,
                      itemBuilder: (context, index) {
                        final entry = entries[index];
                        final game = backlogProvider.gamesMap[entry.gameId];

                        if (game == null) return const SizedBox.shrink();

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: GameCard(
                            entry: entry,
                            game: game,
                            onEdit: () => _showEditGameDialog(context, entry, game),
                            onDelete: () => _showDeleteConfirmation(context, entry.id),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMobileFilters(BacklogProvider provider) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildFilterChip(provider, 'all', 'Todos', Icons.apps_rounded, null),
          const SizedBox(width: 8),
          _buildFilterChip(provider, 'playing', 'Jugando', Icons.play_arrow_rounded, AppColors.statusPlaying),
          const SizedBox(width: 8),
          _buildFilterChip(provider, 'completed', 'Completado', Icons.check_circle_rounded, AppColors.statusCompleted),
          const SizedBox(width: 8),
          _buildFilterChip(provider, 'pending', 'Pendiente', Icons.schedule_rounded, AppColors.statusPending),
          const SizedBox(width: 8),
          _buildFilterChip(provider, 'on_hold', 'Pausa', Icons.pause_circle_rounded, AppColors.statusOnHold),
          const SizedBox(width: 8),
          _buildFilterChip(provider, 'dropped', 'Drop', Icons.cancel_rounded, AppColors.statusDropped),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    BacklogProvider provider,
    String value,
    String label,
    IconData icon,
    Color? statusColor,
  ) {
    final isSelected = provider.selectedFilter == value;
    final color = statusColor ?? AppColors.accentCyan;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => provider.setFilter(value),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: isSelected ? color.withOpacity(0.15) : AppColors.bgCard,
            border: Border.all(
              color: isSelected ? color.withOpacity(0.4) : const Color(0xFF2A2A4A),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? color : AppColors.textMuted,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? color : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.videogame_asset_off_rounded, size: 64, color: AppColors.textMuted.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(
            'Tu backlog está vacío',
            style: GoogleFonts.outfit(fontSize: 18, color: AppColors.textMuted),
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
        title: const Text('¿Eliminar juego?'),
        content: const Text('Esta acción no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await context.read<BacklogProvider>().removeGame(entryId);
            },
            child: const Text('Eliminar', style: TextStyle(color: AppColors.accentRose)),
          ),
        ],
      ),
    );
  }
}
