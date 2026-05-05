import 'package:flutter/material.dart';
import '../../../core/utils/image_utils.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/backlog_provider.dart'; // ✅ Nuevo
import '../../../data/datasources/game_backlog_local_datasource_impl.dart';
import '../../../data/datasources/database_helper.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, int> _stats = {};
  bool _isLoadingStats = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final authProvider = context.read<AuthProvider>();
    if (authProvider.currentUser == null) return;

    try {
      final dbHelper = DatabaseHelper.instance;
      final backlogDataSource = GameBacklogLocalDataSourceImpl(dbHelper);
      final stats = await backlogDataSource.getStatsByUserId(
        authProvider.currentUser!.id,
      );

      if (mounted) {
        setState(() {
          _stats = stats;
          _isLoadingStats = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingStats = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final backlogProvider = context.watch<BacklogProvider>();
    final user = authProvider.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final favorites = backlogProvider.backlogEntries
        .where((e) => e.isFavorite)
        .toList();

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              children: [
                // Header del Perfil
                _buildProfileHeader(context, user),
                const SizedBox(height: 32),

                // Sección de Favoritos (NUEVO)
                if (favorites.isNotEmpty) ...[
                  _buildFavoritesSection(context, favorites, backlogProvider.gamesMap),
                  const SizedBox(height: 32),
                ],

                // Estadísticas del backlog
                _buildStatsCard(context, backlogProvider),
                const SizedBox(height: 32),

                // Acciones de Usuario
                _buildAccountActions(context, authProvider),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, dynamic user) {
    final avatarImage = ImageUtils.getAvatarProvider(user.avatarUrl);

    return Column(
      children: [
        GestureDetector(
          onTap: () => context.push('/edit-profile'),
          child: Stack(
            children: [
              CircleAvatar(
                radius: 60,
                backgroundColor: Theme.of(context).colorScheme.primary,
                backgroundImage: avatarImage,
                child: avatarImage == null
                    ? Text(
                        user.username[0].toUpperCase(),
                        style: const TextStyle(fontSize: 48, color: Colors.white, fontWeight: FontWeight.bold),
                      )
                    : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 2),
                  ),
                  child: const Icon(Icons.edit, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          user.username,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(
          user.email,
          style: TextStyle(color: Colors.grey[400], fontSize: 16),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
           onPressed: () => context.push('/edit-profile'),
           icon: const Icon(Icons.settings),
           label: const Text('Editar Perfil'),
        ),
        const SizedBox(height: 8),
        Text(
          'Miembro desde ${_formatDate(user.createdAt)}',
          style: TextStyle(color: Colors.grey[600], fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildFavoritesSection(BuildContext context, List<dynamic> favorites, Map<String, dynamic> gamesMap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'Juegos Favoritos ❤️',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: favorites.length,
            itemBuilder: (context, index) {
              final entry = favorites[index];
              final game = gamesMap[entry.gameId];
              if (game == null) return const SizedBox.shrink();

              return GestureDetector(
                onTap: () => context.go('/game/${game.id}'),
                child: Container(
                  width: 130,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  child: Column(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: game.coverUrl != null && game.coverUrl.isNotEmpty
                              ? Image.network(game.coverUrl!, fit: BoxFit.cover, width: double.infinity)
                              : Container(color: Colors.grey[800], child: const Icon(Icons.videogame_asset)),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        game.title,
                        maxLines: 2,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatsCard(BuildContext context, BacklogProvider provider) {
    final stats = provider.stats;
    final total = provider.getTotalGames();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tu Backlog en cifras',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              if (total == 0)
                const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('No hay juegos añadidos aún.', style: TextStyle(color: Colors.grey))))
              else
                Column(
                  children: [
                    _buildStatRow(context, '🎮 Jugando ahora', stats['playing'] ?? 0, Colors.blue),
                    const Divider(height: 24),
                    _buildStatRow(context, '✅ Completados', stats['completed'] ?? 0, Colors.green),
                    const Divider(height: 24),
                    _buildStatRow(context, '⏳ Pendientes', stats['pending'] ?? 0, Colors.orange),
                    const Divider(height: 24),
                    _buildStatRow(context, '⏸️ En pausa', stats['on_hold'] ?? 0, Colors.amber),
                    const Divider(height: 24),
                    _buildStatRow(context, '❌ Abandonados', stats['dropped'] ?? 0, Colors.red),
                    const SizedBox(height: 20),
                    Container(
                       padding: const EdgeInsets.all(16),
                       decoration: BoxDecoration(
                         color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                         borderRadius: BorderRadius.circular(12),
                       ),
                       child: Row(
                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total de Juegos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          Text('$total', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                        ],
                       ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                       padding: const EdgeInsets.all(16),
                       decoration: BoxDecoration(
                         color: Colors.blue.withOpacity(0.1),
                         borderRadius: BorderRadius.circular(12),
                       ),
                       child: Row(
                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Tiempo Total', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          Text('${provider.getTotalMinutesPlayed()} min', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue)),
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

  Widget _buildAccountActions(BuildContext context, AuthProvider authProvider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          OutlinedButton.icon(
            onPressed: () => context.push('/api-test'),
            icon: const Icon(Icons.bug_report_outlined),
            label: const Text('Dev Tools: Probar API'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => context.push('/user-reviews'),
            icon: const Icon(Icons.rate_review_outlined),
            label: const Text('Mis Reseñas'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => context.push('/journal'),
            icon: const Icon(Icons.calendar_month_outlined),
            label: const Text('Mi Diario de Juego'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => context.push('/collections'),
            icon: const Icon(Icons.collections_bookmark_outlined),
            label: const Text('Mis Colecciones'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => context.push('/discovery'),
            icon: const Icon(Icons.explore_outlined),
            label: const Text('Comunidad'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () => _handleLogout(context, authProvider),
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Cerrar Sesión'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.withOpacity(0.8),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context, AuthProvider authProvider) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Cerrar sesión?'),
        content: const Text('Tu backlog se mantendrá guardado localmente.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Sí, salir')),
        ],
      ),
    );

    if (shouldLogout == true && context.mounted) {
      await authProvider.logout();
      if (context.mounted) context.go('/login');
    }
  }

  Widget _buildStatRow(
    BuildContext context,
    String label,
    int count,
    Color color, {
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              count.toString(),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'
    ];
    return '${date.day} de ${months[date.month - 1]} de ${date.year}';
  }
}