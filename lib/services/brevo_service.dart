import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/app_config.dart';
import '../models/order.dart';

/// BrevoService - Envío de emails transaccionales via Brevo (Sendinblue) API
/// Replica el enfoque de tiendaOnline/fashionmarket/src/lib/email.ts
class BrevoService {
  static const String _apiUrl = 'https://api.brevo.com/v3/smtp/email';
  static const String _senderEmail = 'jaimechipiona2006@gmail.com';
  static const String _senderName = 'JGMarket';

  /// Enviar email genérico via Brevo API
  static Future<bool> _sendEmail({
    required String to,
    required String subject,
    required String htmlContent,
  }) async {
    final apiKey = AppConfig.brevoApiKey.trim();
    if (apiKey.isEmpty) {
      print('⚠️ BREVO_API_KEY no configurada');
      return false;
    }

    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'accept': 'application/json',
          'api-key': apiKey,
          'content-type': 'application/json',
        },
        body: json.encode({
          'sender': {'name': _senderName, 'email': _senderEmail},
          'to': [
            {'email': to}
          ],
          'subject': subject,
          'htmlContent': htmlContent,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ Email enviado correctamente a $to');
        return true;
      } else {
        print('❌ Error Brevo: ${response.statusCode} ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ Error enviando email: $e');
      return false;
    }
  }

  // ─── WRAPPER HEADER/FOOTER ────────────────────────────────────────────

  static String _wrapEmail(String title, String bodyContent) {
    return '''
<div style="font-family: 'Segoe UI', Arial, sans-serif; max-width: 600px; margin: 0 auto; background-color: #f9fafb;">
  <div style="background: linear-gradient(135deg, #dc2626, #991b1b); color: white; padding: 30px; text-align: center;">
    <h1 style="margin: 0; font-size: 28px; font-weight: 900;">JGMARKET</h1>
    <p style="margin: 8px 0 0 0; font-size: 14px; opacity: 0.9;">$title</p>
  </div>
  <div style="padding: 30px; background-color: white;">
    $bodyContent
  </div>
  <div style="background-color: #1f2937; color: #9ca3af; padding: 20px; text-align: center; font-size: 12px;">
    <p style="margin: 0;">\u00a9 2026 JGMarket. Todos los derechos reservados.</p>
    <p style="margin: 4px 0 0 0;">Gracias por tu confianza</p>
  </div>
</div>
''';
  }

  // ─── 1. EMAIL: PERFIL EDITADO ─────────────────────────────────────────

  /// Envía confirmación cuando el usuario edita datos de su perfil
  static Future<bool> sendProfileUpdatedEmail({
    required String email,
    required String changeType,
    String? userName,
  }) async {
    final changeLabels = {
      'name': 'nombre de usuario',
      'email': 'correo electrónico',
      'password': 'contraseña',
      'photo': 'foto de perfil',
    };
    final changeLabel = changeLabels[changeType] ?? changeType;

    final body = '''
<div style="text-align: center; margin-bottom: 24px;">
  <div style="display: inline-block; width: 60px; height: 60px; background-color: #eff6ff; border-radius: 50%; line-height: 60px; font-size: 28px;">🔒</div>
</div>
<h2 style="color: #1f2937; text-align: center; margin-top: 0; font-size: 22px;">Perfil Actualizado</h2>
<p style="color: #4b5563; line-height: 1.6; text-align: center;">
  Hola <strong>${userName ?? 'Cliente'}</strong>, tu <strong>$changeLabel</strong> ha sido actualizado/a correctamente.
</p>
<div style="background-color: #f0fdf4; border: 1px solid #bbf7d0; border-radius: 8px; padding: 14px; margin: 20px 0; text-align: center;">
  <p style="margin: 0; font-size: 14px; color: #166534;">
    ✅ Cambio realizado con éxito
  </p>
</div>
<div style="background-color: #fef2f2; border: 1px solid #fecaca; border-radius: 8px; padding: 14px; margin-top: 20px;">
  <p style="margin: 0; font-size: 13px; color: #991b1b;">
    <strong>⚠️ Seguridad:</strong> Si no has realizado este cambio, contacta con nosotros inmediatamente.
  </p>
</div>
''';

    return _sendEmail(
      to: email,
      subject: 'Perfil Actualizado - JGMarket',
      htmlContent: _wrapEmail('Actualización de Perfil', body),
    );
  }

  // ─── 2. EMAIL: PEDIDO REALIZADO ────────────────────────────────────────

