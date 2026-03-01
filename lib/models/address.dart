class Address {
  final String id;
  final String userId;
  final String name;
  final String phone;
  final String street;
  final String number;
  final String? apartment;
  final String city;
  final String state;
  final String postalCode;
  final String country;
  final bool isDefault;
  final DateTime createdAt;
  final DateTime updatedAt;

  Address({
    required this.id,
    required this.userId,
    required this.name,
    required this.phone,
    required this.street,
    required this.number,
    this.apartment,
    required this.city,
    required this.state,
    required this.postalCode,
    required this.country,
    this.isDefault = false,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Alias para compatibilidad - province es igual a state
  String get province => state;

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String? ?? '',
      street: json['street'] as String,
      number: json['number'] as String? ?? '',
      apartment: json['apartment'] as String?,
      city: json['city'] as String,
      state: json['state'] as String? ?? json['province'] as String? ?? '',
      postalCode: json['postal_code'] as String,
      country: json['country'] as String,
      isDefault: json['is_default'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'phone': phone,
      'street': street,
      'number': number,
      'apartment': apartment,
      'city': city,
      'state': state,
      'postal_code': postalCode,
      'country': country,
      'is_default': isDefault,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  String get fullAddress {
    final apt = apartment != null && apartment!.isNotEmpty
        ? ', $apartment'
        : '';
    return '$street, $number$apt, $postalCode $city, $state';
  }
}
