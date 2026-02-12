import 'package:flutter/material.dart';
import '../../../core/utils/image_utils.dart';
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
        title: Text(_getTitle()),
        actions: [
          if (_selectedIndex == 0)
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                // Navegar a búsqueda global
                context.push('/search');
              },
            ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              backgroundImage: ImageUtils.getAvatarProvider(user?.avatarUrl),
              child: (user?.avatarUrl == null || user!.avatarUrl!.isEmpty)
                  ? Text(
                      user?.username[0].toUpperCase() ?? 'U',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
          ),
        ],
      ),
      drawer: _buildDrawer(context, user),
      body: _buildBody(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          if (index == 1) {
            // Ir a pantalla de búsqueda dedicada en lugar de cambiar tab
            context.push('/search');
          } else if (index == 3) {
            context.go('/profile');
          } else {
            setState(() {
              _selectedIndex = index;
            });
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.games_outlined),
            selectedIcon: Icon(Icons.games),
            label: 'Backlog',
          ),
          NavigationDestination(
            icon: Icon(Icons.search),
            label: 'Buscar Online',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Stats',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
              onPressed: () => _showAddOptions(context),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  String _getTitle() {
    switch (_selectedIndex) {
      case 0:
        return 'Mi Backlog';
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
      case 2:
        return _buildStatsTab();
      default:
        return _buildBacklogTab();
    }
  }

  Widget _buildDrawer(BuildContext context, dynamic user) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(user?.username ?? 'Usuario'),
            accountEmail: Text(user?.email ?? ''),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                user?.username[0].toUpperCase() ?? 'U',
                style: const TextStyle(fontSize: 24.0),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Mi Perfil'),
            onTap: () {
              context.pop(); // cerrar drawer
              context.go('/profile');
            },
          ),
          ListTile(
            leading: const Icon(Icons.calendar_month),
            title: const Text('Mi Diario'),
            onTap: () {
              context.pop();
              context.push('/journal');
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Cerrar Sesión', style: TextStyle(color: Colors.red)),
            onTap: () async {
              context.pop();
              await context.read<AuthProvider>().logout();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
    );
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
            // Filtros rápidos
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  _buildFilterChip(backlogProvider, 'all', 'Todos'),
                  const SizedBox(width: 8),
                  _buildFilterChip(backlogProvider, 'playing', 'Jugando'),
                  const SizedBox(width: 8),
                  _buildFilterChip(backlogProvider, 'completed', 'Completados'),
                  const SizedBox(width: 8),
                  _buildFilterChip(backlogProvider, 'pending', 'Pendientes'),
                  const SizedBox(width: 8),
                  _buildFilterChip(backlogProvider, 'dropped', 'Abandonados'),
                ],
              ),
            ),
            Expanded(
              child: entries.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
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

  Widget _buildFilterChip(BacklogProvider provider, String value, String label) {
    return FilterChip(
      label: Text(label),
      selected: provider.selectedFilter == value,
      onSelected: (_) => provider.setFilter(value),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.videogame_asset_off, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No hay juegos',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatsTab() {
     return Consumer<BacklogProvider>(
      builder: (context, backlogProvider, child) {
        final stats = backlogProvider.stats;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildStatCard('Jugando', stats['playing'] ?? 0, Colors.blue, Icons.play_arrow),
            _buildStatCard('Completados', stats['completed'] ?? 0, Colors.green, Icons.check_circle),
            _buildStatCard('Pendientes', stats['pending'] ?? 0, Colors.orange, Icons.schedule),
            _buildStatCard('En pausa', stats['on_hold'] ?? 0, Colors.amber, Icons.pause),
            _buildStatCard('Abandonados', stats['dropped'] ?? 0, Colors.red, Icons.cancel),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String label, int value, Color color, IconData icon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(label),
        trailing: Text(
          value.toString(),
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  void _showAddOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.search, color: Colors.blue),
            title: const Text('Buscar en RAWG (Recomendado)'),
            subtitle: const Text('Obtiene portada y datos automáticamente'),
            onTap: () {
              Navigator.pop(context); // cerrar sheet
              context.push('/search');
            },
          ),
          ListTile(
            leading: const Icon(Icons.edit, color: Colors.grey),
            title: const Text('Agregar Manualmente'),
            subtitle: const Text('Ingresa los datos del juego tú mismo'),
            onTap: () {
              Navigator.pop(context); // cerrar sheet
              _showAddGameDialog(context);
            },
          ),
          const SizedBox(height: 16),
        ],
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
