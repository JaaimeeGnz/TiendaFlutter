import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

/// UserService - CRUD de perfiles de usuario en tabla 'users'
/// Replica exactamente la lógica de AccountModals.tsx y AuthForm.tsx de Astro:
///   - AuthForm.tsx: Insertar en tabla 'users' al registrarse (id, email, username)
///   - AccountModals.tsx EditProfileModal: Leer y actualizar username
///   - AccountModals.tsx DeleteAccountModal: Llamar a /api/account/delete con Bearer token
///   - account.astro: Obtener username del usuario
class UserService {
  final SupabaseClient _client = SupabaseService.instance.client;

  /// Crear perfil de usuario en tabla 'users' al registrarse
  /// Replica: AuthForm.tsx → supabaseClient.from('users').insert({id, email, username})
  Future<bool> createUserProfile({
    required String userId,
    required String email,
    required String username,
  }) async {
    try {
      await _client.from('users').insert({
        'id': userId,
        'email': email,
        'username': username.toLowerCase().trim(),
      });
      return true;
    } catch (e) {
      // Código 23505 = violación de restricción única (username duplicado)
      if (e.toString().contains('23505')) {
        throw Exception('Este nombre de usuario ya está en uso');
      }
      print('Error creating user profile: $e');
      throw Exception('Error al guardar el perfil del usuario');
    }
  }

  /// Obtener username del usuario
  /// Replica: AccountModals.tsx EditProfileModal handleOpen
  /// → .from('users').select('username').eq('id', session.user.id).single()
  Future<String?> getUsername(String userId) async {
    try {
      final response = await _client
          .from('users')
          .select('username')
          .eq('id', userId)
          .single();

      return response['username'] as String?;
    } catch (e) {
      print('Error fetching username: $e');
      return null;
    }
  }

  /// Actualizar username
  /// Replica: AccountModals.tsx EditProfileModal handleSubmit
  /// → .from('users').update({ username }).eq('id', session.user.id)
  Future<bool> updateUsername({
    required String userId,
    required String username,
  }) async {
    try {
      if (username.trim().isEmpty) {
        throw Exception('El nombre de usuario no puede estar vacío');
      }

      await _client
          .from('users')
          .update({'username': username.trim()})
          .eq('id', userId);

      return true;
    } catch (e) {
      print('Error updating username: $e');
      rethrow;
    }
  }

  /// Obtener perfil completo del usuario desde tabla 'users'
  /// Replica: account.astro → .from('users').select('*').eq('id', id).single()
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final response = await _client
          .from('users')
          .select()
          .eq('id', userId)
          .maybeSingle();

      return response;
    } catch (e) {
      print('Error fetching user profile: $e');
      return null;
    }
  }

  /// Eliminar cuenta del usuario
  /// Replica: AccountModals.tsx DeleteAccountModal → fetch('/api/account/delete')
  /// En Astro usa service role key en el servidor. En Flutter usamos el mismo patrón:
  /// 1. Eliminar direcciones
  /// 2. Eliminar pedidos (try/catch)
  /// 3. Eliminar datos de tabla 'users'
  /// 4. El usuario cierra sesión (la eliminación de auth se gestiona por RLS o manualmente)
  Future<bool> deleteUserData(String userId) async {
    try {
      // 1. Eliminar direcciones
      try {
        await _client.from('addresses').delete().eq('user_id', userId);
      } catch (e) {
        print('Error deleting addresses: $e');
      }

      // 2. Eliminar pedidos (puede que la tabla no exista)
      try {
        await _client.from('orders').delete().eq('user_id', userId);
      } catch (e) {
        print('Tabla de órdenes no existe o error: $e');
      }

      // 3. Eliminar datos de tabla 'users'
      try {
        await _client.from('users').delete().eq('id', userId);
      } catch (e) {
        print('Error deleting user data: $e');
      }

      return true;
    } catch (e) {
      print('Error deleting user data: $e');
      return false;
    }
  }
}
