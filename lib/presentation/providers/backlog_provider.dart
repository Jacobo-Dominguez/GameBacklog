import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../data/datasources/database_helper.dart';
import '../../data/datasources/game_local_datasource_impl.dart';
import '../../data/datasources/game_backlog_local_datasource_impl.dart';
import '../../data/models/game_model.dart';
import '../../data/models/game_backlog_model.dart';
import '../../domain/entities/game.dart';
import '../../domain/entities/game_backlog_entry.dart';

import '../../data/datasources/game_session_local_datasource.dart';
import '../../domain/entities/game_session.dart';
import '../../data/models/game_session_model.dart';

class BacklogProvider with ChangeNotifier {
  final String userId;
  final GameLocalDataSourceImpl gameDataSource;
  final GameBacklogLocalDataSourceImpl backlogDataSource;
  final GameSessionLocalDataSource sessionDataSource;

  List<GameBacklogEntry> _backlogEntries = [];
  Map<String, Game> _gamesMap = {};
  List<GameSession> _recentSessions = [];
  String _selectedFilter = 'all';
  String _searchQuery = '';
  bool _isLoading = false;
  Map<String, int> _stats = {};

  BacklogProvider({
    required this.userId,
    required this.gameDataSource,
    required this.backlogDataSource,
    required this.sessionDataSource,
  }) {
    loadBacklog();
  }

  List<GameBacklogEntry> get backlogEntries => _backlogEntries;
  Map<String, Game> get gamesMap => _gamesMap;
  List<GameSession> get recentSessions => _recentSessions;
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