  /// Envía confirmación de pedido al cliente
  static Future<bool> sendOrderConfirmationEmail({
    required String email,
    required String orderNumber,
    required int totalCents,
    required List<OrderItem> items,
    String? customerName,
    int? discountCents,
  }) async {
    final totalFormatted = (totalCents / 100).toStringAsFixed(2);

    final itemsHtml = items.map((item) {
      final itemTotal =
          ((item.priceCents * item.quantity) / 100).toStringAsFixed(2);
      return '''
<tr>
  <td style="padding: 10px 16px; border-bottom: 1px solid #f3f4f6; font-size: 14px;">
    ${item.productName}${item.size != null ? ' <span style="color: #9ca3af;">(Talla: ${item.size})</span>' : ''}
  </td>
  <td style="padding: 10px 16px; border-bottom: 1px solid #f3f4f6; font-size: 14px; text-align: center;">${item.quantity}</td>
  <td style="padding: 10px 16px; border-bottom: 1px solid #f3f4f6; font-size: 14px; text-align: right; font-weight: 600;">$itemTotal\u20ac</td>
</tr>
''';
    }).join('');

    final discountHtml = (discountCents != null && discountCents > 0)
        ? '''
<div style="text-align: center; margin: 8px 0;">
  <span style="background-color: #f0fdf4; padding: 4px 12px; border-radius: 12px; font-size: 13px; color: #166534;">
    Descuento aplicado: -${(discountCents / 100).toStringAsFixed(2)}\u20ac
  </span>
</div>
'''
        : '';

    final body = '''
<div style="text-align: center; margin-bottom: 24px;">
  <div style="display: inline-block; width: 60px; height: 60px; background-color: #f0fdf4; border-radius: 50%; line-height: 60px; font-size: 28px;">🛍️</div>
</div>
<h2 style="color: #1f2937; text-align: center; margin-top: 0; font-size: 22px;">¡Pedido Confirmado!</h2>
<p style="color: #4b5563; line-height: 1.6; text-align: center;">
  Hola <strong>${customerName ?? 'Cliente'}</strong>, hemos recibido tu pedido correctamente.
</p>
<div style="text-align: center; margin: 16px 0;">
  <span style="background-color: #f3f4f6; padding: 6px 16px; border-radius: 20px; font-size: 13px; color: #6b7280;">
    Pedido: <strong>$orderNumber</strong>
  </span>
</div>
<table style="width: 100%; border-collapse: collapse; margin: 20px 0;">
  <thead>
    <tr style="background-color: #dc2626;">
      <th style="padding: 10px 16px; text-align: left; color: white; font-size: 12px; text-transform: uppercase;">Producto</th>
      <th style="padding: 10px 16px; text-align: center; color: white; font-size: 12px; text-transform: uppercase;">Cant.</th>
      <th style="padding: 10px 16px; text-align: right; color: white; font-size: 12px; text-transform: uppercase;">Importe</th>
    </tr>
  </thead>
  <tbody>
    $itemsHtml
  </tbody>
</table>
$discountHtml
<div style="background-color: #f0fdf4; border: 2px solid #86efac; border-radius: 8px; padding: 16px; text-align: center; margin: 20px 0;">
  <p style="margin: 0; font-size: 13px; color: #166534;">Total del pedido</p>
  <p style="margin: 8px 0 0 0; font-size: 28px; font-weight: 900; color: #16a34a;">$totalFormatted\u20ac</p>
</div>
<div style="background-color: #eff6ff; border: 1px solid #bfdbfe; border-radius: 8px; padding: 14px; margin-top: 20px;">
  <p style="margin: 0; font-size: 13px; color: #1e40af;">
    <strong>ℹ️ Información:</strong> Te enviaremos un email cuando tu pedido cambie de estado. Puedes seguir el estado de tu pedido desde la app.
  </p>
</div>
''';

    return _sendEmail(
      to: email,
      subject: 'Pedido Confirmado - JGMarket | $orderNumber',
      htmlContent: _wrapEmail('Confirmación de Pedido', body),
    );
  }

  // ─── 3. EMAIL: CAMBIO DE ESTADO DEL PEDIDO ────────────────────────────

