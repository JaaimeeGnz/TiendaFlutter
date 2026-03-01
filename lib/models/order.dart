import 'address.dart';

/// OrderItem - Representa un item en un pedido
class OrderItem {
  final String id;
  final String orderId;
  final String productId;
  final String productName;
  final String? productImage;
  final int quantity;
  final int priceCents;
  final String? size;

  OrderItem({
    required this.id,
    required this.orderId,
    required this.productId,
    required this.productName,
    this.productImage,
    required this.quantity,
    required this.priceCents,
    this.size,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: (json['id'] ?? '') as String,
      orderId: (json['order_id'] ?? '') as String,
      productId: (json['product_id'] ?? '') as String,
      productName: (json['product_name'] ?? 'Producto') as String,
      productImage: json['product_image'] as String?,
      quantity: (json['quantity'] as int?) ?? 1,
      priceCents: (json['price_cents'] as int?) ?? 0,
      size: json['size'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'product_id': productId,
      'product_name': productName,
      'product_image': productImage,
      'quantity': quantity,
      'price_cents': priceCents,
      'size': size,
    };
  }
}

/// Order - Representa un pedido completo
class Order {
  final String id;
  final String userId;
  final String? userEmail;
  final String? addressId;
  final String orderNumber;
  final int totalCents;
  final int shippingCents;
  final int? discountCents;
  final String? discountCode;
  final String status;
  final String? paymentMethod;
  final String? stripePaymentIntentId;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Relaciones cargadas
  final List<OrderItem> items;
  final Address? shippingAddress;

  Order({
    required this.id,
    required this.userId,
    this.userEmail,
    this.addressId,
    required this.orderNumber,
    required this.totalCents,
    this.shippingCents = 0,
    this.discountCents,
    this.discountCode,
    this.status = 'pending',
    this.paymentMethod,
    this.stripePaymentIntentId,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.items = const [],
    this.shippingAddress,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    List<OrderItem> orderItems = [];
    if (json['order_items'] != null) {
      orderItems = (json['order_items'] as List)
          .map((item) => OrderItem.fromJson(item))
          .toList();
    }

    Address? address;
    if (json['addresses'] != null) {
      address = Address.fromJson(json['addresses']);
    }

    return Order(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      userEmail: (json['customer_email'] ?? json['user_email']) as String?,
      addressId: json['address_id'] as String?,
      orderNumber: json['order_number'] as String,
      totalCents: json['total_cents'] as int,
      shippingCents: json['shipping_cents'] as int? ?? 0,
      discountCents: json['discount_cents'] as int?,
      discountCode: json['discount_code'] as String?,
      status: json['status'] as String? ?? 'pending',
      paymentMethod: json['payment_method'] as String?,
      stripePaymentIntentId: json['stripe_payment_intent_id'] as String?,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      items: orderItems,
      shippingAddress: address,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'user_email': userEmail,
      'address_id': addressId,
      'order_number': orderNumber,
      'total_cents': totalCents,
      'shipping_cents': shippingCents,
      'discount_cents': discountCents,
      'discount_code': discountCode,
      'status': status,
      'payment_method': paymentMethod,
      'stripe_payment_intent_id': stripePaymentIntentId,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Método copyWith para crear copias con campos modificados
  Order copyWith({
    String? id,
    String? userId,
    String? userEmail,
    String? addressId,
    String? orderNumber,
    int? totalCents,
    int? shippingCents,
    int? discountCents,
    String? discountCode,
    String? status,
    String? paymentMethod,
    String? stripePaymentIntentId,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<OrderItem>? items,
    Address? shippingAddress,
  }) {
    return Order(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userEmail: userEmail ?? this.userEmail,
      addressId: addressId ?? this.addressId,
      orderNumber: orderNumber ?? this.orderNumber,
      totalCents: totalCents ?? this.totalCents,
      shippingCents: shippingCents ?? this.shippingCents,
      discountCents: discountCents ?? this.discountCents,
      discountCode: discountCode ?? this.discountCode,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      stripePaymentIntentId:
          stripePaymentIntentId ?? this.stripePaymentIntentId,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      items: items ?? this.items,
      shippingAddress: shippingAddress ?? this.shippingAddress,
    );
  }

  String get statusText {
    switch (status) {
      case 'pending':
        return 'Pendiente';
      case 'paid':
        return 'Pagado';
      case 'shipped':
        return 'Enviado';
      case 'delivered':
        return 'Entregado';
      case 'cancelled':
        return 'Cancelado';
      default:
        return 'Desconocido';
    }
  }
}
