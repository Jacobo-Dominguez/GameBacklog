import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';

class BacklogDesktopView extends StatefulWidget {
  const BacklogDesktopView({super.key});

  @override
  State<BacklogDesktopView> createState() => _BacklogDesktopViewState();
}

class _BacklogDesktopViewState extends State<BacklogDesktopView> {
  int _selectedIndex = 0;

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
              if (index == 3) {
                // Perfil
                context.go('/profile');
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
                  Icon(
                    Icons.games,
                    size: 32,
                    color: Theme.of(context).colorScheme.primary,
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
                selectedIcon: Icon(Icons.person),
                label: Text('Perfil'),
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
                      // Usuario
                      Row(
                        children: [
                          Text(
                            user?.username ?? '',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          const SizedBox(width: 12),
                          CircleAvatar(
                            radius: 20,
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                            child: Text(
                              user?.username[0].toUpperCase() ?? 'U',
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
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
              onPressed: () {
                // TODO: Abrir diálogo para agregar juego (Fase 6)
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Función disponible en Fase 6'),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Agregar Juego'),
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
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
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
            ),
            const SizedBox(height: 32),
            Card(
              margin: const EdgeInsets.all(24),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Text(
                      '🎮 Funcionalidades próximamente',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),
                    const Wrap(
                      spacing: 16,
                      runSpacing: 8,
                      children: [
                        Chip(label: Text('Agregar juegos')),
                        Chip(label: Text('Filtrar por estado')),
                        Chip(label: Text('Buscar juegos')),
                        Chip(label: Text('Ver estadísticas')),
                        Chip(label: Text('Editar horas jugadas')),
                        Chip(label: Text('Calificar juegos')),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search,
            size: 120,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 24),
          Text(
            'Búsqueda de juegos',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 12),
          Text(
            'Esta función estará disponible en la Fase 6',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bar_chart,
            size: 120,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 24),
          Text(
            'Estadísticas detalladas',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 12),
          Text(
            'Esta función estará disponible en la Fase 6',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.go('/profile'),
            icon: const Icon(Icons.person),
            label: const Text('Ver estadísticas básicas en tu perfil'),
          ),
        ],
      ),
    );
  }
}
