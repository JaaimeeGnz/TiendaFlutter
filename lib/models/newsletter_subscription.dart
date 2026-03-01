/// Modelo NewsletterSubscription - Suscripciones al newsletter
/// Replica la funcionalidad de newsletter popup de Astro
class NewsletterSubscription {
  final String id;
  final String email;
  final int? discountPercentage;
  final bool isActive;
  final DateTime subscribedAt;
  final DateTime? unsubscribedAt;

  NewsletterSubscription({
    required this.id,
    required this.email,
    this.discountPercentage,
    this.isActive = true,
    required this.subscribedAt,
    this.unsubscribedAt,
  });

  factory NewsletterSubscription.fromJson(Map<String, dynamic> json) {
    return NewsletterSubscription(
      id: json['id'] as String,
      email: json['email'] as String,
      discountPercentage: json['discount_percentage'] as int?,
      isActive: json['is_active'] as bool? ?? true,
      subscribedAt: DateTime.parse(json['subscribed_at'] as String),
      unsubscribedAt: json['unsubscribed_at'] != null
          ? DateTime.parse(json['unsubscribed_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'discount_percentage': discountPercentage,
      'is_active': isActive,
      'subscribed_at': subscribedAt.toIso8601String(),
      'unsubscribed_at': unsubscribedAt?.toIso8601String(),
    };
  }
}
