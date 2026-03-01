import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  // Supabase
  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';
  static String get supabaseServiceRoleKey =>
      dotenv.env['SUPABASE_SERVICE_ROLE_KEY'] ?? '';
  static String get productsBucket =>
      dotenv.env['PRODUCTS_BUCKET'] ?? 'products-images';
  static String get siteUrl => dotenv.env['SITE_URL'] ?? '';

  // Cloudinary
  static String get cloudinaryCloudName =>
      (dotenv.env['CLOUDINARY_CLOUD_NAME'] ?? '').trim();
  static String get cloudinaryApiKey =>
      (dotenv.env['CLOUDINARY_API_KEY'] ?? '').trim();
  static String get cloudinaryApiSecret =>
      (dotenv.env['CLOUDINARY_API_SECRET'] ?? '').trim();

  // Brevo (Email)
  static String get brevoApiKey => dotenv.env['BREVO_API_KEY'] ?? '';

  // Stripe
  static String get stripePublicKey => dotenv.env['STRIPE_PUBLIC_KEY'] ?? '';
  static String get stripeSecretKey => dotenv.env['STRIPE_SECRET_KEY'] ?? '';

  // Validación
  static bool get isConfigured {
    return supabaseUrl.isNotEmpty &&
        supabaseAnonKey.isNotEmpty &&
        cloudinaryCloudName.isNotEmpty &&
        stripePublicKey.isNotEmpty;
  }
}
