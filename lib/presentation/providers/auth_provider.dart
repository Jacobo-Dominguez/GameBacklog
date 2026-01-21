import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../core/utils/crypto_utils.dart';
import '../../data/datasources/user_local_datasource.dart';
import '../../data/datasources/session_local_datasource.dart';
import '../../data/models/user_model.dart';
import '../../domain/entities/user.dart';

class AuthProvider with ChangeNotifier {
  final UserLocalDataSource userDataSource;
  final SessionLocalDataSource sessionDataSource;

  User? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  AuthProvider({
    required this.userDataSource,
    required this.sessionDataSource,
  });

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;

  /// Inicializar sesión al abrir la app
  Future<void> initializeAuth() async {
    _isLoading = true;
    notifyListeners();

    try {
      final userId = await sessionDataSource.getCurrentUserId();
      if (userId != null) {
        final user = await userDataSource.getUserById(userId);
        _currentUser = user;
      }
    } catch (e) {
      _errorMessage = 'Error al inicializar sesión';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Registrar nuevo usuario
  Future<bool> register({
    required String username,
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Verificar si el email ya existe
      final existingUser = await userDataSource.getUserByEmail(email);
      if (existingUser != null) {
        _errorMessage = 'El email ya está registrado';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Verificar si el username ya existe
      final existingUsername = await userDataSource.getUserByUsername(username);
      if (existingUsername != null) {
        _errorMessage = 'El nombre de usuario ya está en uso';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Crear nuevo usuario
      const uuid = Uuid();
      final user = UserModel(
        id: uuid.v4(),
        username: username,
        email: email,
        passwordHash: CryptoUtils.hashPassword(password),
        createdAt: DateTime.now(),
      );

      await userDataSource.insertUser(user);
      await sessionDataSource.saveSession(user.id);
      _currentUser = user;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Error al registrar usuario: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Iniciar sesión
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await userDataSource.getUserByEmail(email);
      
      if (user == null) {
        _errorMessage = 'Usuario no encontrado';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      if (!CryptoUtils.verifyPassword(password, user.passwordHash)) {
        _errorMessage = 'Contraseña incorrecta';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      await sessionDataSource.saveSession(user.id);
      _currentUser = user;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Error al iniciar sesión: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Cerrar sesión
  Future<void> logout() async {
    await sessionDataSource.clearSession();
    _currentUser = null;
    notifyListeners();
  }

  /// Limpiar mensaje de error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
