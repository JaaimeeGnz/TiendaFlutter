import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/contact_message.dart';
import 'supabase_service.dart';

/// ContactMessageService - CRUD para la tabla 'contact_messages'
/// Replica la funcionalidad de api/contact/submit.ts y api/admin/messages.ts de Astro
class ContactMessageService {
  final SupabaseClient _client = SupabaseService.instance.client;

  /// Enviar un nuevo mensaje de contacto/reporte
  /// Replica: api/contact/submit.ts → supabase.from('contact_messages').insert(...)
  Future<bool> submitReport({
    required String name,
    required String email,
    required String subject,
    required String message,
  }) async {
    try {
      await _client.from('contact_messages').insert(
        ContactMessage.toInsertJson(
          name: name,
          email: email,
          subject: subject,
          message: message,
        ),
      );
      return true;
    } catch (e) {
      print('Error submitting contact message: $e');
      return false;
    }
  }

  /// Obtener todos los mensajes (para admin)
  /// Replica: api/admin/messages.ts GET → supabase.from('contact_messages').select('*')
  Future<List<ContactMessage>> getAllMessages() async {
    try {
      final response = await _client
          .from('contact_messages')
          .select('*')
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => ContactMessage.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching contact messages: $e');
      return [];
    }
  }

  /// Actualizar estado de un mensaje (admin)
  /// Replica: api/admin/messages/[id].ts PUT
  Future<bool> updateMessageStatus(String messageId, String status, {String? adminNotes}) async {
    try {
      final updateData = <String, dynamic>{
        'status': status,
        'updated_at': DateTime.now().toIso8601String(),
      };
      if (adminNotes != null) {
        updateData['admin_notes'] = adminNotes;
      }

      await _client
          .from('contact_messages')
          .update(updateData)
          .eq('id', messageId);

      return true;
    } catch (e) {
      print('Error updating message status: $e');
      return false;
    }
  }

  /// Eliminar un mensaje (admin)
  /// Replica: api/admin/messages/[id].ts DELETE
  Future<bool> deleteMessage(String messageId) async {
    try {
      await _client
          .from('contact_messages')
          .delete()
          .eq('id', messageId);

      return true;
    } catch (e) {
      print('Error deleting message: $e');
      return false;
    }
  }

  /// Contar mensajes nuevos (para badge en admin)
  Future<int> getNewMessagesCount() async {
    try {
      final response = await _client
          .from('contact_messages')
          .select('id')
          .eq('status', 'new');

      return (response as List).length;
    } catch (e) {
      print('Error counting new messages: $e');
      return 0;
    }
  }
}
