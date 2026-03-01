import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_stripe/flutter_stripe.dart';
import '../core/constants/app_config.dart';
import '../models/cart_item.dart';

/// StripeService - Gestión de pagos con Stripe dentro de la app
/// Usa PaymentIntent + Payment Sheet para cobrar sin salir de la aplicación
class StripeService {
  static StripeService? _instance;

  StripeService._();

  factory StripeService() => instance;

  static StripeService get instance {
    _instance ??= StripeService._();
    return _instance!;
  }

  /// Inicializar Stripe con la publishable key
  static Future<void> initialize() async {
    if (!kIsWeb) {
      final key = AppConfig.stripePublicKey;
      if (key.isEmpty) {
        print('[StripeService] WARNING: STRIPE_PUBLIC_KEY está vacía');
        return;
      }
      Stripe.publishableKey = key;
      Stripe.merchantIdentifier = 'merchant.com.jgmarket';
      try {
        await Stripe.instance.applySettings();
        print('[StripeService] Stripe inicializado correctamente');
      } catch (e) {
        print('[StripeService] Error en applySettings: $e');
      }
    }
  }

  /// Crear un PaymentIntent en Stripe y devolver client_secret + customer
  Future<Map<String, dynamic>> _createPaymentIntent({
    required int amountCents,
    required String email,
    String? customerName,
  }) async {
    // 1. Buscar o crear customer
    final customerId = await _getOrCreateCustomer(email, customerName);

    // 2. Crear ephemeral key para el customer
    final ephemeralKey = await _createEphemeralKey(customerId);

    // 3. Crear PaymentIntent
    final body = {
      'amount': amountCents.toString(),
      'currency': 'eur',
      'customer': customerId,
      'payment_method_types[]': 'card',
    };

    final response = await http.post(
      Uri.parse('https://api.stripe.com/v1/payment_intents'),
      headers: {
        'Authorization': 'Bearer ${AppConfig.stripeSecretKey}',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: body,
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(
        error['error']?['message'] ?? 'Error al crear PaymentIntent',
      );
    }

    final data = jsonDecode(response.body);
    return {
      'clientSecret': data['client_secret'],
      'customerId': customerId,
      'ephemeralKey': ephemeralKey,
      'paymentIntentId': data['id'],
    };
  }

  /// Buscar o crear un Customer en Stripe por email
  Future<String> _getOrCreateCustomer(String email, String? name) async {
    // Buscar customer existente por email
    final searchResponse = await http.get(
      Uri.parse(
        'https://api.stripe.com/v1/customers?email=${Uri.encodeComponent(email)}&limit=1',
      ),
      headers: {
        'Authorization': 'Bearer ${AppConfig.stripeSecretKey}',
      },
    );

    if (searchResponse.statusCode == 200) {
      final searchData = jsonDecode(searchResponse.body);
      final customers = searchData['data'] as List;
      if (customers.isNotEmpty) {
        return customers[0]['id'] as String;
      }
    }

    // Crear nuevo customer
    final createBody = <String, String>{
      'email': email,
    };
    if (name != null && name.isNotEmpty) {
      createBody['name'] = name;
    }

    final createResponse = await http.post(
      Uri.parse('https://api.stripe.com/v1/customers'),
      headers: {
        'Authorization': 'Bearer ${AppConfig.stripeSecretKey}',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: createBody,
    );

    if (createResponse.statusCode != 200) {
      throw Exception('Error al crear customer en Stripe');
    }

    final createData = jsonDecode(createResponse.body);
    return createData['id'] as String;
  }

  /// Crear Ephemeral Key para el customer
  Future<String> _createEphemeralKey(String customerId) async {
    final response = await http.post(
      Uri.parse('https://api.stripe.com/v1/ephemeral_keys'),
      headers: {
        'Authorization': 'Bearer ${AppConfig.stripeSecretKey}',
        'Content-Type': 'application/x-www-form-urlencoded',
        'Stripe-Version': '2023-10-16',
      },
      body: {
        'customer': customerId,
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Error al crear ephemeral key');
    }

    final data = jsonDecode(response.body);
    return data['secret'] as String;
  }

  /// Procesa el pago mostrando el Payment Sheet de Stripe dentro de la app
  /// Devuelve PaymentResult con éxito, error o cancelación
  Future<PaymentResult> processPayment({
    required List<CartItem> items,
    required int totalCents,
    required String email,
    String? customerName,
    String? discountCode,
    String? addressId,
  }) async {
    try {
      if (items.isEmpty) {
        return PaymentResult.error('El carrito está vacío');
      }

      if (totalCents <= 0) {
        return PaymentResult.error('El importe debe ser mayor a 0');
      }

      // Asegurar que Stripe está inicializado (siempre aplicar settings)
      final key = AppConfig.stripePublicKey;
      if (key.isEmpty) {
        return PaymentResult.error(
          'La clave de Stripe no está configurada. Verifica el archivo .env',
        );
      }
      Stripe.publishableKey = key;
      Stripe.merchantIdentifier = 'merchant.com.jgmarket';
      await Stripe.instance.applySettings();

      // 1. Crear PaymentIntent + Customer + EphemeralKey
      final paymentData = await _createPaymentIntent(
        amountCents: totalCents,
        email: email,
        customerName: customerName,
      );

      // 2. Inicializar el Payment Sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: paymentData['clientSecret'],
          customerEphemeralKeySecret: paymentData['ephemeralKey'],
          customerId: paymentData['customerId'],
          merchantDisplayName: 'JGMarket',
          style: ThemeMode.system,
          appearance: const PaymentSheetAppearance(
            colors: PaymentSheetAppearanceColors(
              primary: Color(0xFF00BFA5),
            ),
          ),
          billingDetailsCollectionConfiguration:
              const BillingDetailsCollectionConfiguration(
            name: CollectionMode.always,
            email: CollectionMode.always,
            address: AddressCollectionMode.full,
          ),
          primaryButtonLabel: 'Pagar',
        ),
      );

      // 3. Mostrar el Payment Sheet (formulario nativo de Stripe)
      await Stripe.instance.presentPaymentSheet();

      // Si llegamos aquí, el pago fue exitoso
      return PaymentResult.success(
        paymentIntentId: paymentData['paymentIntentId'],
      );
    } on StripeException catch (e) {
      if (e.error.code == FailureCode.Canceled) {
        return PaymentResult.cancelled();
      }
      return PaymentResult.error(
        e.error.localizedMessage ?? 'Error en el pago con Stripe',
      );
    } on StripeConfigException catch (e) {
      return PaymentResult.error(
        'Error de configuración de Stripe: ${e.message}',
      );
    } catch (e) {
      return PaymentResult.error('Error al procesar el pago: $e');
    }
  }
}

/// Resultado de un pago
class PaymentResult {
  final bool success;
  final bool cancelled;
  final String? message;
  final String? paymentIntentId;

  PaymentResult._({
    required this.success,
    this.cancelled = false,
    this.message,
    this.paymentIntentId,
  });

  factory PaymentResult.success({String? paymentIntentId}) =>
      PaymentResult._(success: true, paymentIntentId: paymentIntentId);

  factory PaymentResult.error(String message) =>
      PaymentResult._(success: false, message: message);

  factory PaymentResult.cancelled() =>
      PaymentResult._(success: false, cancelled: true, message: 'Pago cancelado');
}
