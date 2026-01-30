import 'package:flutter_test/flutter_test.dart';
import 'package:gamebacklog/core/utils/crypto_utils.dart';

void main() {
  group('CryptoUtils', () {
    test('hashPassword should return a non-empty hash', () {
      // Arrange
      const password = 'testPassword123';

      // Act
      final hash = CryptoUtils.hashPassword(password);

      // Assert
      expect(hash, isNotEmpty);
      expect(hash.length, equals(64)); // SHA-256 produces 64 hex characters
    });

    test('hashPassword should produce consistent hashes for same input', () {
      // Arrange
      const password = 'testPassword123';

      // Act
      final hash1 = CryptoUtils.hashPassword(password);
      final hash2 = CryptoUtils.hashPassword(password);

      // Assert
      expect(hash1, equals(hash2));
    });

    test('hashPassword should produce different hashes for different inputs', () {
      // Arrange
      const password1 = 'testPassword123';
      const password2 = 'differentPassword456';

      // Act
      final hash1 = CryptoUtils.hashPassword(password1);
      final hash2 = CryptoUtils.hashPassword(password2);

      // Assert
      expect(hash1, isNot(equals(hash2)));
    });

    test('verifyPassword should return true for correct password', () {
      // Arrange
      const password = 'testPassword123';
      final hash = CryptoUtils.hashPassword(password);

      // Act
      final result = CryptoUtils.verifyPassword(password, hash);

      // Assert
      expect(result, isTrue);
    });

    test('verifyPassword should return false for incorrect password', () {
      // Arrange
      const correctPassword = 'testPassword123';
      const incorrectPassword = 'wrongPassword456';
      final hash = CryptoUtils.hashPassword(correctPassword);

      // Act
      final result = CryptoUtils.verifyPassword(incorrectPassword, hash);

      // Assert
      expect(result, isFalse);
    });

    test('verifyPassword should handle empty passwords', () {
      // Arrange
      const password = '';
      final hash = CryptoUtils.hashPassword(password);

      // Act
      final result = CryptoUtils.verifyPassword(password, hash);

      // Assert
      expect(result, isTrue);
    });
  });
}
