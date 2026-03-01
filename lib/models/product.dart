/// Modelo SizeStock - Stock por talla (tabla product_sizes en Supabase)
class SizeStock {
  final String size;
  final int stock;

  SizeStock({required this.size, required this.stock});

  factory SizeStock.fromJson(Map<String, dynamic> json) {
    return SizeStock(
      size: json['size'] as String,
      stock: (json['stock'] as int?) ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {'size': size, 'stock': stock};
}

/// Modelo Product - Replica la estructura de la tabla 'products' en Supabase
/// Columnas según el análisis del proyecto Astro:
///   id, name, slug, description, price_cents, original_price_cents,
///   stock, category_id, brand, images, color, material, sizes, sku,
///   featured, is_active, created_at
class Product {
  final String id;
  final String name;
  final String slug;
  final String description;
  final int priceCents;
  final int? originalPriceCents;
  final int? salePriceCents;
  final int stock;
  final String categoryId;
  final List<String> images;
  final List<String> sizes;
  final List<SizeStock> sizeStocks;
  final String? color;
  final String? material;
  final String? brand;
  final bool isActive;
  final bool featured;
  final String? sku;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Product({
    required this.id,
    required this.name,
    required this.slug,
    this.description = '',
    required this.priceCents,
    this.originalPriceCents,
    this.salePriceCents,
    required this.stock,
    this.categoryId = '',
    this.images = const [],
    this.sizes = const [],
    this.sizeStocks = const [],
    this.color,
    this.material,
    this.brand,
    this.isActive = true,
    this.featured = false,
    this.sku,
    required this.createdAt,
    this.updatedAt,
  });

  /// Getter para compatibilidad - devuelve true si featured es true
  bool get isFeatured => featured;

  /// Determina si el producto está en rebajas
  bool get isOnSale {
    if (originalPriceCents != null && originalPriceCents! > priceCents) {
      return true;
    }
    if (salePriceCents != null && salePriceCents! < priceCents) {
      return true;
    }
    return false;
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
      description: (json['description'] as String?) ?? '',
      priceCents: json['price_cents'] as int,
      originalPriceCents: json['original_price_cents'] as int?,
      salePriceCents: json['sale_price_cents'] as int?,
      stock: (json['stock'] as int?) ?? 0,
      categoryId: (json['category_id'] as String?) ?? '',
      images: (json['images'] as List<dynamic>?)?.cast<String>() ?? [],
      sizes: (json['sizes'] as List<dynamic>?)?.cast<String>() ?? [],
      sizeStocks: (json['product_sizes'] as List<dynamic>?)
              ?.map((s) => SizeStock.fromJson(s as Map<String, dynamic>))
              .toList() ??
          (json['size_stocks'] as List<dynamic>?)
              ?.map((s) => SizeStock.fromJson(s as Map<String, dynamic>))
              .toList() ??
          [],
      color: json['color'] as String?,
      material: json['material'] as String?,
      brand: json['brand'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      featured: json['featured'] as bool? ?? false,
      sku: json['sku'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'description': description,
      'price_cents': priceCents,
      'original_price_cents': originalPriceCents,
      'sale_price_cents': salePriceCents,
      'stock': stock,
      'category_id': categoryId,
      'images': images,
      'sizes': sizes,
      'color': color,
      'material': material,
      'brand': brand,
      'is_active': isActive,
      'featured': featured,
      'sku': sku,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  bool get hasDiscount => originalPriceCents != null || salePriceCents != null;

  int get discountPercentage {
    if (salePriceCents != null && salePriceCents! < priceCents) {
      return ((1 - (salePriceCents! / priceCents)) * 100).round();
    }
    if (originalPriceCents != null && originalPriceCents! > priceCents) {
      return ((1 - (priceCents / originalPriceCents!)) * 100).round();
    }
    return 0;
  }

  bool get isInStock => stock > 0;

  /// Obtener stock de una talla específica
  int getStockForSize(String size) {
    try {
      return sizeStocks.firstWhere((s) => s.size == size).stock;
    } catch (_) {
      return stock; // Fallback al stock global si no hay datos por talla
    }
  }

  /// Verificar si una talla tiene stock
  bool isSizeInStock(String size) => getStockForSize(size) > 0;

  /// Stock total calculado desde sizeStocks (si disponible)
  int get totalSizeStock {
    if (sizeStocks.isEmpty) return stock;
    return sizeStocks.fold(0, (sum, s) => sum + s.stock);
  }

  Product copyWith({
    String? id,
    String? name,
    String? slug,
    String? description,
    int? priceCents,
    int? originalPriceCents,
    int? salePriceCents,
    int? stock,
    String? categoryId,
    List<String>? images,
    List<String>? sizes,
    List<SizeStock>? sizeStocks,
    String? color,
    String? material,
    String? brand,
    bool? isActive,
    bool? featured,
    String? sku,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      description: description ?? this.description,
      priceCents: priceCents ?? this.priceCents,
      originalPriceCents: originalPriceCents ?? this.originalPriceCents,
      salePriceCents: salePriceCents ?? this.salePriceCents,
      stock: stock ?? this.stock,
      categoryId: categoryId ?? this.categoryId,
      images: images ?? this.images,
      sizes: sizes ?? this.sizes,
      sizeStocks: sizeStocks ?? this.sizeStocks,
      color: color ?? this.color,
      material: material ?? this.material,
      brand: brand ?? this.brand,
      isActive: isActive ?? this.isActive,
      featured: featured ?? this.featured,
      sku: sku ?? this.sku,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