  /// Envía notificación cuando el admin cambia el estado del pedido
  static Future<bool> sendOrderStatusChangedEmail({
    required String email,
    required String orderNumber,
    required String newStatus,
    String? customerName,
    int? totalCents,
  }) async {
    final statusLabels = {
      'pending': 'Pendiente',
      'paid': 'Pagado',
      'shipped': 'Enviado',
      'delivered': 'Entregado',
      'cancelled': 'Cancelado',
    };

    final statusColors = {
      'pending': '#f59e0b',
      'paid': '#3b82f6',
      'shipped': '#8b5cf6',
      'delivered': '#16a34a',
      'cancelled': '#dc2626',
    };

    final statusIcons = {
      'pending': '⏳',
      'paid': '💳',
      'shipped': '🚚',
      'delivered': '✅',
      'cancelled': '❌',
    };

    final statusText = statusLabels[newStatus] ?? newStatus;
    final statusColor = statusColors[newStatus] ?? '#6b7280';
    final statusIcon = statusIcons[newStatus] ?? '📦';

    final statusMessages = {
      'pending': 'Tu pedido está pendiente de procesamiento.',
      'paid': 'El pago de tu pedido ha sido confirmado.',
      'shipped': 'Tu pedido ha sido enviado. ¡Pronto lo recibirás!',
      'delivered':
          'Tu pedido ha sido entregado. ¡Esperamos que lo disfrutes!',
      'cancelled': 'Tu pedido ha sido cancelado.',
    };
    final statusMessage = statusMessages[newStatus] ?? 'El estado de tu pedido ha cambiado.';

    final totalHtml = (totalCents != null)
        ? '''
<p style="text-align: center; font-size: 14px; color: #6b7280; margin-top: 12px;">
  Total del pedido: <strong>${(totalCents / 100).toStringAsFixed(2)}\u20ac</strong>
</p>
'''
        : '';

    final body = '''
<div style="text-align: center; margin-bottom: 24px;">
  <div style="display: inline-block; width: 60px; height: 60px; background-color: ${statusColor}20; border-radius: 50%; line-height: 60px; font-size: 28px;">$statusIcon</div>
</div>
<h2 style="color: #1f2937; text-align: center; margin-top: 0; font-size: 22px;">Estado del Pedido Actualizado</h2>
<p style="color: #4b5563; line-height: 1.6; text-align: center;">
  Hola <strong>${customerName ?? 'Cliente'}</strong>, el estado de tu pedido ha cambiado.
</p>
<div style="text-align: center; margin: 16px 0;">
  <span style="background-color: #f3f4f6; padding: 6px 16px; border-radius: 20px; font-size: 13px; color: #6b7280;">
    Pedido: <strong>$orderNumber</strong>
  </span>
</div>
<div style="background-color: ${statusColor}10; border: 2px solid ${statusColor}40; border-radius: 8px; padding: 20px; text-align: center; margin: 20px 0;">
  <p style="margin: 0; font-size: 14px; color: #6b7280;">Nuevo estado</p>
  <p style="margin: 8px 0 0 0; font-size: 24px; font-weight: 900; color: $statusColor;">$statusIcon $statusText</p>
</div>
<p style="color: #4b5563; line-height: 1.6; text-align: center;">$statusMessage</p>
$totalHtml
''';

    return _sendEmail(
      to: email,
      subject: 'Pedido $statusText - JGMarket | $orderNumber',
      htmlContent: _wrapEmail('Actualización de Pedido', body),
    );
  }

  // ─── 4. EMAIL: DEVOLUCIÓN PROCESADA ────────────────────────────────────

