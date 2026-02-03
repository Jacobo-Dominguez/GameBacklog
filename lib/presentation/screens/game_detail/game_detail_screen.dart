import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../domain/entities/game.dart';
import '../../../data/datasources/game_remote_datasource.dart';
import '../../providers/backlog_provider.dart';
import '../backlog/widgets/edit_game_dialog.dart';

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
                    _remotePlatform = platforms.first['name'];
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
                  _buildHeaderInfo(),
                  const SizedBox(height: 24),
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
                icon: const Icon(Icons.edit),
                label: const Text('Gestionar'),
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
      expandedHeight: 300.0,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          _game.title,
          style: const TextStyle(
            color: Colors.white,
            shadows: [Shadow(color: Colors.black, blurRadius: 10)],
          ),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (_game.coverUrl != null && _game.coverUrl!.isNotEmpty)
              CachedNetworkImage(
                imageUrl: _game.coverUrl!,
                fit: BoxFit.cover,
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[800],
                  child: const Icon(Icons.videogame_asset, size: 80, color: Colors.white54),
                ),
              )
            else
              Container(
                color: Colors.grey[800],
                child: const Icon(Icons.videogame_asset, size: 80, color: Colors.white54),
              ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black87],
                  stops: [0.6, 1.0],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderInfo() {
    final platformToShow = _remotePlatform ?? _game.platform;
    
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (platformToShow != null && platformToShow.isNotEmpty)
          Chip(
            avatar: const Icon(Icons.gamepad, size: 16),
            label: Text(platformToShow),
          ),
        if (_game.releaseDate != null)
          Chip(
            avatar: const Icon(Icons.calendar_today, size: 16),
            label: Text('${_game.releaseDate!.year}'),
          ),
      ],
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
          genresToShow = [_game.genre!];
      }

      return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
              if (genresToShow.isNotEmpty) ...[
                  Text('Géneros', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white)),
                  const SizedBox(height: 12),
                  Wrap(
                      spacing: 8, 
                      children: genresToShow.take(4).map((g) => Chip(label: Text(g))).toList()
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
          ],
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
                         url = 'https:${url.replaceAll('t_thumb', 't_screenshot_med')}'; 
                         
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
}