      // Cargar sesiones recientes (opcional para el feed inicial)
      _recentSessions = await sessionDataSource.getSessionsByUserId(userId);
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
        isFavorite: false,
        reviewTitle: null,
        isSpoiler: false,
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

// lib/presentation/providers/backlog_provider.dart
Future<bool> addGameFromSearch(Game game) async {
  try {
    // Verificar si ya existe en el backlog
    if (game.remoteId != null) {
      final existing = _backlogEntries.any(
        (e) => _gamesMap[e.gameId]?.remoteId == game.remoteId,
      );
      if (existing) return false;
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
      status: 'pending',
      hoursPlayed: 0,
      isFavorite: false,
      reviewTitle: null,
      isSpoiler: false,
      addedDate: DateTime.now(),
      lastUpdated: DateTime.now(),
    );

    await backlogDataSource.insertBacklogEntry(backlogEntry);

    // Actualizar estado local (SOLO DENTRO DEL PROVIDER)
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

  Future<bool> updateReview({
    required String entryId,
    required String? title,
    required String? content,
    required bool isSpoiler,
  }) async {
    try {
      final entry = _backlogEntries.firstWhere((e) => e.id == entryId);
      
      final updatedEntry = GameBacklogModel(
        id: entry.id,
        userId: entry.userId,
        gameId: entry.gameId,
        status: entry.status,
        hoursPlayed: entry.hoursPlayed,
        rating: entry.rating,
        notes: content,
        isFavorite: entry.isFavorite,
        reviewTitle: title,
        isSpoiler: isSpoiler,
        addedDate: entry.addedDate,
        completedDate: entry.completedDate,
        lastUpdated: DateTime.now(),
      );

      await backlogDataSource.updateBacklogEntry(updatedEntry);

      // Actualizar estado local
      final index = _backlogEntries.indexWhere((e) => e.id == entryId);
      if (index != -1) {
        _backlogEntries[index] = updatedEntry;
      }

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error updating review: $e');
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
        isFavorite: entry.isFavorite,
        reviewTitle: entry.reviewTitle,
        isSpoiler: entry.isSpoiler,
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

  Future<void> toggleFavorite(String entryId) async {
    try {
      final entry = _backlogEntries.firstWhere((e) => e.id == entryId);
      
      final updatedEntry = GameBacklogModel(
        id: entry.id,
        userId: entry.userId,
        gameId: entry.gameId,
        status: entry.status,
        hoursPlayed: entry.hoursPlayed,
        rating: entry.rating,
        notes: entry.notes,
        isFavorite: !entry.isFavorite,
        reviewTitle: entry.reviewTitle,
        isSpoiler: entry.isSpoiler,
        addedDate: entry.addedDate,
        completedDate: entry.completedDate,
        lastUpdated: DateTime.now(),
      );

      await backlogDataSource.updateBacklogEntry(updatedEntry);

      // Actualizar estado local
      final index = _backlogEntries.indexWhere((e) => e.id == entryId);
      if (index != -1) {
        _backlogEntries[index] = updatedEntry;
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error toggling favorite: $e');
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

  Future<bool> addGameSession({
    required String gameId,
    required DateTime date,
    required int durationMinutes,
    String? description,
  }) async {
    try {
      final session = GameSessionModel(
        id: const Uuid().v4(),
        gameId: gameId,
        userId: userId,
        sessionDate: date,
        durationMinutes: durationMinutes,
        description: description,
      );

      await sessionDataSource.insertSession(session);

      // Recalcular horas jugadas en el backlog sumando todas las sesiones del juego
      await _recalculateHoursPlayed(gameId);

      _recentSessions.insert(0, session);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error adding game session: $e');
      return false;
    }
  }

  Future<bool> updateGameSession({
    required String sessionId,
    required DateTime date,
    required int durationMinutes,
    String? description,
  }) async {
    try {
      final sessionIndex = _recentSessions.indexWhere((s) => s.id == sessionId);
      if (sessionIndex == -1) return false;
      
      final oldSession = _recentSessions[sessionIndex];
      final updatedSession = GameSessionModel(
        id: sessionId,
        gameId: oldSession.gameId,
        userId: userId,
        sessionDate: date,
        durationMinutes: durationMinutes,
        description: description,
      );

      await sessionDataSource.updateSession(updatedSession);
      _recentSessions[sessionIndex] = updatedSession;

      // Recalcular horas jugadas
      await _recalculateHoursPlayed(oldSession.gameId);

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error updating game session: $e');
      return false;
    }
  }

  Future<bool> deleteGameSession(String sessionId) async {
    try {
      final sessionIndex = _recentSessions.indexWhere((s) => s.id == sessionId);
      if (sessionIndex == -1) return false;
      
      final session = _recentSessions[sessionIndex];
      await sessionDataSource.deleteSession(sessionId);
      _recentSessions.removeAt(sessionIndex);

      // Recalcular horas jugadas
      await _recalculateHoursPlayed(session.gameId);

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error deleting game session: $e');
      return false;
    }
  }

  Future<void> _recalculateHoursPlayed(String gameId) async {
    try {
      final sessions = await sessionDataSource.getSessionsByGameId(gameId);
      final totalMinutes = sessions.fold(0, (sum, s) => sum + s.durationMinutes);
      final totalHours = (totalMinutes / 60).floor(); // Usamos floor para horas completas

      final entry = _backlogEntries.firstWhere((e) => e.gameId == gameId);
      
      // Si hay sesiones, la primera define el startDate si no estaba ya fijo
      DateTime? firstSessionDate;
      if (sessions.isNotEmpty) {
        // sessions vienen ordenadas desc por session_date
        firstSessionDate = sessions.last.sessionDate;
      }

      await updateGameEntry(
        entryId: entry.id,
        hoursPlayed: totalHours,
      );

      if (firstSessionDate != null && entry.startDate == null) {
        await _updateDates(entry.id, startDate: firstSessionDate);
      }
    } catch (e) {
      debugPrint('Error recalculating hours: $e');
    }
  }

  Future<void> _updateDates(String entryId, {DateTime? startDate, DateTime? endDate}) async {
    try {
      final entry = _backlogEntries.firstWhere((e) => e.id == entryId);
      final updatedEntry = GameBacklogModel(
        id: entry.id,
        userId: entry.userId,
        gameId: entry.gameId,
        status: entry.status,
        hoursPlayed: entry.hoursPlayed,
        rating: entry.rating,
        notes: entry.notes,
        isFavorite: entry.isFavorite,
        reviewTitle: entry.reviewTitle,
        isSpoiler: entry.isSpoiler,
        startDate: startDate ?? entry.startDate,
        endDate: endDate ?? entry.endDate,
        addedDate: entry.addedDate,
        completedDate: entry.completedDate,
        lastUpdated: DateTime.now(),
      );

      await backlogDataSource.updateBacklogEntry(updatedEntry);

      final index = _backlogEntries.indexWhere((e) => e.id == entryId);
      if (index != -1) {
        _backlogEntries[index] = updatedEntry;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating dates: $e');
    }
  }

  Future<List<GameSession>> getSessionsForGame(String gameId) async {
    return await sessionDataSource.getSessionsByGameId(gameId);
  }

  int getTotalMinutesPlayed() {
    return _recentSessions.fold(0, (sum, s) => sum + s.durationMinutes);
  }
}