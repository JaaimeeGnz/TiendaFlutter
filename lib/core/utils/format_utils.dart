import 'package:intl/intl.dart';

class FormatUtils {
  /// Formatea un precio en céntimos a formato de moneda (€)
  /// Ejemplo: 5999 -> "59,99 €"
  static String formatPrice(int priceCents) {
    final double price = priceCents / 100.0;
    final formatter = NumberFormat.currency(
      locale: 'es_ES',
      symbol: '€',
      decimalDigits: 2,
    );
    return formatter.format(price);
  }

  /// Formatea una fecha a formato legible
  /// Ejemplo: 2024-01-15 -> "15 de enero de 2024"
  static String formatDate(DateTime date) {
    final formatter = DateFormat('d \'de\' MMMM \'de\' y', 'es_ES');
    return formatter.format(date);
  }

  /// Formatea una fecha a formato corto
  /// Ejemplo: 2024-01-15 -> "15/01/2024"
  static String formatDateShort(DateTime date) {
    final formatter = DateFormat('dd/MM/yyyy');
    return formatter.format(date);
  }

  /// Capitaliza la primera letra de un string
  static String capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  /// Genera un número de pedido único
  static String generateOrderNumber() {
    final now = DateTime.now();
    final timestamp = now.millisecondsSinceEpoch;
    return 'JGM-${timestamp.toString().substring(5)}';
  }
}

class ValidationUtils {
  /// Valida un email
  static bool isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  /// Valida un teléfono (formato español)
  static bool isValidPhone(String phone) {
    final phoneRegex = RegExp(r'^[+]?[0-9]{9,15}$');
    return phoneRegex.hasMatch(phone.replaceAll(RegExp(r'[\s-]'), ''));
  }

  /// Valida un código postal español
  static bool isValidPostalCode(String postalCode) {
    final postalCodeRegex = RegExp(r'^[0-9]{5}$');
    return postalCodeRegex.hasMatch(postalCode);
  }
}
