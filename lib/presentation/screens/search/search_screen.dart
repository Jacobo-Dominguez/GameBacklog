import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';
import '../../providers/backlog_provider.dart';
import '../../../data/datasources/game_remote_datasource.dart';
import '../../../domain/entities/game_search_result.dart';
import '../../../data/services/game_search_service.dart';
import '../../../core/theme/app_theme.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> with SingleTickerProviderStateMixin {
  final _controller = TextEditingController();
  final _service = GameRemoteDataSource();
  final _searchService = GameSearchService();
  List<GameSearchResult> _results = [];
  bool _loading = false;

  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) return;
    
    setState(() => _loading = true);
    try {
      final results = await _service.searchGames(query.trim());
      if (mounted) {
        setState(() => _results = results);
        _animController.forward(from: 0);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al buscar: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _addGameToBacklog(GameSearchResult gameResult) async {
    final authProvider = context.read<AuthProvider>();
    final backlogProvider = context.read<BacklogProvider?>();
    
    if (authProvider.currentUser == null || backlogProvider == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: usuario no autenticado')),
        );
      }
      return;
    }

    try {
      final releaseDate = gameResult.released != null 
          ? DateTime.tryParse(gameResult.released!)
          : null;
      
      final igdbMap = <String, dynamic>{
        'id': gameResult.id,
        'name': gameResult.name,
        'summary': gameResult.description,
        'genres': gameResult.genres.map((g) => {'name': g}).toList(),
        'platforms': gameResult.platforms.map((p) => {'name': p}).toList(),
      };

      if (gameResult.backgroundImage != null) {
        igdbMap['cover'] = {
          'url': gameResult.backgroundImage!.replaceAll('https:', '')
        };
      }

      if (releaseDate != null) {
        igdbMap['first_release_date'] = releaseDate.millisecondsSinceEpoch ~/ 1000;
      }

      final game = _searchService.fromIgdbResult(igdbMap, authProvider.currentUser!.id);
      final success = await backlogProvider.addGameFromSearch(game);
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: AppColors.accentTeal, size: 20),
                const SizedBox(width: 10),
                Text('${game.title} agregado al backlog'),
              ],
            ),
            backgroundColor: AppColors.bgElevated,
          ),
        );
        setState(() {
          _results = [];
          _controller.clear();
        });
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.info_outline, color: AppColors.accentAmber, size: 20),
                const SizedBox(width: 10),
                const Text('Ya existe en tu backlog'),
              ],
            ),
            backgroundColor: AppColors.bgElevated,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: Column(
        children: [
          // Search bar
          Container(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: AppColors.bgCard,
                border: Border.all(color: const Color(0xFF2A2A4A)),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accentCyan.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                controller: _controller,
                style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'Buscar juegos en IGDB...',
                  hintStyle: GoogleFonts.inter(color: AppColors.textMuted),
                  prefixIcon: const Icon(Icons.search_rounded, color: AppColors.accentCyan),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  suffixIcon: _controller.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, color: AppColors.textMuted, size: 20),
                          onPressed: () {
                            setState(() {
                              _controller.clear();
                              _results = [];
                            });
                          },
                        )
                      : null,
                ),
                onSubmitted: _search,
                onChanged: (val) => setState(() {}),
                autofocus: true,
              ),
            ),
          ),
          
          // Results
          Expanded(
            child: _loading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 40,
                          height: 40,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: AppColors.accentCyan,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Buscando...',
                          style: GoogleFonts.inter(color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  )
                : _results.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _controller.text.isEmpty
                                    ? Icons.search_rounded
                                    : Icons.search_off_rounded,
                                size: 64,
                                color: AppColors.textMuted.withOpacity(0.5),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _controller.text.isEmpty
                                    ? 'Escribe para buscar juegos en IGDB...'
                                    : 'No se encontraron resultados para "${_controller.text}"',
                                style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 15),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _results.length,
                        itemBuilder: (context, index) {
                          final game = _results[index];
                          return _buildSearchResultCard(game, index);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResultCard(GameSearchResult game, int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (index * 50)),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF2A2A4A)),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () {},
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // Cover
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: SizedBox(
                      width: 60,
                      height: 80,
                      child: game.backgroundImage != null
                          ? Image.network(
                              game.backgroundImage!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                    color: AppColors.bgSurface,
                                    child: const Icon(Icons.videogame_asset_rounded, color: AppColors.textMuted),
                                  ),
                            )
                          : Container(
                              color: AppColors.bgSurface,
                              child: const Icon(Icons.videogame_asset_rounded, color: AppColors.textMuted),
                            ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          game.name,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        if (game.released != null)
                          Text(
                            'Lanzado: ${DateTime.tryParse(game.released!)?.year ?? '?'}',
                            style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted),
                          ),
                        if (game.genres.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Wrap(
                              spacing: 6,
                              children: game.genres.take(3).map((genre) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.accentPurple.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: AppColors.accentPurple.withOpacity(0.2)),
                                  ),
                                  child: Text(
                                    genre,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.accentPurple.withOpacity(0.8),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Add button
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
                    child: IconButton(
                      icon: const Icon(Icons.add_rounded, color: AppColors.bgDark, size: 22),
                      onPressed: () => _addGameToBacklog(game),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}