import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/user_model.dart';
import '../../domain/entities/user.dart' as entity;

class AuthProvider with ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  entity.User? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  entity.User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;

  /// Inicializar sesión al abrir la app
  Future<void> initializeAuth() async {
    _isLoading = true;
    notifyListeners();

    try {
      final session = _supabase.auth.currentSession;
      if (session != null) {
        await _loadUserProfile(session.user.id, session.user.email ?? '');
      } else {
        // Suscribirse a cambios en la autenticación
        _supabase.auth.onAuthStateChange.listen((data) {
          final AuthChangeEvent event = data.event;
          final Session? currentSession = data.session;

          if (event == AuthChangeEvent.signedIn && currentSession != null) {
             _loadUserProfile(currentSession.user.id, currentSession.user.email ?? '');
          } else if (event == AuthChangeEvent.signedOut) {
            _currentUser = null;
            notifyListeners();
          }
        });
      }
    } catch (e) {
      _errorMessage = 'Error al inicializar sesión: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadUserProfile(String userId, String email) async {
    try {
      final response = await _supabase.from('profiles').select().eq('id', userId).maybeSingle();
      if (response != null) {
        // Combinamos la info del auth con la del perfil
        final userData = Map<String, dynamic>.from(response);
        userData['email'] = email;
        _currentUser = UserModel.fromJson(userData);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading user profile: $e');
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
      // 1. Verificar si el username ya existe (en Supabase esto se puede hacer con una query rápida)
      final existingUsername = await _supabase.from('profiles').select('id').eq('username', username).maybeSingle();
      if (existingUsername != null) {
        _errorMessage = 'El nombre de usuario ya está en uso';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // 2. Registrar en Supabase Auth
      final AuthResponse res = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'username': username}, // Esto alimentará el trigger que creamos en SQL
      );

      if (res.user != null) {
        // Supabase Auth y el trigger se encargan de crear el profile
        await _loadUserProfile(res.user!.id, email);
        _isLoading = false;
        notifyListeners();
        return true;
      }
      
      return false;
    } on AuthException catch (e) {
       _errorMessage = e.message;
       _isLoading = false;
       notifyListeners();
       return false;
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
      final AuthResponse res = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (res.user != null) {
        await _loadUserProfile(res.user!.id, res.user!.email ?? email);
        _isLoading = false;
        notifyListeners();
        return true;
      }
      return false;
    } on AuthException catch (e) {
      _errorMessage = 'Credenciales incorrectas: ${e.message}';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Error al iniciar sesión: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Cerrar sesión
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();
    try {
      await _supabase.auth.signOut();
      _currentUser = null;
    } catch (e) {
       _errorMessage = 'Error al cerrar sesión: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Actualizar perfil de usuario
  Future<bool> updateProfile({
    String? username,
    String? email,
    String? password,
    String? avatarPath,
  }) async {
    if (_currentUser == null) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Actualizar email/password en Auth si es necesario
      if (email != null && email != _currentUser!.email) {
         await _supabase.auth.updateUser(UserAttributes(email: email));
      }
      if (password != null && password.isNotEmpty) {
         await _supabase.auth.updateUser(UserAttributes(password: password));
      }

      // 2. Actualizar perfil (username, avatar) en la tabla profiles
      final updates = <String, dynamic>{};
      if (username != null && username != _currentUser!.username) {
        // Comprobar disponibilidad de username
        final existing = await _supabase.from('profiles').select('id').eq('username', username).neq('id', _currentUser!.id).maybeSingle();
        if (existing != null) {
           _errorMessage = 'El nombre de usuario ya está en uso';
           _isLoading = false;
           notifyListeners();
           return false;
        }
        updates['username'] = username;
      }
      
      if (avatarPath != null) {
        updates['avatar_url'] = avatarPath;
      }

      if (updates.isNotEmpty) {
        await _supabase.from('profiles').update(updates).eq('id', _currentUser!.id);
      }

      // 3. Recargar perfil
      await _loadUserProfile(_currentUser!.id, email ?? _currentUser!.email);
      
      _isLoading = false;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
       _errorMessage = e.message;
       _isLoading = false;
       notifyListeners();
       return false;
    } catch (e) {
      _errorMessage = 'Error al actualizar perfil: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Limpiar mensaje de error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
