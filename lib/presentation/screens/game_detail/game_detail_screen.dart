import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../domain/entities/game.dart';
import '../../../data/datasources/game_remote_datasource.dart';
import '../../providers/backlog_provider.dart';
import '../backlog/widgets/edit_game_dialog.dart';
import '../backlog/widgets/review_dialog.dart'; // ✅ Nuevo
import '../../../domain/entities/game_backlog_entry.dart';
import '../../../domain/entities/game_session.dart';
import '../../../domain/entities/game_list.dart';
import '../../../domain/entities/community_review.dart'; // ✅ Nuevo
import '../../providers/community_provider.dart'; // ✅ Nuevo
import '../../widgets/spoiler_text_widget.dart'; // ✅ Nuevo

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
  
  // Datos remotos de IGDB
  Map<String, dynamic>? _apiDetails;
  String? _remotePlatform;
  
  // Comunidad
  List<CommunityReview> _communityReviews = [];
  bool _isLoadingCommunity = true;

  final _remoteDataSource = GameRemoteDataSource();

  @override
  void initState() {
    super.initState();
    _loadGame();
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
    
    _loadCommunityReviews();
  }

  Future<void> _loadCommunityReviews() async {
    if (!mounted) return;
    
    final communityProvider = context.read<CommunityProvider?>();
    if (communityProvider != null) {
      try {
        final reviews = await communityProvider.getReviewsForGame(widget.gameId);
        if (mounted) {
          setState(() {
            _communityReviews = reviews;
            _isLoadingCommunity = false;
          });
        }
      } catch (e) {
        debugPrint('Error loading community reviews: $e');
        if (mounted) {
          setState(() => _isLoadingCommunity = false);
        }
      }
    } else {
      setState(() => _isLoadingCommunity = false);
    }
  }

  Future<void> _loadRemoteDetails() async {
    // Intentamos cargar datos frescos de IGDB
    // Si tenemos ID remoto, usamos getGameDetails (más preciso)
    // Si no, buscamos por nombre (fallback)
    if (_apiDetails == null) {
      try {
        Map<String, dynamic>? details;

        if (_game.remoteId != null) {
             details = await _remoteDataSource.getGameDetails(_game.remoteId!);
        }
        
        // Fallback: buscar por título si falló el ID o no tenía
        if (details == null) {
            final results = await _remoteDataSource.searchGamesRaw(_game.title);
            if (results.isNotEmpty) {
                details = results.first;
            }
        }

        if (mounted && details != null) {
          setState(() {
            _apiDetails = details;
            
            // Actualizar plataforma si tenemos datos nuevos
            if (details!['platforms'] != null) {
                final platforms = details['platforms'] as List;
                if (platforms.isNotEmpty) {
                    _remotePlatform = platforms.map((p) => p['name'] as String).join(', ');
                }
            }
          });
        }
      } catch (e) {
        debugPrint('Error loading details from IGDB: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDescriptionSection(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Consumer<BacklogProvider>(
        builder: (context, provider, child) {
          final entry = provider.backlogEntries.where((e) => e.gameId == widget.gameId).isNotEmpty
              ? provider.backlogEntries.firstWhere((e) => e.gameId == widget.gameId)
              : null;
          
          if (entry != null) {
              return FloatingActionButton.extended(
                onPressed: () => _showEditDialog(context, entry, provider),
                icon: const Icon(Icons.edit, color: Colors.white),
                label: const Text('Gestionar', style: TextStyle(color: Colors.white)),
                backgroundColor: Theme.of(context).colorScheme.primary,
              );
          } else {
              return FloatingActionButton.extended(
                onPressed: () => _addToBacklog(context, provider),
                icon: const Icon(Icons.add),
                label: const Text('Agregar'),
                backgroundColor: Colors.green,
              );
          }
        },
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 420.0,
      pinned: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      leading: Center(
        child: _buildCircularButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      actions: [
        // ✅ Botón de Favorito
        Consumer<BacklogProvider>(
          builder: (context, provider, _) {
            final entry = provider.backlogEntries.where((e) => e.gameId == widget.gameId).isNotEmpty
                ? provider.backlogEntries.firstWhere((e) => e.gameId == widget.gameId)
                : null;
            
            if (entry == null) return const SizedBox.shrink();
            
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildCircularButton(
                  icon: Icon(
                    entry.isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: entry.isFavorite ? Colors.red : Colors.white,
                  ),
                  onPressed: () => provider.toggleFavorite(entry.id),
                ),
                const SizedBox(width: 8),
                _buildCircularButton(
                  icon: const Icon(Icons.playlist_add, color: Colors.white),
                  tooltip: 'Añadir a colección',
                  onPressed: () => _showAddToListSheet(context, provider),
                ),
                const SizedBox(width: 16),
              ],
            );
          },
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.pin,
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Fondo difuminado/oscurecido
            if (_game.coverUrl != null && _game.coverUrl!.isNotEmpty)
              Opacity(
                opacity: 0.5,
                child: CachedNetworkImage(
                  imageUrl: _game.coverUrl!.replaceAll('t_cover_big', 't_720p').replaceAll('t_thumb', 't_720p'),
                  fit: BoxFit.cover,
                ),
              ),
            
            // Gradiente para asegurar legibilidad
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black54, Colors.black],
                  stops: [0.0, 1.0],
                ),
              ),
            ),

            // Contenido Principal (Carátula + Info)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Portada como "Carta"
                  Container(
                    width: 140,
                    height: 200,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: _game.coverUrl != null && _game.coverUrl!.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: _game.coverUrl!.replaceAll('t_cover_big', 't_720p').replaceAll('t_thumb', 't_720p'),
                              fit: BoxFit.cover,
                            )
                          : Container(
                              color: Colors.grey[800],
                              child: const Icon(Icons.videogame_asset, size: 50),
                            ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  
                  // Título e Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _game.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            shadows: [Shadow(color: Colors.black, blurRadius: 8)],
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 12),
                        _buildHeaderInfo(isCompact: true),
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

  Widget _buildHeaderInfo({bool isCompact = false}) {
    List<String> platforms = [];
    if (_remotePlatform != null) {
        platforms = _remotePlatform!.split(', ');
    } else if (_game.platform != null) {
        platforms = _game.platform!.split(', ');
    }
    
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        ...platforms.map((p) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white24, width: 1),
            ),
            child: Text(
                p, 
                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500)
            ),
        )),
        if (_game.releaseDate != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.5), width: 1),
            ),
            child: Text(
                '${_game.releaseDate!.year}', 
                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)
            ),
          ),
      ],
    );
  }

  Widget _buildCircularButton({required Widget icon, required VoidCallback onPressed, String? tooltip}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: icon,
        onPressed: onPressed,
        tooltip: tooltip,
      ),
    );
  }

  Widget _buildDescriptionSection() {
      String descriptionText = 'Sin descripción disponible.';
      
      if (_apiDetails != null) {
          final summary = _apiDetails!['summary'] as String?;
          final storyline = _apiDetails!['storyline'] as String?;
          if (summary != null || storyline != null) {
              descriptionText = [summary, storyline].where((e) => e != null).join('\n\n');
          }
      } else if (_game.description != null && _game.description!.isNotEmpty) {
          descriptionText = _game.description!;
      }

      // Géneros
      List<String> genresToShow = [];
      if (_apiDetails != null && _apiDetails!['genres'] != null) {
          genresToShow = (_apiDetails!['genres'] as List).map((g) => g['name'] as String).toList();
      } else if (_game.genre != null) {
          genresToShow = _game.genre!.split(', ');
      }

      return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
              if (genresToShow.isNotEmpty) ...[
                  Text('Géneros', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white)),
                  const SizedBox(height: 12),
                  Wrap(
                      spacing: 8, 
                      runSpacing: 8,
                      children: genresToShow.take(4).map((g) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.white24, width: 1),
                          ),
                          child: Text(
                              g, 
                              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)
                          ),
                      )).toList()
                  ),
                  const SizedBox(height: 24),
              ],
              
              Text('Acerca del juego', style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white)),
              const SizedBox(height: 12),
              
              InkWell(
                  onTap: () => setState(() => _isDescriptionExpanded = !_isDescriptionExpanded),
                  child: Column(
                      children: [
                          Text(
                              descriptionText,
                              style: const TextStyle(color: Colors.white70, fontSize: 16, height: 1.5),
                              maxLines: _isDescriptionExpanded ? null : 6,
                              overflow: _isDescriptionExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Icon(
                              _isDescriptionExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                              color: Colors.blue,
                          ),
                      ],
                  ),
              ),
              
              // Estadísticas de IGDB
              if (_apiDetails != null) ...[
                  const SizedBox(height: 32),
                  _buildIgdbStats(),
                  const SizedBox(height: 24),
                  _buildMediaSection(), // Galería de screenshots
              ],

              // ✅ Nueva Sección de Reseña Personal
              const SizedBox(height: 40),
              _buildReviewSection(),
              const SizedBox(height: 40),
              _buildCommunityReviewsSection(), // ✅ Nueva Sección
              const SizedBox(height: 20),
          ],
      );
  }

  Widget _buildReviewSection() {
    return Consumer<BacklogProvider>(
      builder: (context, provider, _) {
        final entry = provider.backlogEntries.where((e) => e.gameId == widget.gameId).isNotEmpty
            ? provider.backlogEntries.firstWhere((e) => e.gameId == widget.gameId)
            : null;

        if (entry == null) return const SizedBox.shrink();

        final hasReview = (entry.reviewTitle != null && entry.reviewTitle!.isNotEmpty) || 
                         (entry.notes != null && entry.notes!.isNotEmpty);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(hasReview ? 'Tu Reseña' : 'Sin Reseña', 
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white)),
            const SizedBox(height: 12),
            Card(
              color: Colors.grey[900],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (entry.reviewTitle != null && entry.reviewTitle!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Text(
                      entry.reviewTitle!,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ),
                    if (entry.isSpoiler)
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.warning_amber_rounded, size: 16, color: Colors.orange),
                            SizedBox(width: 4),
                            Text('SPOILERS', style: TextStyle(color: Colors.orange, fontSize: 11, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    Text(
                      entry.notes?.isNotEmpty == true 
                          ? entry.notes! 
                          : 'Aún no has escrito una reseña.',
                      style: TextStyle(
                        color: entry.notes?.isNotEmpty == true ? Colors.white70 : Colors.grey,
                        fontStyle: entry.notes?.isNotEmpty == true ? null : FontStyle.italic,
                        fontSize: 15,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _showReviewDialog(context, entry),
                        icon: Icon(hasReview ? Icons.edit : Icons.add_comment),
                        label: Text(hasReview ? 'Editar Reseña' : 'Escribir Reseña'),
                        style: OutlinedButton.styleFrom(foregroundColor: Colors.blue),
                      ),
                    ),
                    _buildSessionsSection(context, entry),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCommunityReviewsSection() {
    if (_isLoadingCommunity) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_communityReviews.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Reseñas de la Comunidad', 
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white)),
          const SizedBox(height: 12),
          const Text('No hay reseñas de otros usuarios para este juego aún.', 
              style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Reseñas de la Comunidad', 
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white)),
        const SizedBox(height: 16),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _communityReviews.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final review = _communityReviews[index];
            return Card(
              color: Colors.white.withOpacity(0.05),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundImage: review.userAvatarUrl != null ? NetworkImage(review.userAvatarUrl!) : null,
                          child: review.userAvatarUrl == null ? Text(review.username[0].toUpperCase()) : null,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(review.username, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                        if (review.rating != null)
                          Row(
                            children: [
                              const Icon(Icons.star, color: Colors.amber, size: 16),
                              Text(' ${review.rating}', style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
                            ],
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (review.reviewTitle != null && review.reviewTitle!.isNotEmpty)
                      Text(review.reviewTitle!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    if (review.isSpoiler) ...[
                       const Row(
                          children: [
                            Icon(Icons.warning, color: Colors.orange, size: 14),
                            SizedBox(width: 4),
                            Text('SPOILER', style: TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        SpoilerTextWidget(text: review.notes, style: const TextStyle(color: Colors.white70)),
                    ] else
                      Text(review.notes, style: const TextStyle(color: Colors.white70)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Icon(Icons.favorite, color: review.isLikedByMe ? Colors.red : Colors.grey, size: 14),
                        const SizedBox(width: 4),
                        Text('${review.likesCount}', style: TextStyle(color: review.isLikedByMe ? Colors.red : Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSessionsSection(BuildContext context, GameBacklogEntry entry) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Sesiones de Juego',
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            TextButton.icon(
              onPressed: () => _showAddSessionDialog(context, entry.gameId),
              icon: const Icon(Icons.add, size: 20),
              label: const Text('Registrar Sesión'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        FutureBuilder<List<GameSession>>(
          future: context.read<BacklogProvider>().getSessionsForGame(entry.gameId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            
            final sessions = snapshot.data ?? [];
            if (sessions.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text(
                    'Aún no has registrado ninguna sesión.',
                    style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                  ),
                ),
              );
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: sessions.length > 3 ? 3 : sessions.length, // Mostrar últimas 3
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final session = sessions[index];
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.access_time, color: Theme.of(context).primaryColor, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${session.durationMinutes >= 60 ? '${(session.durationMinutes / 60).floor()}h ' : ''}${session.durationMinutes % 60} min - ${session.sessionDate.day}/${session.sessionDate.month}/${session.sessionDate.year}',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                            ),
                            if (session.description != null && session.description!.isNotEmpty)
                              Text(
                                session.description!,
                                style: const TextStyle(color: Colors.grey, fontSize: 12),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.more_vert, color: Colors.grey, size: 20),
                        onPressed: () => _showSessionOptions(context, session),
                      ),
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

  void _showSessionOptions(BuildContext context, GameSession session) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Editar Sesión'),
              onTap: () {
                Navigator.pop(context);
                _showEditSessionDialog(context, session);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Eliminar Sesión', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirmation(context, session);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, GameSession session) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar sesión?'),
        content: const Text('Esta acción restará el tiempo de esta sesión del total de horas jugadas.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          TextButton(
            onPressed: () async {
              final success = await context.read<BacklogProvider>().deleteGameSession(session.id);
              if (success && context.mounted) {
                Navigator.pop(context);
                setState(() {});
              }
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showEditSessionDialog(BuildContext context, GameSession session) {
    _showSessionDialog(context, gameId: session.gameId, existingSession: session);
  }

  void _showAddSessionDialog(BuildContext context, String gameId) {
    _showSessionDialog(context, gameId: gameId);
  }

  void _showSessionDialog(BuildContext context, {required String gameId, GameSession? existingSession}) {
    final hours = existingSession != null ? (existingSession.durationMinutes / 60).floor() : 0;
    final mins = existingSession != null ? existingSession.durationMinutes % 60 : 0;
    
    final hoursController = TextEditingController(text: hours > 0 ? hours.toString() : '');
    final minsController = TextEditingController(text: mins > 0 ? mins.toString() : '');
    final descController = TextEditingController(text: existingSession?.description ?? '');
    DateTime selectedDate = existingSession?.sessionDate ?? DateTime.now();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(existingSession == null ? 'Registrar Sesión' : 'Editar Sesión'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Fecha: ${selectedDate.day}/${selectedDate.month}/${selectedDate.year}'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setDialogState(() => selectedDate = picked);
                    }
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: hoursController,
                        decoration: const InputDecoration(
                          labelText: 'Horas',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: minsController,
                        decoration: const InputDecoration(
                          labelText: 'Minutos',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(
                    labelText: 'Descripción (opcional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () async {
                final h = int.tryParse(hoursController.text) ?? 0;
                final m = int.tryParse(minsController.text) ?? 0;
                final totalMinutes = (h * 60) + m;

                if (totalMinutes > 0) {
                  bool success;
                  if (existingSession == null) {
                    success = await context.read<BacklogProvider>().addGameSession(
                      gameId: gameId,
                      date: selectedDate,
                      durationMinutes: totalMinutes,
                      description: descController.text,
                    );
                  } else {
                    success = await context.read<BacklogProvider>().updateGameSession(
                      sessionId: existingSession.id,
                      date: selectedDate,
                      durationMinutes: totalMinutes,
                      description: descController.text,
                    );
                  }

                  if (success && context.mounted) {
                    Navigator.pop(context);
                    setState(() {});
                  }
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  void _showReviewDialog(BuildContext context, GameBacklogEntry entry) {
    showDialog(
      context: context,
      builder: (context) => ReviewDialog(
        entryId: entry.id,
        initialTitle: entry.reviewTitle,
        initialContent: entry.notes,
        initialIsSpoiler: entry.isSpoiler,
      ),
    );
  }

  Widget _buildIgdbStats() {
      final rating = _apiDetails!['aggregated_rating'] ?? _apiDetails!['total_rating'] ?? _apiDetails!['rating'];
      final companies = _apiDetails!['involved_companies'] as List?;
      
      return Column(
          children: [
              Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                      if (rating != null)
                          _buildStatBadge(
                              'IGDB Score', 
                              (rating as num).toInt().toString(), 
                              _getRatingColor((rating as num).toInt()),
                              Icons.star
                          ),
                  ],
              ),
              if (companies != null && companies.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  const Divider(color: Colors.white24),
                  const SizedBox(height: 12),
                  Text(
                      'Desarrollado por', 
                      style: TextStyle(color: Colors.grey[400], fontSize: 14)
                  ),
                  const SizedBox(height: 8),
                  Text(
                       (companies.first['company']['name'] as String),
                       style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
              ]
          ],
      );
  }

  Widget _buildStatBadge(String label, String value, Color color, IconData icon) {
      return Column(
          children: [
              Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: color, width: 3),
                      color: color.withOpacity(0.1),
                  ),
                  child: Text(
                      value,
                      style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
              ),
              const SizedBox(height: 8),
              Text(label, style: const TextStyle(color: Colors.grey)),
          ],
      );
  }

  Color _getRatingColor(int score) {
      if (score >= 75) return Colors.greenAccent;
      if (score >= 50) return Colors.amberAccent;
      return Colors.redAccent;
  }

  Widget _buildMediaSection() {
     if (_apiDetails == null || _apiDetails!['screenshots'] == null) return const SizedBox.shrink();
     
     final screenshots = _apiDetails!['screenshots'] as List;
     if (screenshots.isEmpty) return const SizedBox.shrink();

     return Column(
         crossAxisAlignment: CrossAxisAlignment.start,
         children: [
             Text('Galería', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white)),
             const SizedBox(height: 16),
             SizedBox(
                 height: 180,
                 child: ListView.builder(
                     scrollDirection: Axis.horizontal,
                     itemCount: screenshots.length,
                     itemBuilder: (context, index) {
                         String url = screenshots[index]['url'];
                         url = 'https:${url.replaceAll('t_thumb', 't_720p')}'; 
                         
                         return Padding(
                             padding: const EdgeInsets.only(right: 12),
                             child: ClipRRect(
                                 borderRadius: BorderRadius.circular(8),
                                 child: CachedNetworkImage(
                                     imageUrl: url,
                                     placeholder: (_,__) => Container(color: Colors.grey[900], width: 320),
                                     errorWidget: (_,__,___) => const Icon(Icons.error),
                                 ),
                             ),
                         );
                     },
                 ),
             ),
         ],
     );
  }

  void _showEditDialog(BuildContext context, dynamic entry, BacklogProvider provider) {
      showDialog(
        context: context,
        builder: (context) => EditGameDialog(
          entry: entry,
          game: _game,
          onUpdate: ({status, hoursPlayed, rating, notes}) async {
            final success = await provider.updateGameEntry(
              entryId: entry.id,
              status: status,
              hoursPlayed: hoursPlayed,
              rating: rating,
              notes: notes,
            );

            if (success && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Juego actualizado')),
              );
              setState(() {}); 
            }
          },
        ),
      );
  }

  Future<void> _addToBacklog(BuildContext context, BacklogProvider provider) async {
      final success = await provider.addGameFromSearch(_game);
      if (success && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Juego agregado al backlog')),
          );
      }
  }

  void _showAddToListSheet(BuildContext context, BacklogProvider provider) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final lists = provider.gameLists;

            if (lists.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.collections_bookmark_outlined, size: 48, color: Colors.grey[500]),
                    const SizedBox(height: 16),
                    const Text('No tienes colecciones aún'),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _showQuickCreateList(context, provider);
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Crear Colección'),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              );
            }

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Añadir a colección',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        TextButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _showQuickCreateList(context, provider);
                          },
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Nueva'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...lists.map((list) {
                    return FutureBuilder<List<GameList>>(
                      future: provider.getListsForGame(widget.gameId),
                      builder: (context, snapshot) {
                        final containingLists = snapshot.data ?? [];
                        final isInList = containingLists.any((l) => l.id == list.id);

                        return CheckboxListTile(
                          title: Text(list.name),
                          subtitle: list.description != null
                              ? Text(list.description!, maxLines: 1, overflow: TextOverflow.ellipsis)
                              : null,
                          secondary: Icon(
                            Icons.collections_bookmark,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          value: isInList,
                          onChanged: (value) async {
                            if (value == true) {
                              await provider.addGameToList(list.id, widget.gameId);
                            } else {
                              await provider.removeGameFromList(list.id, widget.gameId);
                            }
                            setSheetState(() {});
                          },
                        );
                      },
                    );
                  }),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showQuickCreateList(BuildContext context, BacklogProvider provider) {
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nueva Colección'),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Nombre',
            hintText: 'Ej: RPGs favoritos',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isEmpty) return;

              final success = await provider.createGameList(name: name);
              if (success && context.mounted) {
                Navigator.pop(context);
                // Abrir de nuevo el bottom sheet para añadir
                _showAddToListSheet(context, provider);
              }
            },
            child: const Text('Crear'),
          ),
        ],
      ),
    );
  }
}