import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/newsletter_subscription.dart';
import 'supabase_service.dart';

/// NewsletterService - Gestión de suscripciones al newsletter
/// Replica EXACTAMENTE la lógica de lib/newsletter.ts de tiendaOnline (Astro):
///   - Tabla: newsletter_subscribers (email, discount_code, discount_percentage, is_active)
///   - Tabla: discount_codes (code, discount_type, discount_value, valid_from, valid_until, is_active)
///   - Genera código único tipo SAVE2026XXXX
///   - Si el email ya existe → devuelve el mismo código
///   - Código válido por 30 días
class NewsletterService {
  final SupabaseClient _client = SupabaseService.instance.client;

  /// Genera un código de descuento único tipo SAVE2026XXXX
  /// Replica: newsletter.ts → generateDiscountCode()
  String _generateDiscountCode() {
    final year = DateTime.now().year;
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    final randomChars = String.fromCharCodes(
      Iterable.generate(4, (_) => chars.codeUnitAt(random.nextInt(chars.length))),
    );
    return 'SAVE$year$randomChars';
  }

  /// Suscribir un email al newsletter y generar código de descuento
  /// Replica EXACTAMENTE: newsletter.ts → subscribeToNewsletter()
  Future<NewsletterResult> subscribe({
    required String email,
    int discountPercentage = 10,
  }) async {
    try {
      // Validar email
      final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
      if (!emailRegex.hasMatch(email)) {
        return NewsletterResult.error('Email inválido');
      }

      // Generar código único (evitar duplicados)
      String discountCode = _generateDiscountCode();
      int attempts = 0;
      const maxAttempts = 5;

      while (attempts < maxAttempts) {
        final existing = await _client
            .from('newsletter_subscribers')
            .select('id')
            .eq('discount_code', discountCode)
            .maybeSingle();

        if (existing == null) break;
        discountCode = _generateDiscountCode();
        attempts++;
      }

      if (attempts >= maxAttempts) {
        return NewsletterResult.error('Error generando código');
      }

      // Intentar insertar suscriptor
      try {
        await _client.from('newsletter_subscribers').insert({
          'email': email.trim().toLowerCase(),
          'discount_code': discountCode,
          'discount_percentage': discountPercentage,
          'is_active': true,
        });
      } catch (e) {
        // Si el email ya existe (código 23505), devolver el código existente
        if (e.toString().contains('23505') || e.toString().contains('duplicate')) {
          final existing = await _client
              .from('newsletter_subscribers')
              .select('discount_code')
              .eq('email', email.trim().toLowerCase())
              .maybeSingle();

          if (existing != null) {
            return NewsletterResult.success(
              message: 'Ya estabas suscrito a nuestra newsletter',
              discountCode: existing['discount_code'] as String,
              discountPercentage: discountPercentage,
            );
          }
        }
        return NewsletterResult.error('Error en la suscripción');
      }

      // Crear el código en la tabla discount_codes (válido 30 días)
      final now = DateTime.now();
      final validUntil = now.add(const Duration(days: 30));

      try {
        await _client.from('discount_codes').insert({
          'code': discountCode,
          'discount_type': 'percentage',
          'discount_value': discountPercentage,
          'valid_from': now.toIso8601String(),
          'valid_until': validUntil.toIso8601String(),
          'max_uses': null,
          'is_active': true,
          'created_by': 'newsletter_system',
        });
      } catch (e) {
        print('Warning: Error inserting discount_code (may already exist): $e');
      }

      return NewsletterResult.success(
        message:
            '¡Bienvenido! Usa el código $discountCode para obtener un $discountPercentage% de descuento',
        discountCode: discountCode,
        discountPercentage: discountPercentage,
      );
    } catch (e) {
      print('Error en suscripción newsletter: $e');
      return NewsletterResult.error('Error procesando tu suscripción');
    }
  }

  /// Cancelar suscripción
  Future<bool> unsubscribe(String email) async {
    try {
      await _client
          .from('newsletter_subscribers')
          .update({'is_active': false})
          .eq('email', email.toLowerCase());
      return true;
    } catch (e) {
      print('Error cancelando suscripción: $e');
      return false;
    }
  }

  /// Verificar si un email está suscrito
  Future<bool> isSubscribed(String email) async {
    try {
      final response = await _client
          .from('newsletter_subscribers')
          .select('id')
          .eq('email', email.toLowerCase())
          .eq('is_active', true)
          .maybeSingle();
      return response != null;
    } catch (e) {
      return false;
    }
  }

  /// Obtener todas las suscripciones (Admin)
  Future<List<NewsletterSubscription>> getAllSubscriptions() async {
    try {
      final response = await _client
          .from('newsletter_subscribers')
          .select()
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => NewsletterSubscription.fromJson(json))
          .toList();
    } catch (e) {
      print('Error obteniendo suscripciones: $e');
      return [];
    }
  }
}

/// Resultado de operación de newsletter
class NewsletterResult {
  final bool success;
  final String message;
  final String? discountCode;
  final int? discountPercentage;

  NewsletterResult._({
    required this.success,
    required this.message,
    this.discountCode,
    this.discountPercentage,
  });

  factory NewsletterResult.success({
    required String message,
    String? discountCode,
    int? discountPercentage,
  }) {
    return NewsletterResult._(
      success: true,
      message: message,
      discountCode: discountCode,
      discountPercentage: discountPercentage,
    );
  }

  factory NewsletterResult.error(String message) {
    return NewsletterResult._(success: false, message: message);
  }
}
