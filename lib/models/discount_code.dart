/// Modelo DiscountCode - Códigos de descuento
/// Replica la funcionalidad de códigos de descuento usada en Astro
class DiscountCode {
  final String id;
  final String code;
  final int discountPercentage;
  final int? minOrderCents; // Pedido mínimo para aplicar
  final int? maxDiscountCents; // Descuento máximo
  final DateTime? validFrom;
  final DateTime? validUntil;
  final int? usageLimit; // Límite de usos totales
  final int usageCount; // Veces usado
  final bool isActive;
  final DateTime createdAt;

  DiscountCode({
    required this.id,
    required this.code,
    required this.discountPercentage,
    this.minOrderCents,
    this.maxDiscountCents,
    this.validFrom,
    this.validUntil,
    this.usageLimit,
    this.usageCount = 0,
    this.isActive = true,
    required this.createdAt,
  });

  /// Verifica si el código es válido actualmente
  bool get isValid {
    if (!isActive) return false;

    final now = DateTime.now();
    if (validFrom != null && now.isBefore(validFrom!)) return false;
    if (validUntil != null && now.isAfter(validUntil!)) return false;
    if (usageLimit != null && usageCount >= usageLimit!) return false;

    return true;
  }

  /// Verifica si el código puede aplicarse a un pedido
  bool canApplyToOrder(int orderTotalCents) {
    if (!isValid) return false;
    if (minOrderCents != null && orderTotalCents < minOrderCents!) return false;
    return true;
  }

  /// Calcula el descuento para un monto dado
  int calculateDiscount(int totalCents) {
    int discount = (totalCents * discountPercentage) ~/ 100;
    if (maxDiscountCents != null && discount > maxDiscountCents!) {
      discount = maxDiscountCents!;
    }
    return discount;
  }

  /// Descuento formateado
  String get formattedDiscount => '$discountPercentage%';

  factory DiscountCode.fromJson(Map<String, dynamic> json) {
    return DiscountCode(
      id: json['id'] as String,
      code: json['code'] as String,
      discountPercentage: json['discount_percentage'] as int,
      minOrderCents: json['min_order_cents'] as int?,
      maxDiscountCents: json['max_discount_cents'] as int?,
      validFrom: json['valid_from'] != null
          ? DateTime.parse(json['valid_from'] as String)
          : null,
      validUntil: json['valid_until'] != null
          ? DateTime.parse(json['valid_until'] as String)
          : null,
      usageLimit: json['usage_limit'] as int?,
      usageCount: json['usage_count'] as int? ?? 0,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'discount_percentage': discountPercentage,
      'min_order_cents': minOrderCents,
      'max_discount_cents': maxDiscountCents,
      'valid_from': validFrom?.toIso8601String(),
      'valid_until': validUntil?.toIso8601String(),
      'usage_limit': usageLimit,
      'usage_count': usageCount,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

/// Modelo para un descuento aplicado (guardado localmente)
class AppliedDiscount {
  final String code;
  final int percentage;

  AppliedDiscount({required this.code, required this.percentage});

  factory AppliedDiscount.fromJson(Map<String, dynamic> json) {
    return AppliedDiscount(
      code: json['code'] as String,
      percentage: json['percentage'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {'code': code, 'percentage': percentage};
  }
}
