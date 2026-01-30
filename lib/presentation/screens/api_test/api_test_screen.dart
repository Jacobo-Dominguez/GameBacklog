import 'package:flutter/material.dart';
import '../../../data/datasources/game_remote_datasource.dart';
import '../../../domain/entities/game_search_result.dart';

class ApiTestScreen extends StatefulWidget {
  const ApiTestScreen({super.key});

  @override
  State<ApiTestScreen> createState() => _ApiTestScreenState();
}

class _ApiTestScreenState extends State<ApiTestScreen> {
  final _dataSource = GameRemoteDataSource();
  bool _isLoading = false;
  String _status = 'Presiona el botón para probar la API';
  List<GameSearchResult> _results = [];

  Future<void> _testConnection() async {
    setState(() {
      _isLoading = true;
      _status = 'Probando conexión...';
    });

    try {
      final isConnected = await _dataSource.testConnection();
      
      if (isConnected) {
        setState(() {
          _status = '✅ API conectada correctamente';
        });
        _searchGames();
      } else {
        setState(() {
          _status = '❌ Error de conexión. Verifica tu API key.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _status = '❌ Error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _searchGames() async {
    try {
      final results = await _dataSource.searchGames('Zelda');
      
      setState(() {
        _results = results;
        _status = '✅ Encontrados ${results.length} juegos';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _status = '❌ Error al buscar: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prueba de API RAWG'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      _status,
                      style: Theme.of(context).textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    if (_isLoading)
                      const CircularProgressIndicator()
                    else
                      ElevatedButton.icon(
                        onPressed: _testConnection,
                        icon: const Icon(Icons.cloud),
                        label: const Text('Probar API'),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (_results.isNotEmpty) ...[
              Text(
                'Resultados de búsqueda:',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: _results.length,
                  itemBuilder: (context, index) {
                    final game = _results[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: game.backgroundImage != null
                            ? Image.network(
                                game.backgroundImage!,
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(Icons.games, size: 40),
                              )
                            : const Icon(Icons.games, size: 40),
                        title: Text(game.name),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (game.platforms.isNotEmpty)
                              Text('🎮 ${game.platforms.first}'),
                            if (game.genres.isNotEmpty)
                              Text('📁 ${game.genres.join(', ')}'),
                            if (game.rating != null)
                              Text('⭐ ${game.rating}/5'),
                          ],
                        ),
                        isThreeLine: true,
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
