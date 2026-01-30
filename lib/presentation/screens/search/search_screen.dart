import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/backlog_provider.dart';
import '../../../data/datasources/game_remote_datasource.dart';
import '../../../data/services/game_search_service.dart';
import '../../../domain/entities/game_search_result.dart'; // ✅ Ruta correcta

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
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _addGameToBacklog(GameSearchResult rawgGame) async {
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
      // Convertir resultado RAWG a modelo local
      final localGame = _searchService.fromRawgResult(
        rawgGame, 
        authProvider.currentUser!.id,
      );

      // Guardar en DB y agregar al backlog
      final success = await backlogProvider.addGameFromSearch(localGame);
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ ${localGame.title} agregado al backlog')),
        );
        // Opcional: limpiar búsqueda después de agregar
        setState(() {
          _results = [];
          _controller.clear();
        });
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ Ya existe en tu backlog o error al guardar')),
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
      appBar: AppBar(
        title: const Text('Buscar juegos'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _controller,
              decoration: const InputDecoration(
                hintText: 'Buscar en RAWG...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onSubmitted: _search,
              autofocus: true,
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _results.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            'Escribe para buscar juegos...',
                            style: TextStyle(color: Colors.grey),
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
                                      'Lanzado: ${game.released}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  if (game.rating != null)
                                    Text( // ✅ FIX: null safety para toStringAsFixed
                                      '⭐ ${game.rating!.toStringAsFixed(1)}',
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