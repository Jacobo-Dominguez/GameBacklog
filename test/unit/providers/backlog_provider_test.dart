import 'package:flutter_test/flutter_test.dart';
import 'package:gamebacklog/presentation/providers/backlog_provider.dart';
import 'package:gamebacklog/domain/entities/game.dart';
import 'package:gamebacklog/domain/entities/game_backlog_entry.dart';

void main() {
  group('BacklogProvider', () {
    late BacklogProvider provider;

    // setUp(() {
    //   provider = BacklogProvider(userId: 'test-user-id');
    // });

    test('initial state should be empty', () {
      expect(provider.backlogEntries, isEmpty);
      expect(provider.gamesMap, isEmpty);
      expect(provider.currentFilter, equals('all'));
      expect(provider.searchQuery, isEmpty);
    });

    test('getTotalGames should return correct count', () {
      // Initially should be 0
      expect(provider.getTotalGames(), equals(0));
    });

    test('getGamesByStatus should return 0 for all statuses initially', () {
      expect(provider.getGamesByStatus('playing'), equals(0));
      expect(provider.getGamesByStatus('completed'), equals(0));
      expect(provider.getGamesByStatus('pending'), equals(0));
      expect(provider.getGamesByStatus('on_hold'), equals(0));
      expect(provider.getGamesByStatus('dropped'), equals(0));
    });

    test('getCompletionPercentage should return 0 initially', () {
      expect(provider.getCompletionPercentage(), equals(0.0));
    });

    test('setFilter should update current filter', () {
      // Act
      provider.setFilter('playing');

      // Assert
      expect(provider.currentFilter, equals('playing'));
    });

    test('setSearchQuery should update search query', () {
      // Act
      provider.setSearchQuery('Zelda');

      // Assert
      expect(provider.searchQuery, equals('Zelda'));
    });

    test('clearSearch should reset search query', () {
      // Arrange
      provider.setSearchQuery('Zelda');

      // Act
      provider.clearSearch();

      // Assert
      expect(provider.searchQuery, isEmpty);
    });
  });
}
