/// Invoice - Modelo de factura (tabla 'invoices' en Supabase)
/// Replica la estructura de tiendaOnline/Astro
class Invoice {
  final String id;
  final String invoiceNumber;
  final String orderId;
  final String customerEmail;
  final String customerName;
  final String type; // 'invoice' | 'credit_note'
  final int subtotalCents;
  final int taxCents;
  final int totalCents;
  final String status; // 'draft' | 'issued' | 'paid' | 'cancelled'
  final DateTime issuedAt;
  final DateTime? paidAt;
  final List<Map<String, dynamic>> items;
  final String? referenceInvoiceId;
  final String? reason;

  const Invoice({
    required this.id,
    required this.invoiceNumber,
    required this.orderId,
    required this.customerEmail,
    required this.customerName,
    required this.type,
    required this.subtotalCents,
    required this.taxCents,
    required this.totalCents,
    required this.status,
    required this.issuedAt,
    this.paidAt,
    required this.items,
    this.referenceInvoiceId,
    this.reason,
  });

  factory Invoice.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    final items = <Map<String, dynamic>>[];
    if (rawItems is List) {
      for (final item in rawItems) {
        if (item is Map<String, dynamic>) items.add(item);
      }
    }

    return Invoice(
      id: json['id'] as String? ?? '',
      invoiceNumber: json['invoice_number'] as String? ?? '',
      orderId: json['order_id'] as String? ?? '',
      customerEmail: json['customer_email'] as String? ?? '',
      customerName: json['customer_name'] as String? ?? '',
      type: json['type'] as String? ?? 'invoice',
      subtotalCents: (json['subtotal_cents'] as num?)?.toInt() ?? 0,
      taxCents: (json['tax_cents'] as num?)?.toInt() ?? 0,
      totalCents: (json['total_cents'] as num?)?.toInt() ?? 0,
      status: json['status'] as String? ?? 'issued',
      issuedAt: json['issued_at'] != null
          ? DateTime.parse(json['issued_at'] as String)
          : DateTime.now(),
      paidAt: json['paid_at'] != null
          ? DateTime.parse(json['paid_at'] as String)
          : null,
      items: items,
      referenceInvoiceId: json['reference_invoice_id'] as String?,
      reason: json['reason'] as String?,
    );
  }

  String get statusDisplay {
    switch (status) {
      case 'paid':
        return 'Pagada';
      case 'issued':
        return 'Emitida';
      case 'cancelled':
        return 'Cancelada';
      case 'draft':
        return 'Borrador';
      default:
        return status;
    }
  }

  bool get isInvoice => type == 'invoice';
  bool get isCreditNote => type == 'credit_note';
}
