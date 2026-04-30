import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/backlog_provider.dart';
import '../../../domain/entities/game.dart';
import '../../../domain/entities/game_list.dart';
import '../../../domain/entities/game_search_result.dart';
import '../../../data/datasources/game_remote_datasource.dart';

class CollectionDetailScreen extends StatefulWidget {
  final String listId;

  const CollectionDetailScreen({super.key, required this.listId});

  @override
  State<CollectionDetailScreen> createState() => _CollectionDetailScreenState();
}

class _CollectionDetailScreenState extends State<CollectionDetailScreen> {
  List<Game> _games = [];
  bool _isLoading = true;
  GameList? _list;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final provider = context.read<BacklogProvider>();

    try {
      _list = provider.gameLists.firstWhere((l) => l.id == widget.listId);
    } catch (_) {
      _list = null;
    }

    final games = await provider.getGamesInList(widget.listId);

    if (mounted) {
      setState(() {
        _games = games;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_list?.name ?? 'Colección'),
        centerTitle: true,
        actions: [
          if (_list != null)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _showEditDialog(context),
            ),
        ],
      ),
      body: _games.isEmpty ? _buildEmptyState(context) : _buildGameGrid(context),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddGamesSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('Añadir Juegos'),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.videogame_asset_off, size: 80, color: Colors.grey[600]),
            const SizedBox(height: 20),
            Text(
              'Lista vacía',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Añade juegos de tu backlog o busca online.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameGrid(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 250,
        childAspectRatio: 0.65,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _games.length,
      itemBuilder: (context, index) {
        final game = _games[index];

        return Stack(
          children: [
            _buildSimpleGameCard(context, game),
            // Botón para quitar de la lista
            Positioned(
              top: 8,
              right: 8,
              child: Material(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => _removeFromList(game),
                  child: const Padding(
                    padding: EdgeInsets.all(6),
                    child: Icon(Icons.close, color: Colors.white, size: 18),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Tarjeta simple que no requiere un GameBacklogEntry
  Widget _buildSimpleGameCard(BuildContext context, Game game) {
    final theme = Theme.of(context);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/game/${game.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Portada
            SizedBox(
              height: 120,
              width: double.infinity,
              child: game.coverUrl != null && game.coverUrl!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: game.coverUrl!,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        color: Colors.grey[200],
                        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        color: Colors.grey[200],
                        child: const Icon(Icons.broken_image, size: 40, color: Colors.grey),
                      ),
                    )
                  : Container(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      child: Center(
                        child: Icon(
                          Icons.videogame_asset,
                          size: 64,
                          color: theme.colorScheme.primary.withOpacity(0.5),
                        ),
                      ),
                    ),
            ),
            // Info
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    game.title,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (game.platform != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      game.platform!,
                      style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Bottom Sheet: Backlog + Búsqueda IGDB ───

  void _showAddGamesSheet(BuildContext context) {
    final provider = context.read<BacklogProvider>();
    final searchController = TextEditingController();
    final remoteDataSource = GameRemoteDataSource();
    List<GameSearchResult> searchResults = [];
    bool isSearching = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            final showingSearch = searchController.text.trim().isNotEmpty;

            return DraggableScrollableSheet(
              initialChildSize: 0.75,
              maxChildSize: 0.95,
              minChildSize: 0.4,
              expand: false,
              builder: (_, scrollController) {
                return Column(
                  children: [
                    // Handle
                    Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey[400],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    // Título
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                      child: Text(
                        'Añadir juegos a "${_list?.name}"',
                        style: Theme.of(sheetContext).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                    // Campo de búsqueda
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: TextField(
                        controller: searchController,
                        decoration: InputDecoration(
                          hintText: 'Buscar juegos online...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    searchController.clear();
                                    setSheetState(() {
                                      searchResults = [];
                                    });
                                  },
                                )
                              : null,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        onSubmitted: (query) async {
                          if (query.trim().isEmpty) return;
                          setSheetState(() => isSearching = true);
                          try {
                            final results = await remoteDataSource.searchGames(query.trim());
                            setSheetState(() {
                              searchResults = results;
                              isSearching = false;
                            });
                          } catch (e) {
                            setSheetState(() => isSearching = false);
                          }
                        },
                      ),
                    ),
                    const Divider(),
                    // Contenido
                    Expanded(
                      child: isSearching
                          ? const Center(child: CircularProgressIndicator())
                          : showingSearch && searchResults.isNotEmpty
                              ? _buildSearchResultsList(
                                  sheetContext, scrollController, searchResults, provider, setSheetState)
                              : showingSearch && searchResults.isEmpty
                                  ? Center(
                                      child: Text('Sin resultados', style: TextStyle(color: Colors.grey[500])),
                                    )
                                  : _buildBacklogList(
                                      sheetContext, scrollController, provider, setSheetState),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  /// Lista de juegos del backlog (vista por defecto)
  Widget _buildBacklogList(
    BuildContext context,
    ScrollController scrollController,
    BacklogProvider provider,
    StateSetter setSheetState,
  ) {
    final allEntries = provider.backlogEntries;
    final gamesMap = provider.gamesMap;

    if (allEntries.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Tu backlog está vacío.\nUsa la barra de búsqueda para encontrar juegos online.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[500]),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Text(
            'Desde tu backlog',
            style: TextStyle(color: Colors.grey[500], fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ),
        Expanded(
          child: ListView.builder(
            controller: scrollController,
            itemCount: allEntries.length,
            itemBuilder: (context, index) {
              final entry = allEntries[index];
              final game = gamesMap[entry.gameId];
              if (game == null) return const SizedBox.shrink();

              final isAlreadyInList = _games.any((g) => g.id == game.id);

              return _buildGameTile(
                context: context,
                title: game.title,
                subtitle: _getStatusLabel(entry.status),
                imageUrl: game.coverUrl,
                isAlreadyInList: isAlreadyInList,
                onAdd: () async {
                  final success = await provider.addGameToList(widget.listId, game.id);
                  if (success) {
                    setState(() => _games.add(game));
                    setSheetState(() {});
                  }
                },
              );
            },
          ),
        ),
      ],
    );
  }

  /// Lista de resultados de búsqueda IGDB
  Widget _buildSearchResultsList(
    BuildContext context,
    ScrollController scrollController,
    List<GameSearchResult> results,
    BacklogProvider provider,
    StateSetter setSheetState,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Text(
            'Resultados de búsqueda',
            style: TextStyle(color: Colors.grey[500], fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ),
        Expanded(
          child: ListView.builder(
            controller: scrollController,
            itemCount: results.length,
            itemBuilder: (context, index) {
              final result = results[index];

              // Comprobar si ya está en la lista (por remoteId)
              final isAlreadyInList = _games.any((g) => g.remoteId == result.id);

              return _buildGameTile(
                context: context,
                title: result.name,
                subtitle: result.platforms.isNotEmpty ? result.platforms.first : null,
                imageUrl: result.backgroundImage,
                isAlreadyInList: isAlreadyInList,
                onAdd: () async {
                  // Convertir GameSearchResult → Game
                  final game = Game(
                    id: const Uuid().v4(),
                    title: result.name,
                    platform: result.platforms.isNotEmpty ? result.platforms.first : null,
                    genre: result.genres.isNotEmpty ? result.genres.first : null,
                    releaseDate: result.released != null
                        ? DateTime.tryParse(result.released!)
                        : null,
                    coverUrl: result.backgroundImage,
                    description: result.description,
                    remoteId: result.id,
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                    userId: provider.userId,
                  );

                  // Guardar en BD (sin añadir al backlog)
                  await provider.saveGameToDb(game);
                  // Añadir a la lista
                  final success = await provider.addGameToList(widget.listId, game.id);
                  if (success) {
                    setState(() => _games.add(game));
                    setSheetState(() {});
                  }
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildGameTile({
    required BuildContext context,
    required String title,
    String? subtitle,
    String? imageUrl,
    required bool isAlreadyInList,
    required VoidCallback onAdd,
  }) {
    return ListTile(
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 48,
          height: 64,
          child: imageUrl != null && imageUrl.isNotEmpty
              ? Image.network(imageUrl, fit: BoxFit.cover)
              : Container(
                  color: Colors.grey[800],
                  child: const Icon(Icons.videogame_asset, size: 24),
                ),
        ),
      ),
      title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: subtitle != null
          ? Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[500]))
          : null,
      trailing: isAlreadyInList
          ? const Icon(Icons.check_circle, color: Colors.green)
          : IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: onAdd,
            ),
    );
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'playing': return 'Jugando';
      case 'completed': return 'Completado';
      case 'pending': return 'Pendiente';
      case 'on_hold': return 'En pausa';
      case 'dropped': return 'Abandonado';
      default: return status;
    }
  }

  Future<void> _removeFromList(Game game) async {
    final provider = context.read<BacklogProvider>();
    final success = await provider.removeGameFromList(widget.listId, game.id);
    if (success && mounted) {
      setState(() {
        _games.removeWhere((g) => g.id == game.id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${game.title} eliminado de la lista')),
      );
    }
  }

  void _showEditDialog(BuildContext context) {
    final nameController = TextEditingController(text: _list?.name ?? '');
    final descController = TextEditingController(text: _list?.description ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Colección'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Nombre'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descController,
              decoration: const InputDecoration(labelText: 'Descripción (opcional)'),
              maxLines: 2,
            ),
          ],
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

              final provider = context.read<BacklogProvider>();
              final success = await provider.updateGameList(
                listId: widget.listId,
                name: name,
                description: descController.text.trim().isNotEmpty
                    ? descController.text.trim()
                    : null,
              );

              if (success && context.mounted) {
                Navigator.pop(context);
                setState(() {
                  _list = provider.gameLists.firstWhere((l) => l.id == widget.listId);
                });
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }
}