  /// Envía confirmación de devolución al cliente
  static Future<bool> sendRefundConfirmationEmail({
    required String email,
    required String orderNumber,
    required int refundAmountCents,
    required String reason,
    required List<OrderItem> items,
    String? customerName,
  }) async {
    final reasonLabels = {
      'defective': 'Producto defectuoso o dañado',
      'wrong_size': 'Talla incorrecta',
      'not_as_described': 'No coincide con la descripción',
      'wrong_product': 'Recibí un producto equivocado',
      'not_satisfied': 'No estoy satisfecho con la calidad',
      'other': 'Otro motivo',
    };
    final reasonText = reasonLabels[reason] ?? reason;
    final refundFormatted = (refundAmountCents / 100).toStringAsFixed(2);

    final itemsHtml = items.map((item) {
      final itemTotal =
          ((item.priceCents * item.quantity) / 100).toStringAsFixed(2);
      return '''
<tr>
  <td style="padding: 10px 16px; border-bottom: 1px solid #f3f4f6; font-size: 14px;">
    ${item.productName}${item.size != null ? ' <span style="color: #9ca3af;">(Talla: ${item.size})</span>' : ''}
  </td>
  <td style="padding: 10px 16px; border-bottom: 1px solid #f3f4f6; font-size: 14px; text-align: center;">${item.quantity}</td>
  <td style="padding: 10px 16px; border-bottom: 1px solid #f3f4f6; font-size: 14px; text-align: right; font-weight: 600;">$itemTotal\u20ac</td>
</tr>
''';
    }).join('');

    final body = '''
<div style="text-align: center; margin-bottom: 24px;">
  <div style="display: inline-block; width: 60px; height: 60px; background-color: #fff7ed; border-radius: 50%; line-height: 60px; font-size: 28px;">✅</div>
</div>
<h2 style="color: #1f2937; text-align: center; margin-top: 0; font-size: 22px;">Devolución Procesada</h2>
<p style="color: #4b5563; line-height: 1.6; text-align: center;">
  Hola <strong>${customerName ?? 'Cliente'}</strong>, tu devolución ha sido procesada correctamente.
</p>
<div style="text-align: center; margin: 16px 0;">
  <span style="background-color: #f3f4f6; padding: 6px 16px; border-radius: 20px; font-size: 13px; color: #6b7280;">
    Pedido: <strong>$orderNumber</strong>
  </span>
</div>
<div style="background-color: #fff7ed; border: 1px solid #fed7aa; border-radius: 8px; padding: 14px; margin: 20px 0;">
  <p style="margin: 0; font-size: 13px; color: #9a3412;">
    <strong>Motivo:</strong> $reasonText
  </p>
</div>
<table style="width: 100%; border-collapse: collapse; margin: 20px 0;">
  <thead>
    <tr style="background-color: #ea580c;">
      <th style="padding: 10px 16px; text-align: left; color: white; font-size: 12px; text-transform: uppercase;">Producto</th>
      <th style="padding: 10px 16px; text-align: center; color: white; font-size: 12px; text-transform: uppercase;">Cant.</th>
      <th style="padding: 10px 16px; text-align: right; color: white; font-size: 12px; text-transform: uppercase;">Importe</th>
    </tr>
  </thead>
  <tbody>
    $itemsHtml
  </tbody>
</table>
<div style="background-color: #fef2f2; border: 2px solid #fca5a5; border-radius: 8px; padding: 16px; text-align: center; margin: 20px 0;">
  <p style="margin: 0; font-size: 13px; color: #991b1b;">Total a reembolsar</p>
  <p style="margin: 8px 0 0 0; font-size: 28px; font-weight: 900; color: #dc2626;">$refundFormatted\u20ac</p>
  <p style="margin: 8px 0 0 0; font-size: 12px; color: #991b1b;">El reembolso se procesará en 5-7 días hábiles</p>
</div>
<div style="background-color: #eff6ff; border: 1px solid #bfdbfe; border-radius: 8px; padding: 14px; margin-top: 20px;">
  <p style="margin: 0; font-size: 13px; color: #1e40af;">
    <strong>ℹ️ Información:</strong> El reembolso se realizará al método de pago original utilizado en la compra.
    Si tienes alguna duda, no dudes en contactarnos.
  </p>
</div>
''';

    return _sendEmail(
      to: email,
      subject:
          'Devolución Procesada - JGMarket | Pedido $orderNumber',
      htmlContent: _wrapEmail('Confirmación de Devolución', body),
    );
  }

  // ─── 5. EMAIL: PEDIDO CANCELADO ────────────────────────────────────────

  /// Envía confirmación de cancelación de pedido al cliente
  static Future<bool> sendOrderCancelledEmail({
    required String email,
    required String orderNumber,
    String? customerName,
    int? totalCents,
    String? reason,
  }) async {
    final totalHtml = (totalCents != null)
        ? '''
<p style="text-align: center; font-size: 14px; color: #6b7280; margin-top: 12px;">
  Importe del pedido: <strong>${(totalCents / 100).toStringAsFixed(2)}\u20ac</strong>
</p>
'''
        : '';

    final reasonHtml = (reason != null && reason.isNotEmpty)
        ? '''
<div style="background-color: #fff7ed; border: 1px solid #fed7aa; border-radius: 8px; padding: 14px; margin: 20px 0;">
  <p style="margin: 0; font-size: 13px; color: #9a3412;">
    <strong>Motivo:</strong> $reason
  </p>
</div>
'''
        : '';

    final body = '''
<div style="text-align: center; margin-bottom: 24px;">
  <div style="display: inline-block; width: 60px; height: 60px; background-color: #fef2f2; border-radius: 50%; line-height: 60px; font-size: 28px;">❌</div>
</div>
<h2 style="color: #1f2937; text-align: center; margin-top: 0; font-size: 22px;">Pedido Cancelado</h2>
<p style="color: #4b5563; line-height: 1.6; text-align: center;">
  Hola <strong>${customerName ?? 'Cliente'}</strong>, tu pedido ha sido cancelado.
</p>
<div style="text-align: center; margin: 16px 0;">
  <span style="background-color: #f3f4f6; padding: 6px 16px; border-radius: 20px; font-size: 13px; color: #6b7280;">
    Pedido: <strong>$orderNumber</strong>
  </span>
</div>
$reasonHtml
$totalHtml
<div style="background-color: #eff6ff; border: 1px solid #bfdbfe; border-radius: 8px; padding: 14px; margin-top: 20px;">
  <p style="margin: 0; font-size: 13px; color: #1e40af;">
    <strong>ℹ️ Información:</strong> Si se realizó un cobro, el reembolso se procesará automáticamente en 5-7 días hábiles al método de pago original.
  </p>
</div>
''';

    return _sendEmail(
      to: email,
      subject: 'Pedido Cancelado - JGMarket | $orderNumber',
      htmlContent: _wrapEmail('Pedido Cancelado', body),
    );
  }
}
