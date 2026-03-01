/// Modelo de devolución (tabla `refunds` en Supabase)
class Refund {
  final String id;
  final String orderId;
  final String? invoiceId;
  final String customerEmail;
  final String customerName;
  final String reason;
  final List<Map<String, dynamic>> returnedItems;
  final int refundAmountCents;
  final String refundMethod;
  final String status; // 'pending' | 'approved' | 'rejected'
  final DateTime createdAt;

  const Refund({
    required this.id,
    required this.orderId,
    this.invoiceId,
    required this.customerEmail,
    required this.customerName,
    required this.reason,
    required this.returnedItems,
    required this.refundAmountCents,
    required this.refundMethod,
    required this.status,
    required this.createdAt,
  });

  factory Refund.fromJson(Map<String, dynamic> json) {
    final rawItems = json['returned_items'];
    final items = <Map<String, dynamic>>[];
    if (rawItems is List) {
      for (final item in rawItems) {
        if (item is Map<String, dynamic>) items.add(item);
      }
    }

    return Refund(
      id: json['id'] as String? ?? '',
      orderId: json['order_id'] as String? ?? '',
      invoiceId: json['invoice_id'] as String?,
      customerEmail: json['customer_email'] as String? ?? '',
      customerName: json['customer_name'] as String? ?? '',
      reason: json['reason'] as String? ?? '',
      returnedItems: items,
      refundAmountCents: (json['refund_amount_cents'] as num?)?.toInt() ?? 0,
      refundMethod: json['refund_method'] as String? ?? 'original_payment',
      status: json['status'] as String? ?? 'pending',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  String get statusText {
    switch (status) {
      case 'pending':
        return 'Pendiente';
      case 'processed':
        return 'Procesada';
      case 'approved':
        return 'Aprobada';
      case 'rejected':
        return 'Rechazada';
      default:
        return status;
    }
  }
}
