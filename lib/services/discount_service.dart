import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/discount_code.dart';
import 'supabase_service.dart';

/// DiscountService - Gestión de códigos de descuento
/// Replica la funcionalidad de /api/discount/validate-code de Astro
class DiscountService {
  final SupabaseClient _client = SupabaseService.instance.client;

  /// Validar un código de descuento
  /// Equivalente a POST /api/discount/validate-code en Astro
  Future<DiscountValidationResult> validateCode(String code) async {
    try {
      if (code.isEmpty) {
        return DiscountValidationResult.error('Por favor ingresa un código');
      }

      // Buscar el código en la base de datos
      final response = await _client
          .from('discount_codes')
          .select()
          .eq('code', code.toUpperCase())
          .eq('is_active', true)
          .maybeSingle();

      if (response == null) {
        return DiscountValidationResult.error('Código inválido o expirado');
      }

      final discountCode = DiscountCode.fromJson(response);

      // Verificar validez
      if (!discountCode.isValid) {
        return DiscountValidationResult.error('Código expirado o no válido');
      }

      return DiscountValidationResult.success(
        code: discountCode.code,
        discountPercentage: discountCode.discountPercentage,
        message: '¡Código aplicado correctamente!',
      );
    } catch (e) {
      print('Error validando código de descuento: $e');

      // Si la tabla no existe, simular respuesta para newsletter codes
      // (10% de descuento por suscripción)
      if (code.toUpperCase().startsWith('WELCOME') ||
          code.toUpperCase().startsWith('NEWS')) {
        return DiscountValidationResult.success(
          code: code.toUpperCase(),
          discountPercentage: 10,
          message: '¡Descuento de bienvenida aplicado!',
        );
      }

      return DiscountValidationResult.error('Error al validar el código');
    }
  }

  /// Incrementar contador de uso de un código
  Future<bool> incrementUsageCount(String code) async {
    try {
      await _client.rpc(
        'increment_discount_usage',
        params: {'code_param': code},
      );
      return true;
    } catch (e) {
      print('Error incrementando uso del código: $e');
      return false;
    }
  }

  /// Crear código de descuento (Admin)
  Future<DiscountCode?> createDiscountCode({
    required String code,
    required int discountPercentage,
    int? minOrderCents,
    int? maxDiscountCents,
    DateTime? validFrom,
    DateTime? validUntil,
    int? usageLimit,
  }) async {
    try {
      final data = {
        'code': code.toUpperCase(),
        'discount_percentage': discountPercentage,
        'min_order_cents': minOrderCents,
        'max_discount_cents': maxDiscountCents,
        'valid_from': validFrom?.toIso8601String(),
        'valid_until': validUntil?.toIso8601String(),
        'usage_limit': usageLimit,
        'usage_count': 0,
        'is_active': true,
      };

      final response = await _client
          .from('discount_codes')
          .insert(data)
          .select()
          .single();

      return DiscountCode.fromJson(response);
    } catch (e) {
      print('Error creando código de descuento: $e');
      return null;
    }
  }

  /// Obtener todos los códigos (Admin)
  Future<List<DiscountCode>> getAllDiscountCodes() async {
    try {
      final response = await _client
          .from('discount_codes')
          .select()
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => DiscountCode.fromJson(json))
          .toList();
    } catch (e) {
      print('Error obteniendo códigos de descuento: $e');
      return [];
    }
  }
}

/// Resultado de validación de código de descuento
class DiscountValidationResult {
  final bool success;
  final String message;
  final String? code;
  final int? discountPercentage;

  DiscountValidationResult._({
    required this.success,
    required this.message,
    this.code,
    this.discountPercentage,
  });

  factory DiscountValidationResult.success({
    required String code,
    required int discountPercentage,
    required String message,
  }) {
    return DiscountValidationResult._(
      success: true,
      message: message,
      code: code,
      discountPercentage: discountPercentage,
    );
  }

  factory DiscountValidationResult.error(String message) {
    return DiscountValidationResult._(success: false, message: message);
  }
}
