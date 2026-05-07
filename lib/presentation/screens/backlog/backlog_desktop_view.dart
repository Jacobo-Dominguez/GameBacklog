import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/backlog_provider.dart';
import 'widgets/game_card.dart';
import 'widgets/edit_game_dialog.dart';
import '../../../core/theme/app_theme.dart';

class BacklogDesktopView extends StatelessWidget {
  const BacklogDesktopView({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<BacklogProvider>(
      builder: (context, backlogProvider, child) {
        if (backlogProvider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.accentCyan),
          );
        }

        final entries = backlogProvider.filteredEntries;

        return Column(
          children: [
            _buildFilterBar(context, backlogProvider),
            Expanded(
              child: entries.isEmpty
                  ? _buildEmptyState(context)
                  : GridView.builder(
                      padding: const EdgeInsets.all(24),
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 220,
                        childAspectRatio: 0.58,
                        crossAxisSpacing: 20,
                        mainAxisSpacing: 20,
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

  Widget _buildFilterBar(BuildContext context, BacklogProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.bgDark,
        border: Border(
          bottom: BorderSide(color: const Color(0xFF1E1E3A).withOpacity(0.5)),
        ),
      ),
      child: Row(
        children: [
          _buildFilterChip(provider, 'all', 'Todos', Icons.apps_rounded, null),
          const SizedBox(width: 8),
          _buildFilterChip(provider, 'playing', 'Jugando', Icons.play_arrow_rounded, AppColors.statusPlaying),
          const SizedBox(width: 8),
          _buildFilterChip(provider, 'completed', 'Completados', Icons.check_circle_rounded, AppColors.statusCompleted),
          const SizedBox(width: 8),
          _buildFilterChip(provider, 'pending', 'Pendientes', Icons.schedule_rounded, AppColors.statusPending),
          const SizedBox(width: 8),
          _buildFilterChip(provider, 'on_hold', 'En pausa', Icons.pause_circle_rounded, AppColors.statusOnHold),
          const SizedBox(width: 8),
          _buildFilterChip(provider, 'dropped', 'Abandonados', Icons.cancel_rounded, AppColors.statusDropped),
          const Spacer(),
          // Add Game button with gradient
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: AppColors.primaryGradient,
              boxShadow: [
                BoxShadow(
                  color: AppColors.accentCyan.withOpacity(0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: () => context.push('/search'),
              icon: const Icon(Icons.add_rounded, size: 20),
              label: Text('Agregar Juego', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                foregroundColor: AppColors.bgDark,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
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
    Color? statusColor,
  ) {
    final isSelected = provider.selectedFilter == value;
    final color = statusColor ?? AppColors.accentCyan;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => provider.setFilter(value),
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: isSelected ? color.withOpacity(0.15) : Colors.transparent,
            border: Border.all(
              color: isSelected ? color.withOpacity(0.4) : const Color(0xFF2E2E4E),
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

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  AppColors.accentCyan.withOpacity(0.1),
                  AppColors.accentPurple.withOpacity(0.1),
                ],
              ),
            ),
            child: const Icon(
              Icons.games_outlined,
              size: 56,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Tu backlog está vacío',
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Empieza buscando juegos para añadir a tu colección',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 28),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: AppColors.primaryGradient,
              boxShadow: [
                BoxShadow(
                  color: AppColors.accentCyan.withOpacity(0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: () => context.push('/search'),
              icon: const Icon(Icons.search_rounded),
              label: Text('Buscar juegos', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                foregroundColor: AppColors.bgDark,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
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
        content: const Text('¿Estás seguro de que quieres eliminar este juego de tu backlog?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
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
