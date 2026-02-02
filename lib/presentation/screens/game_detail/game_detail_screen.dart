import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../domain/entities/game.dart';
import '../../../data/datasources/game_remote_datasource.dart';
import '../../providers/backlog_provider.dart';
import '../backlog/widgets/edit_game_dialog.dart'; // Importar diálogo de edición

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
  String? _remoteDescription;   // Descripción de RAWG
  List<String>? _remoteGenres;  // Géneros de RAWG
  String? _remotePlatform;      // Primera plataforma de RAWG
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
    if (_game.remoteId != null && (_game.description == null || _game.description!.isEmpty)) {
      try {
        final results = await _remoteDataSource.searchGames(_game.title);
        if (mounted && results.isNotEmpty) {
          final firstResult = results.first;
          setState(() {
            _remoteDescription = firstResult.description;
            _remoteGenres = firstResult.genres.isNotEmpty ? firstResult.genres : null;
            _remotePlatform = firstResult.platforms.isNotEmpty ? firstResult.platforms.first : null;
          });
        }
      } catch (e) {
        debugPrint('Error loading details: $e');
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
          // Buscar si el juego ya está en el backlog
          final entry = provider.backlogEntries.where((e) => e.gameId == widget.gameId).isNotEmpty
              ? provider.backlogEntries.firstWhere((e) => e.gameId == widget.gameId)
              : null;
          
          if (entry != null) {
              // MODO EDICIÓN
              return FloatingActionButton.extended(
                onPressed: () => _showEditDialog(context, entry, provider),
                icon: const Icon(Icons.edit),
                label: const Text('Gestionar'),
                backgroundColor: Theme.of(context).colorScheme.primary,
              );
          } else {
              // MODO AGREGAR
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
    // ✅ Prioridad para plataforma: 1) remota, 2) local, 3) none
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

  // ✅ Helper para eliminar tags HTML de la descripción
  String _removeHtmlTags(String? html) {
    if (html == null || html.isEmpty) return 'Sin descripción disponible.';
    String result = html.replaceAll(RegExp(r'<[^>]*>'), '');
    result = result.replaceAll('&nbsp;', ' ');
    result = result.replaceAll('&quot;', '"');
    result = result.replaceAll('&apos;', "'");
    result = result.replaceAll('&amp;', '&');
    return result.trim().isNotEmpty ? result.trim() : 'Sin descripción disponible.';
  }

  // ✅ Traductor básico de géneros (inglés → español)
  String _translateGenre(String genre) {
    final translations = {
      'Action': 'Acción',
      'Adventure': 'Aventura',
      'RPG': 'RPG',
      'Shooter': 'Disparos',
      'Strategy': 'Estrategia',
      'Simulation': 'Simulación',
      'Puzzle': 'Puzles',
      'Racing': 'Carreras',
      'Sports': 'Deportes',
      'Fighting': 'Peleas',
      'Platformer': 'Plataformas',
      'Horror': 'Terror',
      'Indie': 'Indie',
      'Arcade': 'Arcade',
      'Card': 'Cartas',
      'Board': 'Tablero',
      'Family': 'Familiar',
      'Massively Multiplayer': 'Multijugador masivo',
      'Point-and-click': 'Apuntar y clicar',
      'Visual Novel': 'Novela visual',
      'Turn-based': 'Por turnos',
      'Tactical': 'Táctico',
      'Open World': 'Mundo abierto',
      'Survival': 'Supervivencia',
      'Stealth': 'Sigilo',
      'Battle Royale': 'Battle Royale',
    };
    
    return translations[genre.trim()] ?? genre; // Si no hay traducción, mantener original
  }

  Widget _buildDescriptionSection() {
    // ✅ PRIORIDAD para géneros: 1) remoto (traducido), 2) local, 3) vacío
    List<String> genresToShow = [];
    
    if (_remoteGenres != null && _remoteGenres!.isNotEmpty) {
      genresToShow = _remoteGenres!.map((genre) => _translateGenre(genre)).toList();
    } else if (_game.genre != null && _game.genre!.isNotEmpty) {
      genresToShow = [_game.genre!];
    }

    // ✅ PRIORIDAD para descripción
    final descriptionText = _removeHtmlTags(_remoteDescription) != 'Sin descripción disponible.'
        ? _removeHtmlTags(_remoteDescription)
        : (_game.description != null && _game.description!.isNotEmpty
            ? _game.description!
            : 'Sin descripción disponible.');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ✅ Sección de Géneros (si existen) - ETIQUETA EN BLANCO
        if (genresToShow.isNotEmpty) ...[
          Text(
            'Géneros',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white, // ✅ TEXTO BLANCO PARA FONDO OSCURO
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: genresToShow.map((genre) => 
              Chip(
                label: Text(
                  genre,
                  style: const TextStyle(
                    color: Colors.white, // ✅ TEXTO BLANCO
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                // ✅ ELIMINADO: backgroundColor (para usar el estilo del tema)
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ).toList(),
          ),
          const SizedBox(height: 28),
        ],
        
        // ✅ Sección de Descripción - ETIQUETA EN BLANCO
        Text(
          'Acerca del juego',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white, // ✅ TEXTO BLANCO PARA FONDO OSCURO
          ),
        ),
        const SizedBox(height: 14),
        
        // ✅ Mostrar mensaje amigable si no hay descripción (CON ALTO CONTRASTE)
        if (descriptionText == 'Sin descripción disponible.') ...[
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.grey[300]!,
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ℹ️ Información limitada',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87, // ✅ Mantener negro en este caso (fondo claro)
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 11),
                Text(
                  'Con tu API key gratuita solo se muestran datos básicos (portada, géneros). La descripción completa requiere key premium de RAWG.',
                  style: const TextStyle(
                    color: Colors.black87, // ✅ Mantener negro en este caso (fondo claro)
                    fontSize: 15,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 15),
                Text.rich(
                  TextSpan(
                    children: [
                      const TextSpan(text: '💡 '),
                      TextSpan(
                        text: 'Consejo:',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.blue,
                        ),
                      ),
                      const TextSpan(text: ' Edita el juego desde "Gestionar" para añadir descripción manualmente.'),
                    ],
                  ),
                  style: const TextStyle(
                    color: Colors.black87, // ✅ Mantener negro en este caso (fondo claro)
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
          // ✅ Mostrar descripción normal si está disponible
          InkWell(
            onTap: () {
              setState(() {
                _isDescriptionExpanded = !_isDescriptionExpanded;
              });
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  descriptionText,
                  style: const TextStyle(
                    color: Colors.white, // ✅ TEXTO BLANCO PARA FONDO OSCURO
                    fontSize: 16,
                    height: 1.55,
                  ),
                  maxLines: _isDescriptionExpanded ? null : 6,
                  overflow: _isDescriptionExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _isDescriptionExpanded ? 'Ver menos' : 'Leer más',
                        style: const TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Icon(
                        _isDescriptionExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                        color: Colors.blue,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
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