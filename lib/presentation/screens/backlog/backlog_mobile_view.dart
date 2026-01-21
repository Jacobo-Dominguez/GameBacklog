import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';

class BacklogMobileView extends StatefulWidget {
  const BacklogMobileView({super.key});

  @override
  State<BacklogMobileView> createState() => _BacklogMobileViewState();
}

class _BacklogMobileViewState extends State<BacklogMobileView> {
  int _selectedIndex = 0;

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
              onPressed: () {
                // TODO: Abrir diálogo para agregar juego (Fase 6)
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Función disponible en Fase 6'),
                  ),
                );
              },
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
            'Tu backlog está vacío',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Agrega juegos usando el botón +',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          const Card(
            margin: EdgeInsets.all(24),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    '🎮 Próximamente',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text('• Agregar juegos al backlog'),
                  Text('• Filtrar por estado'),
                  Text('• Buscar juegos'),
                  Text('• Ver estadísticas'),
                  Text('• Editar horas jugadas'),
                ],
              ),
            ),
          ),
        ],
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
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Búsqueda de juegos',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Disponible en Fase 6',
            style: TextStyle(color: Colors.grey[600]),
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
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Estadísticas',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Disponible en Fase 6',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => context.go('/profile'),
            child: const Text('Ver estadísticas en tu perfil'),
          ),
        ],
      ),
    );
  }
}
