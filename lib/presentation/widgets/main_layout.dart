import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../../core/utils/image_utils.dart';
import '../../core/widgets/responsive_layout.dart';
import '../../core/theme/app_theme.dart';

class MainLayout extends StatefulWidget {
  final Widget child;

  const MainLayout({super.key, required this.child});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> with TickerProviderStateMixin {
  late AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).matchedLocation;
    if (location == '/') return 0;
    if (location.startsWith('/search')) return 1;
    if (location.startsWith('/stats')) return 2;
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
        context.go('/stats');
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
    final selectedIndex = _calculateSelectedIndex(context);

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: Row(
        children: [
          // Sidebar en Desktop
          if (ResponsiveLayout.isDesktop(context)) ...[
            _buildSidebar(context, selectedIndex, user),
          ],

          // Área principal
          Expanded(
            child: Column(
              children: [
                // Top Nav bar
                _buildTopBar(context, user),

                // Pantalla actual con animación
                Expanded(
                  child: FadeTransition(
                    opacity: _fadeController,
                    child: widget.child,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      // Bottom Nav para móvil
      bottomNavigationBar: ResponsiveLayout.isMobile(context)
          ? _buildMobileBottomNav(context, selectedIndex)
          : null,
    );
  }

  Widget _buildSidebar(BuildContext context, int selectedIndex, dynamic user) {
    final navItems = [
      _NavItem(Icons.games_outlined, Icons.games, 'Backlog'),
      _NavItem(Icons.search_rounded, Icons.search_rounded, 'Buscar'),
      _NavItem(Icons.bar_chart_outlined, Icons.bar_chart_rounded, 'Stats'),
      _NavItem(Icons.person_outline_rounded, Icons.person_rounded, 'Perfil'),
      _NavItem(Icons.calendar_month_outlined, Icons.calendar_month, 'Diario'),
      _NavItem(Icons.collections_bookmark_outlined, Icons.collections_bookmark, 'Listas'),
      _NavItem(Icons.explore_outlined, Icons.explore, 'Descubrir'),
    ];

    return Container(
      width: 82,
      decoration: const BoxDecoration(
        color: AppColors.sidebarBg,
        border: Border(
          right: BorderSide(color: Color(0xFF1E1E3A), width: 1),
        ),
      ),
      child: Column(
        children: [
          // Logo
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: AppColors.primaryGradient,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accentCyan.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.asset(
                  'assets/icons/logo_app2.png',
                  height: 44,
                  width: 44,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Nav Items
          Expanded(
            child: ListView.builder(
              itemCount: navItems.length,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemBuilder: (context, index) {
                final item = navItems[index];
                final isSelected = selectedIndex == index;
                return _buildNavItem(
                  context,
                  icon: isSelected ? item.selectedIcon : item.icon,
                  label: item.label,
                  isSelected: isSelected,
                  onTap: () => _onItemTapped(index, context),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          splashColor: AppColors.accentCyan.withOpacity(0.1),
          highlightColor: AppColors.accentCyan.withOpacity(0.05),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: isSelected ? AppColors.accentCyan.withOpacity(0.12) : Colors.transparent,
              border: isSelected
                  ? Border.all(color: AppColors.accentCyan.withOpacity(0.25), width: 1)
                  : null,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    icon,
                    size: isSelected ? 26 : 22,
                    color: isSelected ? AppColors.accentCyan : AppColors.sidebarUnselected,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected ? AppColors.accentCyan : AppColors.sidebarUnselected,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, dynamic user) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: AppColors.bgDark.withOpacity(0.95),
        border: const Border(
          bottom: BorderSide(color: Color(0xFF1E1E3A), width: 1),
        ),
      ),
      child: Row(
        children: [
          // Título con gradiente
          ShaderMask(
            shaderCallback: (bounds) => AppColors.primaryGradient.createShader(bounds),
            child: Text(
              'GameBacklog',
              style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const Spacer(),
          // Perfil
          if (user != null)
            InkWell(
              onTap: () => context.go('/profile'),
              borderRadius: BorderRadius.circular(30),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    Text(
                      user.username ?? '',
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppColors.primaryGradient,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accentCyan.withOpacity(0.3),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.transparent,
                        backgroundImage: ImageUtils.getAvatarProvider(user?.avatarUrl),
                        child: (user?.avatarUrl == null || user!.avatarUrl!.isEmpty)
                            ? Text(
                                user?.username[0].toUpperCase() ?? 'U',
                                style: const TextStyle(
                                  color: AppColors.bgDark,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMobileBottomNav(BuildContext context, int selectedIndex) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bgCard,
        border: Border(
          top: BorderSide(color: Color(0xFF1E1E3A), width: 1),
        ),
      ),
      child: BottomNavigationBar(
        currentIndex: selectedIndex > 2 ? 0 : selectedIndex,
        onTap: (index) => _onItemTapped(index, context),
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: AppColors.accentCyan,
        unselectedItemColor: AppColors.sidebarUnselected,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.games), label: 'Backlog'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Buscar'),
          BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'Descubrir'),
        ],
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  _NavItem(this.icon, this.selectedIcon, this.label);
}
