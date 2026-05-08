import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:game_backlog/domain/entities/game.dart';
import 'package:game_backlog/data/datasources/game_remote_datasource.dart';
import 'package:game_backlog/presentation/providers/backlog_provider.dart';
import 'package:game_backlog/presentation/providers/community_provider.dart';
import 'package:game_backlog/presentation/screens/backlog/widgets/edit_game_dialog.dart';
import 'package:game_backlog/presentation/screens/backlog/widgets/review_dialog.dart';
import 'package:game_backlog/presentation/widgets/session_dialog.dart';
import 'package:game_backlog/domain/entities/game_backlog_entry.dart';
import 'package:game_backlog/domain/entities/game_session.dart';
import 'package:game_backlog/domain/entities/community_review.dart';
import 'package:game_backlog/domain/entities/user_review.dart';
import 'package:game_backlog/core/theme/app_theme.dart';

class GameDetailScreen extends StatefulWidget {
  final String gameId;
  final Game? gameHelper; 

  const GameDetailScreen({
    super.key,
    required this.gameId,
    this.gameHelper,
  });

  @override
  State<GameDetailScreen> createState() => _GameDetailScreenState();
}

class _GameDetailScreenState extends State<GameDetailScreen> {
  late Game _game;
  bool _isLoading = true;
  bool _isDescriptionExpanded = false;
  Map<String, dynamic>? _apiDetails;
  List<String> _platforms = [];
  List<String> _genres = [];
  String? _developer;
  final _remoteDataSource = GameRemoteDataSource();
  final ScrollController _galleryController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadGame();
  }

  @override
  void dispose() {
    _galleryController.dispose();
    super.dispose();
  }

  void _loadGame() {
    final backlogProvider = context.read<BacklogProvider>();
    final localGame = backlogProvider.gamesMap[widget.gameId];

    if (localGame != null) {
      _game = localGame;
      _isLoading = false;
      _loadRemoteDetails();
    } else if (widget.gameHelper != null) {
      _game = widget.gameHelper!;
      _isLoading = false;
      _loadRemoteDetails();
    } else {
      _isLoading = false;
    }
  }

  Future<void> _loadRemoteDetails() async {
    try {
      Map<String, dynamic>? details;
      if (_game.remoteId != null) {
        details = await _remoteDataSource.getGameDetails(_game.remoteId!);
      }
      if (details == null) {
        final results = await _remoteDataSource.searchGamesRaw(_game.title);
        if (results.isNotEmpty) details = results.first;
      }

      if (mounted && details != null) {
        setState(() {
          _apiDetails = details;
          if (details!['platforms'] != null) {
            _platforms = (details['platforms'] as List).map((p) => p['name'] as String).toList();
          }
          final List<String> allTags = [];
          if (details['genres'] != null) {
            allTags.addAll((details['genres'] as List).map((g) => g['name'] as String));
          }
          if (details['themes'] != null) {
            allTags.addAll((details['themes'] as List).map((t) => t['name'] as String));
          }
          _genres = allTags.toSet().toList();

          if (details['involved_companies'] != null) {
            final companies = details['involved_companies'] as List;
            final dev = companies.firstWhere((c) => c['developer'] == true, orElse: () => null);
            if (dev != null) _developer = dev['company']['name'];
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading IGDB details: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.bgDark,
        body: Center(child: CircularProgressIndicator(color: AppColors.accentCyan)),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatsRow(),
                  const SizedBox(height: 32),
                  _buildGenresSection(),
                  const SizedBox(height: 32),
                  _buildDescriptionSection(),
                  const SizedBox(height: 32),
                  _buildMediaGallery(),
                  const SizedBox(height: 32),
                  _buildUserBacklogSections(),
                  const SizedBox(height: 32),
                  _buildCommunityReviewsSection(),
                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: _buildActionButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildSliverAppBar() {
    final coverUrl = _game.coverUrl?.replaceAll('t_cover_big', 't_720p').replaceAll('t_thumb', 't_720p');

    return SliverAppBar(
      expandedHeight: 480.0,
      pinned: true,
      stretch: true,
      backgroundColor: AppColors.bgDark,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: _buildBlurButton(
          icon: Icons.arrow_back_rounded,
          onPressed: () => context.pop(),
        ),
      ),
      actions: [
        Consumer<BacklogProvider>(
          builder: (context, provider, _) {
            final entry = provider.backlogEntries.where((e) => e.gameId == widget.gameId).isNotEmpty
                ? provider.backlogEntries.firstWhere((e) => e.gameId == widget.gameId)
                : null;
            
            return Row(
              children: [
                if (entry != null) ...[
                  _buildBlurButton(
                    icon: Icons.playlist_add_rounded,
                    tooltip: 'Añadir a colección',
                    onPressed: () => _showAddToListSheet(context, provider),
                  ),
                  const SizedBox(width: 8),
                  _buildBlurButton(
                    icon: entry.isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    color: entry.isFavorite ? AppColors.accentRose : Colors.white,
                    onPressed: () => provider.toggleFavorite(entry.id),
                  ),
                ],
                const SizedBox(width: 16),
              ],
            );
          },
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground, StretchMode.blurBackground],
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (coverUrl != null)
              CachedNetworkImage(imageUrl: coverUrl, fit: BoxFit.cover),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black.withOpacity(0.2), AppColors.bgDark.withOpacity(0.8), AppColors.bgDark],
                  stops: const [0.0, 0.7, 1.0],
                ),
              ),
            ),
            Positioned(
              bottom: 24,
              left: 24,
              right: 24,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Hero(
                    tag: 'game_cover_${_game.id}',
                    child: Container(
                      width: 140, height: 200,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20, offset: const Offset(0, 10))],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: coverUrl != null
                            ? CachedNetworkImage(imageUrl: coverUrl, fit: BoxFit.cover)
                            : Container(color: AppColors.bgSurface, child: const Icon(Icons.videogame_asset, size: 50)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_developer != null)
                          Text(_developer!.toUpperCase(), style: GoogleFonts.inter(color: AppColors.accentCyan, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                        Text(_game.title, style: GoogleFonts.outfit(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800, height: 1.1)),
                        const SizedBox(height: 12),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              if (_game.releaseDate != null)
                                _buildConsistentChip('${_game.releaseDate!.year}'),
                              const SizedBox(width: 8),
                              ..._platforms.map((p) => Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: _buildConsistentChip(p),
                              )).toList(),
                            ],
                          ),
                        ),
                      ],
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

  Widget _buildConsistentChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.accentTeal.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.accentTeal.withOpacity(0.2)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.accentTeal,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildGenresSection() {
    if (_genres.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Géneros y Temas', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _genres.map((g) => _buildConsistentChip(g)).toList(),
        ),
      ],
    );
  }

  Widget _buildBlurButton({required IconData icon, required VoidCallback onPressed, Color color = Colors.white, String? tooltip}) {
    return Tooltip(
      message: tooltip ?? '',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: IconButton(icon: Icon(icon, color: color, size: 22), onPressed: onPressed),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    final apiRating = _apiDetails != null && _apiDetails!['total_rating'] != null 
        ? (_apiDetails!['total_rating'] as num).toStringAsFixed(1) 
        : 'N/A';

    return Consumer<BacklogProvider>(
      builder: (context, provider, _) {
        final entry = provider.backlogEntries.where((e) => e.gameId == widget.gameId).isNotEmpty
            ? provider.backlogEntries.firstWhere((e) => e.gameId == widget.gameId)
            : null;

        return Row(
          children: [
            _buildStatItem('IGDB Score', apiRating, Icons.auto_awesome_rounded, AppColors.accentAmber),
            const SizedBox(width: 12),
            _buildStatItem('Mi Nota', entry?.rating?.toString() ?? '-', Icons.star_rounded, AppColors.accentPurple),
            const SizedBox(width: 12),
            _buildStatItem('Tiempo', '${entry?.hoursPlayed ?? 0}h', Icons.timer_rounded, AppColors.accentCyan),
          ],
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(color: AppColors.bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withOpacity(0.1))),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Text(value, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            Text(label, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }

  Widget _buildDescriptionSection() {
    final description = _apiDetails?['summary'] ?? _game.description ?? 'Sin descripción.';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Acerca del juego', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        const SizedBox(height: 12),
        InkWell(
          onTap: () => setState(() => _isDescriptionExpanded = !_isDescriptionExpanded),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(description, style: GoogleFonts.inter(fontSize: 15, color: AppColors.textSecondary, height: 1.6), maxLines: _isDescriptionExpanded ? null : 4, overflow: _isDescriptionExpanded ? TextOverflow.visible : TextOverflow.ellipsis),
              const SizedBox(height: 8),
              Row(children: [Text(_isDescriptionExpanded ? 'Mostrar menos' : 'Leer más', style: const TextStyle(color: AppColors.accentCyan, fontSize: 13, fontWeight: FontWeight.bold)), Icon(_isDescriptionExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: AppColors.accentCyan, size: 16)]),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMediaGallery() {
    List screenshots = [];
    if (_apiDetails != null) {
      if (_apiDetails!['screenshots'] != null) screenshots.addAll(_apiDetails!['screenshots'] as List);
      if (_apiDetails!['artworks'] != null) screenshots.addAll(_apiDetails!['artworks'] as List);
    }
    
    if (screenshots.isEmpty) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Galería', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            Row(
              children: [
                _buildGalleryArrow(Icons.chevron_left, () {
                  _galleryController.animateTo(_galleryController.offset - 300, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                }),
                const SizedBox(width: 8),
                _buildGalleryArrow(Icons.chevron_right, () {
                  _galleryController.animateTo(_galleryController.offset + 300, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                }),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 160,
          child: ListView.builder(
            controller: _galleryController,
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: screenshots.length,
            itemBuilder: (context, index) {
              final url = (screenshots[index]['url'] as String).replaceAll('t_thumb', 't_720p');
              return GestureDetector(
                onTap: () => _showImageGallery(screenshots, index),
                child: Container(
                  margin: const EdgeInsets.only(right: 12),
                  width: 280,
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white10)),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(imageUrl: 'https:$url', fit: BoxFit.cover, placeholder: (context, url) => Container(color: AppColors.bgSurface)),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildGalleryArrow(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: AppColors.accentCyan, size: 24)),
    );
  }

  void _showImageGallery(List screenshots, int initialIndex) {
    showDialog(
      context: context,
      builder: (context) => Stack(
        children: [
          PageView.builder(
            controller: PageController(initialPage: initialIndex),
            itemCount: screenshots.length,
            itemBuilder: (context, index) {
              final url = (screenshots[index]['url'] as String).replaceAll('t_thumb', 't_1080p');
              return InteractiveViewer(child: CachedNetworkImage(imageUrl: 'https:$url', fit: BoxFit.contain));
            },
          ),
          Positioned(top: 40, right: 20, child: _buildBlurButton(icon: Icons.close, onPressed: () => Navigator.pop(context))),
        ],
      ),
    );
  }

  Widget _buildUserBacklogSections() {
    return Consumer<BacklogProvider>(
      builder: (context, provider, _) {
        final entry = provider.backlogEntries.where((e) => e.gameId == widget.gameId).isNotEmpty
            ? provider.backlogEntries.firstWhere((e) => e.gameId == widget.gameId)
            : null;

        if (entry == null) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTimelineSection(entry),
            const SizedBox(height: 32),
            _buildMultiReviewSection(context, provider),
            const SizedBox(height: 32),
            _buildSessionsSection(context, entry, provider),
          ],
        );
      },
    );
  }

  Widget _buildTimelineSection(GameBacklogEntry entry) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Línea de Tiempo', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppColors.bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white10)),
          child: Column(
            children: [
              _buildTimelineRow(Icons.play_arrow_rounded, 'Empezado', entry.startDate, AppColors.statusPlaying, () => _selectDate(entry, true)),
              const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(color: Colors.white10, indent: 32)),
              _buildTimelineRow(Icons.flag_rounded, 'Finalizado', entry.endDate, AppColors.statusCompleted, () => _selectDate(entry, false)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineRow(IconData icon, String label, DateTime? date, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, color: color, size: 18)),
          const SizedBox(width: 16),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
            Text(date != null ? '${date.day}/${date.month}/${date.year}' : 'Pendiente', style: TextStyle(color: date != null ? Colors.white : Colors.white24, fontWeight: FontWeight.bold)),
          ]),
          const Spacer(),
          const Icon(Icons.edit_calendar_rounded, color: Colors.white24, size: 16),
        ],
      ),
    );
  }

  Widget _buildMultiReviewSection(BuildContext context, BacklogProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Tus Reseñas', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            TextButton.icon(
              onPressed: () => _showAddReviewDialog(context, provider), 
              icon: const Icon(Icons.add_comment_rounded, size: 16), 
              label: const Text('Añadir Reseña')
            ),
          ],
        ),
        const SizedBox(height: 12),
        FutureBuilder<List<UserReview>>(
          future: provider.getUserReviewsForGame(widget.gameId),
          builder: (context, snapshot) {
            final reviews = snapshot.data ?? [];
            if (reviews.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: AppColors.bgCard, borderRadius: BorderRadius.circular(16)),
                child: const Text('No has escrito ninguna reseña todavía.', style: TextStyle(color: AppColors.textMuted, fontStyle: FontStyle.italic)),
              );
            }

            return Column(
              children: reviews.map((review) => InkWell(
                onTap: () => _showAddReviewDialog(context, provider, existing: review),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: AppColors.bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white10)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (review.title != null) Expanded(child: Text(review.title!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.accentRose, size: 18),
                            onPressed: () => _confirmDeleteReview(context, provider, review.id),
                          ),
                        ],
                      ),
                      if (review.isSpoiler) Container(margin: const EdgeInsets.symmetric(vertical: 8), padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: AppColors.accentRose.withOpacity(0.1), borderRadius: BorderRadius.circular(4)), child: const Text('SPOILERS', style: TextStyle(color: AppColors.accentRose, fontSize: 10, fontWeight: FontWeight.bold))),
                      Text(review.content ?? '', style: const TextStyle(color: AppColors.textSecondary)),
                      const SizedBox(height: 8),
                      Text('${review.createdAt.day}/${review.createdAt.month}/${review.createdAt.year}', style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
                    ],
                  ),
                ),
              )).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSessionsSection(BuildContext context, GameBacklogEntry entry, BacklogProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Sesiones de Juego', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            TextButton.icon(onPressed: () => _showAddSessionDialog(context, entry.gameId), icon: const Icon(Icons.add_rounded, size: 16), label: const Text('Registrar')),
          ],
        ),
        const SizedBox(height: 12),
        FutureBuilder<List<GameSession>>(
          future: provider.getSessionsForGame(entry.gameId),
          builder: (context, snapshot) {
            final sessions = snapshot.data ?? [];
            if (sessions.isEmpty) return Container(padding: const EdgeInsets.all(16), width: double.infinity, decoration: BoxDecoration(color: AppColors.bgCard, borderRadius: BorderRadius.circular(16)), child: const Center(child: Text('Sin sesiones registradas', style: TextStyle(color: AppColors.textMuted))));
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: sessions.length.clamp(0, 3),
              itemBuilder: (context, index) {
                final s = sessions[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppColors.bgCard, borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      const Icon(Icons.history_toggle_off_rounded, color: AppColors.accentCyan, size: 16),
                      const SizedBox(width: 12),
                      Text('${s.sessionDate.day}/${s.sessionDate.month}', style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
                      const Spacer(),
                      Text('${s.durationMinutes} min', style: const TextStyle(color: AppColors.textSecondary)),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildCommunityReviewsSection() {
    final communityProvider = context.read<CommunityProvider>();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Reseñas de la Comunidad', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        const SizedBox(height: 16),
        FutureBuilder<List<CommunityReview>>(
          future: communityProvider.getReviewsForGame(widget.gameId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: AppColors.accentCyan));
            }
            
            final reviews = snapshot.data ?? [];
            if (reviews.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(24),
                width: double.infinity,
                decoration: BoxDecoration(color: AppColors.bgCard, borderRadius: BorderRadius.circular(16)),
                child: const Center(child: Text('Nadie ha escrito una reseña todavía.', style: TextStyle(color: AppColors.textMuted))),
              );
            }

            final displayReviews = reviews.take(4).toList();

            return Column(
              children: [
                ...displayReviews.map((review) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: AppColors.bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withOpacity(0.05))),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(radius: 12, backgroundColor: AppColors.accentTeal.withOpacity(0.2), child: Text(review.username[0].toUpperCase(), style: const TextStyle(fontSize: 10, color: AppColors.accentTeal))),
                          const SizedBox(width: 8),
                          Text(review.username, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
                          const Spacer(),
                          if (review.rating != null && review.rating! > 0)
                            Row(children: [const Icon(Icons.star_rounded, color: AppColors.accentAmber, size: 14), const SizedBox(width: 4), Text('${review.rating}', style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13))]),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (review.reviewTitle != null) Text(review.reviewTitle!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                      Text(review.notes ?? '', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13), maxLines: 3, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                )),
                if (reviews.length > 4)
                  TextButton(onPressed: () => context.push('/discovery'), child: const Text('Ver todas las reseñas')),
              ],
            );
          },
        ),
      ],
    );
  }

  void _showAddToListSheet(BuildContext context, BacklogProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgDark,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Añadir a colección', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                TextButton.icon(
                  onPressed: () => _showCreateListDialog(context, provider), 
                  icon: const Icon(Icons.add_box_rounded, size: 18), 
                  label: const Text('Nueva Colección')
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                shrinkWrap: true,
                children: provider.gameLists.map((list) => ListTile(
                  leading: const Icon(Icons.collections_bookmark_rounded, color: AppColors.accentCyan),
                  title: Text(list.name, style: const TextStyle(color: AppColors.textPrimary)),
                  onTap: () async {
                    final ok = await provider.addGameToList(list.id, widget.gameId);
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? 'Añadido a ${list.name}' : 'Ya está en esta lista')));
                    }
                  },
                )).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateListDialog(BuildContext context, BacklogProvider provider) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        title: const Text('Nueva Colección', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Nombre de la colección',
            hintStyle: TextStyle(color: Colors.white24),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.accentCyan)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          TextButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                await provider.createGameList(name: controller.text);
                if (context.mounted) Navigator.pop(context);
              }
            }, 
            child: const Text('Crear', style: TextStyle(color: AppColors.accentCyan))
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton() {
    return Consumer<BacklogProvider>(
      builder: (context, provider, _) {
        final entry = provider.backlogEntries.where((e) => e.gameId == widget.gameId).isNotEmpty ? provider.backlogEntries.firstWhere((e) => e.gameId == widget.gameId) : null;
        return Container(
          width: 220,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(30), gradient: entry != null ? AppColors.primaryGradient : AppColors.accentGradient, boxShadow: [BoxShadow(color: (entry != null ? AppColors.accentCyan : AppColors.accentPurple).withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 8))]),
          child: FloatingActionButton.extended(onPressed: () => entry != null ? _showEditDialog(context, entry, provider) : _addToBacklog(context, provider), backgroundColor: Colors.transparent, elevation: 0, icon: Icon(entry != null ? Icons.edit_rounded : Icons.add_rounded, color: entry != null ? AppColors.bgDark : Colors.white), label: Text(entry != null ? 'GESTIONAR' : 'AÑADIR', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: entry != null ? AppColors.bgDark : Colors.white, letterSpacing: 1.2))),
        );
      },
    );
  }

  void _showEditDialog(BuildContext context, GameBacklogEntry entry, BacklogProvider provider) {
    showDialog(context: context, builder: (context) => EditGameDialog(entry: entry, game: _game, onUpdate: ({status, hoursPlayed, rating, notes}) async => await provider.updateGameEntry(entryId: entry.id, status: status, hoursPlayed: hoursPlayed, rating: rating, notes: notes)));
  }

  void _showAddReviewDialog(BuildContext context, BacklogProvider provider, {UserReview? existing}) {
    showDialog(
      context: context, 
      builder: (context) => ReviewDialog(
        entryId: widget.gameId,
        reviewId: existing?.id,
        initialTitle: existing?.title,
        initialContent: existing?.content,
        initialIsSpoiler: existing?.isSpoiler ?? false,
        onReviewSubmit: (title, content, isSpoiler) async {
          if (existing == null) {
            await provider.addUserReview(
              gameId: widget.gameId,
              title: title,
              content: content,
              isSpoiler: isSpoiler,
            );
          } else {
            await provider.updateUserReview(
              reviewId: existing.id,
              title: title,
              content: content,
              isSpoiler: isSpoiler,
            );
          }
          setState(() {}); 
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(existing == null ? 'Reseña añadida' : 'Reseña actualizada'), backgroundColor: AppColors.accentTeal),
            );
          }
        },
      ),
    );
  }

  void _confirmDeleteReview(BuildContext context, BacklogProvider provider, String reviewId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        title: const Text('¿Eliminar reseña?', style: TextStyle(color: Colors.white)),
        content: const Text('Esta acción no se puede deshacer.', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          TextButton(
            onPressed: () async {
              await provider.deleteUserReview(reviewId);
              if (context.mounted) Navigator.pop(context);
              setState(() {});
            }, 
            child: const Text('Eliminar', style: TextStyle(color: AppColors.accentRose))
          ),
        ],
      ),
    );
  }

  void _showAddSessionDialog(BuildContext context, String gameId) {
    showDialog(context: context, builder: (context) => SessionDialog(gameId: gameId));
  }

  Future<void> _selectDate(GameBacklogEntry entry, bool isStart) async {
    final picked = await showDatePicker(context: context, initialDate: (isStart ? entry.startDate : entry.endDate) ?? DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime.now().add(const Duration(days: 365)));
    if (picked != null) {
      final p = context.read<BacklogProvider>();
      isStart ? await p.setStartDate(entry.id, picked) : await p.setEndDate(entry.id, picked);
      setState(() {});
    }
  }

  Future<void> _addToBacklog(BuildContext context, BacklogProvider provider) async {
    final success = await provider.addGameFromSearch(_game);
    if (success && mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${_game.title} añadido'), backgroundColor: AppColors.accentTeal));
  }
}