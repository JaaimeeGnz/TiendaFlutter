import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/supabase_service.dart';
import '../services/user_service.dart';

/// AuthProvider - Gestión de autenticación
/// Replica la funcionalidad de AuthForm.tsx de Astro:
///   - Login: signInWithPassword → redirigir según admin o usuario
///   - Registro: signUp + insertar en tabla 'users' (id, email, username)
///   - Auto-login tras registro (signInWithPassword)
///   - Modo invitado con localStorage flags
///   - Verificación de admin por email
///   - Obtener username desde tabla 'users' (no solo metadata)
class AuthProvider with ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService.instance;
  final UserService _userService = UserService();
  static const String _guestModeKey = 'guestMode';
  static const String _guestEmailKey = 'guestEmail';

  UserModel? _user;
  bool _isLoading = false;
  String? _errorMessage;

  // Modo invitado
  bool _isGuestMode = false;
  String? _guestEmail;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null;

  // Modo invitado
  bool get isGuestMode => _isGuestMode;
  String? get guestEmail => _guestEmail;
  bool get canCheckout =>
      isAuthenticated || (isGuestMode && guestEmail != null);

  /// Verificar si el usuario actual es admin
  /// Replica la verificación del middleware de Astro
  bool get isAdmin {
    final adminEmail = dotenv.env['ADMIN_EMAIL'] ?? '';
    return _user?.email == adminEmail;
  }

  AuthProvider() {
    _initAuthListener();
    _loadCurrentUser();
    _loadGuestMode();
  }

  void _initAuthListener() {
    _supabaseService.authStateChanges.listen((data) {
      final user = data.session?.user;
      if (user != null) {
        _user = UserModel.fromSupabaseUser(user);
        // Si inicia sesión, salir del modo invitado
        _isGuestMode = false;
        _guestEmail = null;
        _clearGuestMode();
      } else {
        _user = null;
      }
      notifyListeners();
    });
  }

  Future<void> _loadCurrentUser() async {
    final currentUser = _supabaseService.currentUser;
    if (currentUser != null) {
      _user = UserModel.fromSupabaseUser(currentUser);
      // Obtener username desde tabla 'users' (como en account.astro)
      await _loadUsernameFromDB();
      notifyListeners();
    }
  }

  /// Cargar username desde la tabla 'users' de Supabase
  /// Replica: account.astro → .from('users').select('username').eq('id', session.user.id)
  Future<void> _loadUsernameFromDB() async {
    if (_user == null) return;
    try {
      final username = await _userService.getUsername(_user!.id);
      if (username != null && username.isNotEmpty) {
        _user = _user!.copyWith(username: username);
      }
    } catch (e) {
      print('Error loading username from DB: $e');
    }
  }

  /// Refrescar los datos del usuario desde Supabase
  Future<void> _refreshUser() async {
    try {
      // Forzar recarga del usuario desde el servidor
      final response = await _supabaseService.client.auth.refreshSession();
      final updatedUser = response.user;
      if (updatedUser != null) {
        _user = UserModel.fromSupabaseUser(updatedUser);
      }
    } catch (e) {
      // Fallback: usar el usuario en caché
      final currentUser = _supabaseService.currentUser;
      if (currentUser != null) {
        _user = UserModel.fromSupabaseUser(currentUser);
      }
    }
  }

  /// Cargar modo invitado desde SharedPreferences
  Future<void> _loadGuestMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isGuestMode = prefs.getBool(_guestModeKey) ?? false;
      _guestEmail = prefs.getString(_guestEmailKey);
      notifyListeners();
    } catch (e) {
      print('Error loading guest mode: $e');
    }
  }

  /// Guardar modo invitado
  Future<void> _saveGuestMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_guestModeKey, _isGuestMode);
      if (_guestEmail != null) {
        await prefs.setString(_guestEmailKey, _guestEmail!);
      }
    } catch (e) {
      print('Error saving guest mode: $e');
    }
  }

  /// Limpiar modo invitado
  Future<void> _clearGuestMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_guestModeKey);
      await prefs.remove(_guestEmailKey);
    } catch (e) {
      print('Error clearing guest mode: $e');
    }
  }

  /// Activar modo invitado con email
  /// Replica la funcionalidad de AuthForm.tsx con "Comprar como invitado"
  Future<bool> enableGuestMode(String email) async {
    if (email.isEmpty || !email.contains('@')) {
      _errorMessage = 'Por favor ingresa un email válido';
      notifyListeners();
      return false;
    }

    _isGuestMode = true;
    _guestEmail = email;
    await _saveGuestMode();
    notifyListeners();
    return true;
  }

  /// Desactivar modo invitado
  void disableGuestMode() {
    _isGuestMode = false;
    _guestEmail = null;
    _clearGuestMode();
    notifyListeners();
  }

  /// Obtener email para checkout (usuario autenticado o invitado)
  String? get checkoutEmail => _user?.email ?? _guestEmail;

  Future<bool> signIn(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _supabaseService.signInWithEmail(email, password);
      if (response.user != null) {
        _user = UserModel.fromSupabaseUser(response.user!);
        // Cargar username desde tabla 'users' (como en Astro)
        await _loadUsernameFromDB();
        _isLoading = false;
        notifyListeners();
        return true;
      }
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Registro de usuario
  /// Replica exactamente AuthForm.tsx de Astro:
  /// 1. Validar username (mínimo 3 chars, solo letras/números/guiones)
  /// 2. supabaseClient.auth.signUp({email, password})
  /// 3. Insertar en tabla 'users': {id, email, username}
  /// 4. Auto-login: signInWithPassword({email, password})
  Future<bool> signUp({
    required String email,
    required String password,
    String? username,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Validar username (como en AuthForm.tsx)
      if (username != null) {
        if (username.trim().isEmpty) {
          throw Exception('El nombre de usuario es requerido');
        }
        if (username.length < 3) {
          throw Exception('El nombre de usuario debe tener al menos 3 caracteres');
        }
        if (!RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(username)) {
          throw Exception(
            'El nombre de usuario solo puede contener letras, números, guiones y guiones bajos',
          );
        }
      }

      // 1. Crear cuenta en auth
      final response = await _supabaseService.signUpWithEmail(
        email: email,
        password: password,
        username: username,
      );

      if (response.user == null) {
        _isLoading = false;
        _errorMessage = 'No se pudo crear la cuenta';
        notifyListeners();
        return false;
      }

      // 2. Guardar perfil en tabla 'users' (como en AuthForm.tsx)
      if (username != null && response.user!.id.isNotEmpty) {
        try {
          await _userService.createUserProfile(
            userId: response.user!.id,
            email: email,
            username: username,
          );
        } catch (dbError) {
          // Si falla por username duplicado, propagar el error
          _errorMessage = dbError.toString();
          _isLoading = false;
          notifyListeners();
          return false;
        }
      }

      // 3. Auto-login tras registro (como en AuthForm.tsx)
      try {
        final signInResponse = await _supabaseService.signInWithEmail(
          email,
          password,
        );
        if (signInResponse.user != null) {
          _user = UserModel.fromSupabaseUser(signInResponse.user!);
          if (username != null) {
            _user = _user!.copyWith(username: username);
          }
        }
      } catch (e) {
        // Si el auto-login falla, el registro fue exitoso igualmente
        _user = UserModel.fromSupabaseUser(response.user!);
        print('Auto-login tras registro falló, pero registro exitoso: $e');
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _supabaseService.signOut();
      _user = null;
      // Limpiar dirección seleccionada al cerrar sesión
      // Nota: Esto puede ser manejado por el AddressProvider si es necesario
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> resetPassword(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _supabaseService.resetPassword(email);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Actualizar el nombre de usuario
  /// Replica: AccountModals.tsx EditProfileModal
  /// Actualiza tanto la metadata de auth como la tabla 'users'
  Future<bool> updateDisplayName(String displayName) async {
    if (!isAuthenticated) {
      _errorMessage = 'Usuario no autenticado';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Actualizar en tabla 'users' (como en Astro)
      await _userService.updateUsername(
        userId: _user!.id,
        username: displayName,
      );

      // También actualizar metadata de auth para consistencia
      await _supabaseService.updateUserProfile({
        'username': displayName,
        'display_name': displayName,
      });

      // Recargar datos del usuario
      await _refreshUser();
      _user = _user?.copyWith(username: displayName);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Actualizar la foto de perfil
  Future<bool> updateProfilePhoto(String photoUrl) async {
    if (!isAuthenticated) {
      _errorMessage = 'Usuario no autenticado';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _supabaseService.updateUserProfile({'avatar_url': photoUrl});
      // Recargar datos del usuario desde Supabase para garantizar sincronización
      await _refreshUser();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Cambiar contraseña
  Future<bool> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    if (!isAuthenticated) {
      _errorMessage = 'Usuario no autenticado';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Primero verificar que la contraseña actual es correcta
      final success = await _supabaseService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );

      if (success) {
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'No se pudo cambiar la contraseña';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Actualizar email
  Future<bool> updateEmail(String newEmail) async {
    if (!isAuthenticated) {
      _errorMessage = 'Usuario no autenticado';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _supabaseService.updateEmail(newEmail);
      // Recargar datos del usuario desde Supabase para garantizar sincronización
      await _refreshUser();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Eliminar cuenta
  Future<bool> deleteAccount() async {
    if (!isAuthenticated) {
      _errorMessage = 'Usuario no autenticado';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _supabaseService.deleteAccount();
      _user = null;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
