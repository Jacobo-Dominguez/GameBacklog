import 'package:flutter/material.dart';
import '../../../core/utils/image_utils.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/backlog_provider.dart';
import 'widgets/game_card.dart';
import 'widgets/edit_game_dialog.dart';

class BacklogDesktopView extends StatefulWidget {
  const BacklogDesktopView({super.key});

  @override
  State<BacklogDesktopView> createState() => _BacklogDesktopViewState();
}

class _BacklogDesktopViewState extends State<BacklogDesktopView> {
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
      body: Row(
        children: [
          // NavigationRail
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              if (index == 1) {
                context.push('/search');
              } else if (index == 3) {
                context.go('/profile');
              } else if (index == 4) {
                context.push('/journal');
              } else if (index == 5) {
                context.push('/collections');
              } else {
                setState(() {
                  _selectedIndex = index;
                });
              }
            },
            labelType: NavigationRailLabelType.all,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  Image.asset(
                    'assets/icons/logo_app2.png',
                    height: 32,
                    width: 32,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Game\nBacklog',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.games_outlined),
                selectedIcon: Icon(Icons.games),
                label: Text('Backlog'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.search),
                label: Text('Buscar'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.bar_chart_outlined),
                selectedIcon: Icon(Icons.bar_chart),
                label: Text('Estadísticas'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: const Icon(Icons.person),
                label: const Text('Perfil'),
              ),
              NavigationRailDestination(
                icon: const Icon(Icons.calendar_month_outlined),
                selectedIcon: const Icon(Icons.calendar_month),
                label: const Text('Diario'),
              ),
              NavigationRailDestination(
                icon: const Icon(Icons.collections_bookmark_outlined),
                selectedIcon: const Icon(Icons.collections_bookmark),
                label: const Text('Colecciones'),
              ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),

          // Contenido principal
          Expanded(
            child: Column(
              children: [
                // App bar personalizado
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    border: Border(
                      bottom: BorderSide(
                        color: Theme.of(context).dividerColor,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        _getTitle(),
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Text(
                            user?.username ?? '',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          const SizedBox(width: 12),
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            backgroundImage: ImageUtils.getAvatarProvider(user?.avatarUrl),
                            child: (user?.avatarUrl == null || user!.avatarUrl!.isEmpty)
                                ? Text(
                                    user?.username[0].toUpperCase() ?? 'U',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.white,
                                    ),
                                  )
                                : null,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Contenido
                Expanded(
                  child: _buildBody(),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton.extended(
              heroTag: 'search',
              onPressed: () => context.push('/search'),
              icon: const Icon(Icons.search),
              label: const Text('Buscar'),
            )
          : null,
    );
  }

  String _getTitle() {
    switch (_selectedIndex) {
      case 0:
        return 'Mi Backlog';
      case 1:
        return 'Buscar Juegos';
      case 2:
        return 'Estadísticas';
      default:
        return 'Game Backlog';
    }
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
            _buildFilterChips(backlogProvider),
            Expanded(
              child: entries.isEmpty
                  ? _buildEmptyState()
                  : GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 250,
                        childAspectRatio: 0.7,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
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

  Widget _buildFilterChips(BacklogProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _buildFilterChip(provider, 'all', 'Todos', Icons.apps),
          _buildFilterChip(provider, 'playing', 'Jugando', Icons.play_arrow),
          _buildFilterChip(provider, 'completed', 'Completados', Icons.check),
          _buildFilterChip(provider, 'pending', 'Pendientes', Icons.schedule),
          _buildFilterChip(provider, 'on_hold', 'En pausa', Icons.pause),
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
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.games_outlined,
              size: 120,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 24),
            Text(
              'Tu backlog está vacío',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 12),
            Text(
              'Comienza agregando juegos a tu colección',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
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
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Buscar juegos en tu backlog...',
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
            ),
            Expanded(
              child: backlogProvider.filteredEntries.isEmpty
                  ? Center(
                      child: Text(
                        backlogProvider.searchQuery.isEmpty
                            ? 'Escribe para buscar en tu backlog'
                            : 'No se encontraron juegos',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 250,
                        childAspectRatio: 0.7,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
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

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: GridView.count(
              padding: const EdgeInsets.all(24),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 2.5,
              children: [
                _buildStatCard('Total de juegos', total.toString(), Icons.games, Colors.blue),
                _buildStatCard('Jugando', stats['playing']?.toString() ?? '0', Icons.play_arrow, Colors.blue),
                _buildStatCard('Completados', stats['completed']?.toString() ?? '0', Icons.check, Colors.green),
                _buildStatCard('Pendientes', stats['pending']?.toString() ?? '0', Icons.schedule, Colors.orange),
                _buildStatCard('En pausa', stats['on_hold']?.toString() ?? '0', Icons.pause, Colors.amber),
                _buildStatCard('Abandonados', stats['dropped']?.toString() ?? '0', Icons.close, Colors.red),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: color.withOpacity(0.1),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(fontSize: 14),
                  ),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
