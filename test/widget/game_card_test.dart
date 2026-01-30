import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gamebacklog/presentation/screens/backlog/widgets/game_card.dart';
import 'package:gamebacklog/domain/entities/game.dart';
import 'package:gamebacklog/domain/entities/game_backlog_entry.dart';

void main() {
  group('GameCard Widget', () {
    late Game testGame;
    late GameBacklogEntry testEntry;

    setUp(() {
      testGame = Game(
        id: 'game-1',
        title: 'The Legend of Zelda',
        platform: 'Nintendo Switch',
        genre: 'Adventure',
        createdAt: DateTime.now(),
      );

      testEntry = GameBacklogEntry(
        id: 'entry-1',
        userId: 'user-1',
        gameId: 'game-1',
        status: 'playing',
        hoursPlayed: 15,
        rating: 9,
        addedDate: DateTime.now(),
        lastUpdated: DateTime.now(),
      );
    });

    testWidgets('should display game title', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GameCard(
              entry: testEntry,
              game: testGame,
              onEdit: () {},
              onDelete: () {},
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('The Legend of Zelda'), findsOneWidget);
    });

    testWidgets('should display platform', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GameCard(
              entry: testEntry,
              game: testGame,
              onEdit: () {},
              onDelete: () {},
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('🎮 Nintendo Switch'), findsOneWidget);
    });

    testWidgets('should display hours played', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GameCard(
              entry: testEntry,
              game: testGame,
              onEdit: () {},
              onDelete: () {},
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('⏱️ 15h'), findsOneWidget);
    });

    testWidgets('should display rating when present', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GameCard(
              entry: testEntry,
              game: testGame,
              onEdit: () {},
              onDelete: () {},
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('⭐ 9/10'), findsOneWidget);
    });

    testWidgets('should display status chip', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GameCard(
              entry: testEntry,
              game: testGame,
              onEdit: () {},
              onDelete: () {},
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Jugando'), findsOneWidget);
    });

    testWidgets('should show popup menu on tap', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GameCard(
              entry: testEntry,
              game: testGame,
              onEdit: () {},
              onDelete: () {},
            ),
          ),
        ),
      );

      // Act
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Editar'), findsOneWidget);
      expect(find.text('Eliminar'), findsOneWidget);
    });
  });
}
