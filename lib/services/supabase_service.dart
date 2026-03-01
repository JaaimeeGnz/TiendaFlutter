import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants/app_config.dart';

/// SupabaseService - Cliente Supabase singleton
/// Replica la configuración de src/lib/supabase.ts de Astro:
///   - supabaseClient: clave anónima, persistSession, autoRefreshToken
///   - Funciones auth: signIn, signUp, signOut, resetPassword, etc.
///   - Autenticación: getSession, updateUser, changePassword
class SupabaseService {
  static SupabaseService? _instance;
  late final SupabaseClient _client;

  SupabaseService._();

  static SupabaseService get instance {
    _instance ??= SupabaseService._();
    return _instance!;
  }

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      anonKey: AppConfig.supabaseAnonKey,
    );
    instance._client = Supabase.instance.client;
  }

  SupabaseClient get client => _client;

  // Auth helpers
  User? get currentUser => _client.auth.currentUser;
  String? get currentUserId => currentUser?.id;
  bool get isAuthenticated => currentUser != null;

  // Auth stream
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  /// Obtener el token de acceso actual (para headers Authorization: Bearer)
  /// Replica: AccountModals.tsx → session.access_token
  String? get accessToken => _client.auth.currentSession?.accessToken;

  /// Sign in con email y contraseña
  /// Replica: AuthForm.tsx → supabaseClient.auth.signInWithPassword({email, password})
  Future<AuthResponse> signInWithEmail(String email, String password) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  /// Sign up con email y contraseña
  /// Replica: AuthForm.tsx → supabaseClient.auth.signUp({email, password})
  /// NOTA: La inserción en tabla 'users' se hace en AuthProvider (como en Astro)
  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    String? username,
  }) async {
    return await _client.auth.signUp(
      email: email,
      password: password,
      data: username != null ? {'username': username} : null,
    );
  }

  /// Sign out
  /// Replica: api/auth/logout.ts → supabaseClient.auth.signOut()
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  /// Reset password
  Future<void> resetPassword(String email) async {
    await _client.auth.resetPasswordForEmail(email);
  }

  /// Get session
  /// Replica: lib/supabase.ts getSession()
  Future<Session?> getSession() async {
    final session = _client.auth.currentSession;
    return session;
  }

  /// Actualizar el perfil del usuario (metadata de auth)
  /// Replica: AccountModals.tsx → supabaseClient.auth.updateUser(...)
  Future<void> updateUserProfile(Map<String, dynamic> data) async {
    final user = currentUser;
    if (user == null) throw Exception('Usuario no autenticado');

    await _client.auth.updateUser(UserAttributes(data: data));
  }

  /// Cambiar contraseña
  /// Replica: AccountModals.tsx ChangePasswordModal → supabaseClient.auth.updateUser({password})
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final user = currentUser;
      if (user == null) throw Exception('Usuario no autenticado');

      await _client.auth.updateUser(UserAttributes(password: newPassword));
      return true;
    } catch (e) {
      print('Error changing password: $e');
      return false;
    }
  }

  /// Actualizar email
  /// Replica: AccountModals.tsx ChangeEmailModal → supabaseClient.auth.updateUser({email})
  Future<void> updateEmail(String newEmail) async {
    final user = currentUser;
    if (user == null) throw Exception('Usuario no autenticado');

    await _client.auth.updateUser(UserAttributes(email: newEmail));
  }

  /// Eliminar cuenta del usuario (datos de perfil)
  /// Replica: api/account/delete.ts
  /// NOTA: En Astro se usa service role en el server para admin.deleteUser.
  /// En Flutter, eliminamos los datos del usuario y cerramos sesión.
  /// La eliminación del auth user requiere service role en un backend.
  Future<void> deleteAccount() async {
    final user = currentUser;
    if (user == null) throw Exception('Usuario no autenticado');

    try {
      // Eliminar datos del usuario de las tablas
      // (Replica el orden de api/account/delete.ts)

      // 1. Eliminar direcciones
      try {
        await _client.from('addresses').delete().eq('user_id', user.id);
      } catch (e) {
        print('Error deleting addresses: $e');
      }

      // 2. Eliminar pedidos (si existe la tabla)
      try {
        await _client.from('orders').delete().eq('user_id', user.id);
      } catch (e) {
        print('Tabla de órdenes no existe, continuando...');
      }

      // 3. Eliminar datos del usuario en tabla users
      try {
        await _client.from('users').delete().eq('id', user.id);
      } catch (e) {
        print('Error deleting user data: $e');
      }

      // 4. Cerrar sesión (la eliminación del auth user requiere service role)
      await _client.auth.signOut();
    } catch (e) {
      print('Error deleting account: $e');
      rethrow;
    }
  }
}
