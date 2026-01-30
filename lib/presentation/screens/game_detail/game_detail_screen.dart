import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../domain/entities/game.dart';
import '../../../data/datasources/game_remote_datasource.dart';
import '../../providers/backlog_provider.dart';

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
  String? _remoteDescription; // ✅ Solo necesitamos la descripción remota
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
    // ✅ CORRECCIÓN: getGameDetails() ya devuelve Map, NO usar .toJson()
    if (_game.remoteId != null && (_game.description == null || _game.description!.isEmpty)) {
      try {
        // Usar búsqueda por nombre (más confiable con key gratuita)
        final results = await _remoteDataSource.searchGames(_game.title);
        if (mounted && results.isNotEmpty) {
          setState(() {
            _remoteDescription = results.first.description; // ✅ Descripción directa
          });
        }
      } catch (e) {
        debugPrint('Error loading description: $e');
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: Implementar gestión
        },
        icon: const Icon(Icons.edit),
        label: const Text('Gestionar'),
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
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (_game.platform != null && _game.platform!.isNotEmpty)
          Chip(
            avatar: const Icon(Icons.gamepad, size: 16),
            label: Text(_game.platform!),
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

  Widget _buildDescriptionSection() {
  // ✅ PRIORIDAD: 1) descripción remota (limpia), 2) descripción local, 3) mensaje predeterminado
  final descriptionText = _removeHtmlTags(_remoteDescription) != 'Sin descripción disponible.'
      ? _removeHtmlTags(_remoteDescription)
      : (_game.description != null && _game.description!.isNotEmpty
          ? _game.description!
          : 'Sin descripción disponible.');

  // ✅ Mostrar mensaje amigable si no hay descripción disponible
  if (descriptionText == 'Sin descripción disponible.') {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Acerca del juego', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'ℹ️ Información no disponible',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              Text(
                'La descripción detallada requiere una API key premium de RAWG. Con tu key actual solo se muestran datos básicos (nombre, portada, géneros).',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black),
              ),
              const SizedBox(height: 12),
              Text(
                '💡 Consejo: Puedes editar el juego desde el botón "Gestionar" para añadir tu propia descripción manualmente.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.blue),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ✅ Mostrar descripción normal (con expandir/colapsar) si está disponible
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Acerca del juego', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 12),
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
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5),
              maxLines: _isDescriptionExpanded ? null : 6,
              overflow: _isDescriptionExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _isDescriptionExpanded ? 'Ver menos' : 'Leer más',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    _isDescriptionExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: Theme.of(context).colorScheme.primary,
                    size: 18,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ],
  );
}
}