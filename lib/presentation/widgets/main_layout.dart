import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../../core/utils/image_utils.dart';
import '../../core/widgets/responsive_layout.dart';

class MainLayout extends StatefulWidget {
  final Widget child;

  const MainLayout({super.key, required this.child});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).matchedLocation;
    if (location == '/') return 0;
    if (location.startsWith('/search')) return 1;
    if (location.startsWith('/stats')) return 2; // Asumiendo que existirá una ruta /stats
    if (location.startsWith('/profile')) return 3;
    if (location.startsWith('/journal')) return 4;
    if (location.startsWith('/collections')) return 5;
    if (location.startsWith('/discovery')) return 6;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/');
        break;
      case 1:
        context.go('/search');
        break;
      case 2:
        // TODO: Crear ruta de estadísticas si no existe
        break;
      case 3:
        context.go('/profile');
        break;
      case 4:
        context.go('/journal');
        break;
      case 5:
        context.go('/collections');
        break;
      case 6:
        context.go('/discovery');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;

    return Scaffold(
      body: Row(
        children: [
          // NavigationRail persistente en Desktop
          if (ResponsiveLayout.isDesktop(context)) ...[
            NavigationRail(
              selectedIndex: _calculateSelectedIndex(context),
              onDestinationSelected: (index) => _onItemTapped(index, context),
              labelType: NavigationRailLabelType.all,
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Image.asset(
                  'assets/icons/logo_app2.png',
                  height: 40,
                  width: 40,
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
                  label: Text('Stats'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.person_outline),
                  selectedIcon: Icon(Icons.person),
                  label: Text('Perfil'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.calendar_month_outlined),
                  selectedIcon: Icon(Icons.calendar_month),
                  label: Text('Diario'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.collections_bookmark_outlined),
                  selectedIcon: Icon(Icons.collections_bookmark),
                  label: Text('Listas'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.explore_outlined),
                  selectedIcon: Icon(Icons.explore),
                  label: Text('Descubrir'),
                ),
              ],
            ),
            const VerticalDivider(thickness: 1, width: 1),
          ],
          
          // Área principal
          Expanded(
            child: Column(
              children: [
                // Top Nav bar persistente
                Container(
                  height: 70,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    border: Border(
                      bottom: BorderSide(color: Theme.of(context).dividerColor),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        'GameBacklog',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const Spacer(),
                      // Perfil en el Top Nav
                      InkWell(
                        onTap: () => context.go('/profile'),
                        borderRadius: BorderRadius.circular(30),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          child: Row(
                            children: [
                              Text(
                                user?.username ?? '',
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(width: 12),
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: Theme.of(context).colorScheme.primary,
                                backgroundImage: ImageUtils.getAvatarProvider(user?.avatarUrl),
                                child: (user?.avatarUrl == null || user!.avatarUrl!.isEmpty)
                                    ? Text(
                                        user?.username[0].toUpperCase() ?? 'U',
                                        style: const TextStyle(color: Colors.white, fontSize: 14),
                                      )
                                    : null,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Pantalla actual
                Expanded(child: widget.child),
              ],
            ),
          ),
        ],
      ),
      // Bottom Nav para móvil si fuera necesario (opcional, ya tienes Mobile views específicas)
      bottomNavigationBar: ResponsiveLayout.isMobile(context) 
        ? BottomNavigationBar(
            currentIndex: _calculateSelectedIndex(context) > 2 ? 0 : _calculateSelectedIndex(context), // Simplificado
            onTap: (index) => _onItemTapped(index, context),
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.games), label: 'Backlog'),
              BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Buscar'),
              BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'Descubrir'),
            ],
          )
        : null,
    );
  }
}
