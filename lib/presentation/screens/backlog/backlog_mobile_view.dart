import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/backlog_provider.dart';
import 'widgets/game_card.dart';
import 'widgets/add_game_dialog.dart';
import 'widgets/edit_game_dialog.dart';

class BacklogMobileView extends StatefulWidget {
  const BacklogMobileView({super.key});

  @override
  State<BacklogMobileView> createState() => _BacklogMobileViewState();
}

class _BacklogMobileViewState extends State<BacklogMobileView> {
  int _selectedIndex = 0;
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Game Backlog'),
        actions: [
          IconButton(
            icon: CircleAvatar(
              radius: 16,
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: Text(
                user?.username[0].toUpperCase() ?? 'U',
                style: const TextStyle(fontSize: 14, color: Colors.white),
              ),
            ),
            onPressed: () => context.go('/profile'),
            tooltip: 'Perfil',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.games),
            label: 'Backlog',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Buscar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Estadísticas',
          ),
        ],
      ),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
              onPressed: () => _showAddGameDialog(context),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildBacklogTab();
      case 1:
        return _buildSearchTab();
      case 2:
        return _buildStatsTab();
      default:
        return _buildBacklogTab();
    }
  }

  Widget _buildBacklogTab() {
    return Consumer<BacklogProvider>(
      builder: (context, backlogProvider, child) {
        if (backlogProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final entries = backlogProvider.filteredEntries;

        return Column(
          children: [
            // Filtros
            _buildFilterChips(backlogProvider),

            // Lista de juegos
            Expanded(
              child: entries.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
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

  Widget _buildFilterChips(BacklogProvider provider) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(16),
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.games_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No hay juegos',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Agrega juegos usando el botón +',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchTab() {
    return Consumer<BacklogProvider>(
      builder: (context, backlogProvider, child) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Buscar juegos...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            backlogProvider.clearSearch();
                          },
                        )
                      : null,
                  border: const OutlineInputBorder(),
                ),
                onChanged: (value) {
                  backlogProvider.setSearchQuery(value);
                },
              ),
            ),
            Expanded(
              child: backlogProvider.filteredEntries.isEmpty
                  ? Center(
                      child: Text(
                        backlogProvider.searchQuery.isEmpty
                            ? 'Escribe para buscar'
                            : 'No se encontraron juegos',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    )
                  : ListView.builder(
                      itemCount: backlogProvider.filteredEntries.length,
                      itemBuilder: (context, index) {
                        final entry = backlogProvider.filteredEntries[index];
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

  Widget _buildStatsTab() {
    return Consumer<BacklogProvider>(
      builder: (context, backlogProvider, child) {
        final stats = backlogProvider.stats;
        final total = backlogProvider.getTotalGames();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Estadísticas del Backlog',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 24),
              _buildStatCard('Total de juegos', total.toString(), Icons.games, Colors.blue),
              _buildStatCard('Jugando', stats['playing']?.toString() ?? '0', Icons.play_arrow, Colors.blue),
              _buildStatCard('Completados', stats['completed']?.toString() ?? '0', Icons.check, Colors.green),
              _buildStatCard('Pendientes', stats['pending']?.toString() ?? '0', Icons.schedule, Colors.orange),
              _buildStatCard('En pausa', stats['on_hold']?.toString() ?? '0', Icons.pause, Colors.amber),
              _buildStatCard('Abandonados', stats['dropped']?.toString() ?? '0', Icons.close, Colors.red),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(label),
        trailing: Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ),
    );
  }

  void _showAddGameDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AddGameDialog(
        onAdd: (title, platform, status, genre) async {
          final backlogProvider = context.read<BacklogProvider>();
          final success = await backlogProvider.addGame(
            title: title,
            platform: platform,
            status: status,
            genre: genre,
          );

          if (success && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Juego agregado exitosamente')),
            );
          }
        },
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
          final success = await backlogProvider.updateGameEntry(
            entryId: entry.id,
            status: status,
            hoursPlayed: hoursPlayed,
            rating: rating,
            notes: notes,
          );

          if (success && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Juego actualizado exitosamente')),
            );
          }
        },
      ),
    );
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

              if (success && context.mounted) {
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
}
