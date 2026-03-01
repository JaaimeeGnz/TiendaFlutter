import 'package:hive/hive.dart';

part 'cart_item.g.dart';

@HiveType(typeId: 0)
class CartItem extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String slug;

  @HiveField(3)
  final int priceCents;

  @HiveField(4)
  int quantity;

  @HiveField(5)
  final String? size;

  @HiveField(6)
  final String? imageUrl;

  @HiveField(7)
  final int stock;

  CartItem({
    required this.id,
    required this.name,
    required this.slug,
    required this.priceCents,
    required this.quantity,
    this.size,
    this.imageUrl,
    required this.stock,
  });

  int get totalCents => priceCents * quantity;

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
      priceCents: json['price_cents'] as int,
      quantity: json['quantity'] as int,
      size: json['size'] as String?,
      imageUrl: json['image_url'] as String?,
      stock: json['stock'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'price_cents': priceCents,
      'quantity': quantity,
      'size': size,
      'image_url': imageUrl,
      'stock': stock,
    };
  }

  CartItem copyWith({
    String? id,
    String? name,
    String? slug,
    int? priceCents,
    int? quantity,
    String? size,
    String? imageUrl,
    int? stock,
  }) {
    return CartItem(
      id: id ?? this.id,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      priceCents: priceCents ?? this.priceCents,
      quantity: quantity ?? this.quantity,
      size: size ?? this.size,
      imageUrl: imageUrl ?? this.imageUrl,
      stock: stock ?? this.stock,
    );
  }
}
