/// Modelo OrderItem - Items individuales de un pedido
/// Replica la estructura usada en el checkout de Astro
class OrderItem {
  final String id;
  final String orderId;
  final String productId;
  final String name;
  final int priceCents;
  final int quantity;
  final String? size;
  final String? imageUrl;
  final DateTime createdAt;

  OrderItem({
    required this.id,
    required this.orderId,
    required this.productId,
    required this.name,
    required this.priceCents,
    required this.quantity,
    this.size,
    this.imageUrl,
    required this.createdAt,
  });

  /// Total en céntimos para este item
  int get totalCents => priceCents * quantity;

  /// Precio formateado
  String get formattedPrice => '€${(priceCents / 100).toStringAsFixed(2)}';

  /// Total formateado
  String get formattedTotal => '€${(totalCents / 100).toStringAsFixed(2)}';

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'] as String,
      orderId: json['order_id'] as String,
      productId: json['product_id'] as String,
      name: json['name'] as String,
      priceCents: json['price_cents'] as int,
      quantity: json['quantity'] as int,
      size: json['size'] as String?,
      imageUrl: json['image_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'product_id': productId,
      'name': name,
      'price_cents': priceCents,
      'quantity': quantity,
      'size': size,
      'image_url': imageUrl,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Crear desde un CartItem para el checkout
  factory OrderItem.fromCartItem({
    required String id,
    required String orderId,
    required String productId,
    required String name,
    required int priceCents,
    required int quantity,
    String? size,
    String? imageUrl,
  }) {
    return OrderItem(
      id: id,
      orderId: orderId,
      productId: productId,
      name: name,
      priceCents: priceCents,
      quantity: quantity,
      size: size,
      imageUrl: imageUrl,
      createdAt: DateTime.now(),
    );
  }
}
