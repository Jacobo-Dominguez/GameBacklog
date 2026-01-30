import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../data/datasources/database_helper.dart';
import '../../data/datasources/game_local_datasource_impl.dart';
import '../../data/datasources/game_backlog_local_datasource_impl.dart';
import '../../data/models/game_model.dart';
import '../../data/models/game_backlog_model.dart';
import '../../domain/entities/game.dart';
import '../../domain/entities/game_backlog_entry.dart';

class BacklogProvider with ChangeNotifier {
  final String userId;
  final GameLocalDataSourceImpl gameDataSource;
  final GameBacklogLocalDataSourceImpl backlogDataSource;

  List<GameBacklogEntry> _backlogEntries = [];
  Map<String, Game> _gamesMap = {};
  String _selectedFilter = 'all';
  String _searchQuery = '';
  bool _isLoading = false;
  Map<String, int> _stats = {};

  BacklogProvider({
    required this.userId,
    required this.gameDataSource,
    required this.backlogDataSource,
  }) {
    loadBacklog();
  }

  List<GameBacklogEntry> get backlogEntries => _backlogEntries;
  Map<String, Game> get gamesMap => _gamesMap;
  String get selectedFilter => _selectedFilter;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;
  Map<String, int> get stats => _stats;

  List<GameBacklogEntry> get filteredEntries {
    var entries = _backlogEntries;

    // Filtrar por estado
    if (_selectedFilter != 'all') {
      entries = entries.where((e) => e.status == _selectedFilter).toList();
    }

    // Filtrar por búsqueda
    if (_searchQuery.isNotEmpty) {
      entries = entries.where((e) {
        final game = _gamesMap[e.gameId];
        return game?.title.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false;
      }).toList();
    }

    return entries;
  }

  Future<void> loadBacklog() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Cargar entradas del backlog
      final entries = await backlogDataSource.getBacklogByUserId(userId);
      _backlogEntries = entries;

      // Cargar información de los juegos
      final gameIds = entries.map((e) => e.gameId).toSet();
      _gamesMap.clear();
      for (var gameId in gameIds) {
        final game = await gameDataSource.getGameById(gameId);
        if (game != null) {
          _gamesMap[gameId] = game;
        }
      }

      // Cargar estadísticas
      await _loadStats();
    } catch (e) {
      debugPrint('Error loading backlog: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadStats() async {
    try {
      _stats = await backlogDataSource.getStatsByUserId(userId);
    } catch (e) {
      debugPrint('Error loading stats: $e');
      _stats = {};
    }
  }

  Future<bool> addGame({
    required String title,
    required String platform,
    String status = 'pending',
    String? genre,
  }) async {
    try {
      const uuid = Uuid();

      // Crear el juego
      final game = GameModel(
        id: uuid.v4(),
        title: title,
        platform: platform,
        genre: genre,
        userId: userId, // Usar el userId actual del provider
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await gameDataSource.insertGame(game);

      // Crear entrada en el backlog
      final backlogEntry = GameBacklogModel(
        id: uuid.v4(),
        userId: userId,
        gameId: game.id,
        status: status,
        hoursPlayed: 0,
        addedDate: DateTime.now(),
        lastUpdated: DateTime.now(),
      );

      await backlogDataSource.insertBacklogEntry(backlogEntry);

      // Actualizar estado local
      _backlogEntries.add(backlogEntry);
      _gamesMap[game.id] = game;
      await _loadStats();
      notifyListeners();

      return true;
    } catch (e) {
      debugPrint('Error adding game: $e');
      return false;
    }
  }

  /// ✅ NUEVO MÉTODO: Agregar juego desde búsqueda RAWG
  Future<bool> addGameFromSearch(Game game) async {
    try {
      // Verificar si ya existe en el backlog (por remoteId o título)
      if (game.remoteId != null) {
        final existing = _backlogEntries.any(
          (e) => _gamesMap[e.gameId]?.remoteId == game.remoteId,
        );
        if (existing) return false; // Ya existe
      }

      // Guardar juego en DB local
      final gameModel = GameModel(
        id: game.id,
        title: game.title,
        platform: game.platform,
        genre: game.genre,
        releaseDate: game.releaseDate,
        coverUrl: game.coverUrl,
        description: game.description,
        remoteId: game.remoteId,
        createdAt: game.createdAt,
        updatedAt: game.updatedAt,
        userId: game.userId,
      );
      
      await gameDataSource.insertGame(gameModel);

      // Crear entrada en backlog
      final backlogEntry = GameBacklogModel(
        id: const Uuid().v4(),
        userId: userId,
        gameId: game.id,
        status: 'pending', // Estado por defecto
        hoursPlayed: 0,
        addedDate: DateTime.now(),
        lastUpdated: DateTime.now(),
      );

      await backlogDataSource.insertBacklogEntry(backlogEntry);

      // Actualizar estado local
      _backlogEntries.add(backlogEntry);
      _gamesMap[game.id] = game;
      await _loadStats();
      notifyListeners();

      return true;
    } catch (e) {
      debugPrint('Error adding game from search: $e');
      return false;
    }
  }

  Future<bool> updateGameEntry({
    required String entryId,
    String? status,
    int? hoursPlayed,
    int? rating,
    String? notes,
  }) async {
    try {
      final entry = _backlogEntries.firstWhere((e) => e.id == entryId);
      
      final updatedEntry = GameBacklogModel(
        id: entry.id,
        userId: entry.userId,
        gameId: entry.gameId,
        status: status ?? entry.status,
        hoursPlayed: hoursPlayed ?? entry.hoursPlayed,
        rating: rating ?? entry.rating,
        notes: notes ?? entry.notes,
        addedDate: entry.addedDate,
        completedDate: status == 'completed' ? DateTime.now() : entry.completedDate,
        lastUpdated: DateTime.now(),
      );

      await backlogDataSource.updateBacklogEntry(updatedEntry);

      // Actualizar estado local
      final index = _backlogEntries.indexWhere((e) => e.id == entryId);
      if (index != -1) {
        _backlogEntries[index] = updatedEntry;
      }

      await _loadStats();
      notifyListeners();

      return true;
    } catch (e) {
      debugPrint('Error updating game entry: $e');
      return false;
    }
  }

  Future<bool> removeGame(String entryId) async {
    try {
      await backlogDataSource.deleteBacklogEntry(entryId);

      // Actualizar estado local
      _backlogEntries.removeWhere((e) => e.id == entryId);
      await _loadStats();
      notifyListeners();

      return true;
    } catch (e) {
      debugPrint('Error removing game: $e');
      return false;
    }
  }

  void setFilter(String filter) {
    _selectedFilter = filter;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void clearSearch() {
    _searchQuery = '';
    notifyListeners();
  }

  int getTotalGames() {
    return _backlogEntries.length;
  }

  int getGamesByStatus(String status) {
    return _stats[status] ?? 0;
  }

  double getCompletionPercentage() {
    final total = getTotalGames();
    if (total == 0) return 0;
    final completed = getGamesByStatus('completed');
    return (completed / total) * 100;
  }
}