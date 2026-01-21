import 'dart:convert';
import 'package:crypto/crypto.dart';

class CryptoUtils {
  /// Hashea una contraseña usando SHA-256
  static String hashPassword(String password) {
    final bytes = utf8.encode(password);
    final hash = sha256.convert(bytes);
    return hash.toString();
  }

  /// Verifica si una contraseña coincide con su hash
  static bool verifyPassword(String password, String hashedPassword) {
    return hashPassword(password) == hashedPassword;
  }
}
