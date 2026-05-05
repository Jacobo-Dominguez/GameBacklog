import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/backlog_provider.dart';
import '../../../data/datasources/game_remote_datasource.dart';
import '../../../domain/entities/game_search_result.dart';
import '../../../data/services/game_search_service.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  final _service = GameRemoteDataSource();
  final _searchService = GameSearchService();
  List<GameSearchResult> _results = [];
  bool _loading = false;

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) return;
    
    setState(() => _loading = true);
    try {
      final results = await _service.searchGames(query.trim());
      if (mounted) {
        setState(() => _results = results);
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
      // ✅ Conversión segura a Map para fromIgdbResult
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

      // ✅ Agregar cover si existe
      if (gameResult.backgroundImage != null) {
        igdbMap['cover'] = {
          'url': gameResult.backgroundImage!.replaceAll('https:', '')
        };
      }

      // ✅ Agregar fecha de lanzamiento si existe
      if (releaseDate != null) {
        igdbMap['first_release_date'] = releaseDate.millisecondsSinceEpoch ~/ 1000;
      }

      // ✅ Convertir a Game usando el servicio
      final game = _searchService.fromIgdbResult(igdbMap, authProvider.currentUser!.id);

      // ✅ Usar API pública del provider
      final success = await backlogProvider.addGameFromSearch(game);
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ ${game.title} agregado al backlog')),
        );
        setState(() {
          _results = [];
          _controller.clear();
        });
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ Ya existe en tu backlog')),
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'Buscar juegos...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onSubmitted: _search,
              autofocus: true,
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _results.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _controller.text.isEmpty ? Icons.search : Icons.search_off,
                                size: 64,
                                color: Colors.grey,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _controller.text.isEmpty 
                                    ? 'Escribe para buscar juegos en IGDB...'
                                    : 'No se encontraron resultados para "${_controller.text}"',
                                style: const TextStyle(color: Colors.grey, fontSize: 16),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _results.length,
                        itemBuilder: (context, index) {
                          final game = _results[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: ListTile(
                              leading: game.backgroundImage != null
                                  ? Image.network(
                                      game.backgroundImage!,
                                      width: 60,
                                      height: 60,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) =>
                                          const Icon(Icons.videogame_asset, size: 40),
                                    )
                                  : const Icon(Icons.videogame_asset, size: 40),
                              title: Text(game.name),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (game.released != null)
                                    Text(
                                      'Lanzado: ${DateTime.tryParse(game.released!)?.year ?? '?'}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  if (game.genres.isNotEmpty)
                                    Text(
                                      'Géneros: ${game.genres.take(2).join(', ')}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                ],
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.add_circle_outline, color: Colors.green),
                                onPressed: () => _addGameToBacklog(game),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}