import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// SettingsProvider - Gestión de preferencias y configuración del usuario
/// Maneja tema, idioma, notificaciones y otras preferencias
class SettingsProvider with ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  static const String _languageKey = 'language';
  static const String _notificationsKey = 'notifications_enabled';
  static const String _emailNotificationsKey = 'email_notifications';
  static const String _orderNotificationsKey = 'order_notifications';
  static const String _promotionNotificationsKey = 'promotion_notifications';

  SharedPreferences? _prefs;
  bool _isLoading = true;

  // Configuraciones
  ThemeMode _themeMode = ThemeMode.light;
  String _language = 'es';
  bool _notificationsEnabled = true;
  bool _emailNotificationsEnabled = true;
  bool _orderNotificationsEnabled = true;
  bool _promotionNotificationsEnabled = true;

  // Getters
  bool get isLoading => _isLoading;
  ThemeMode get themeMode => _themeMode;
  String get language => _language;
  bool get notificationsEnabled => _notificationsEnabled;
  bool get emailNotificationsEnabled => _emailNotificationsEnabled;
  bool get orderNotificationsEnabled => _orderNotificationsEnabled;
  bool get promotionNotificationsEnabled => _promotionNotificationsEnabled;

  // Setters con persistencia
  set themeMode(ThemeMode value) {
    _themeMode = value;
    _saveThemeMode(value);
    notifyListeners();
  }

  set language(String value) {
    _language = value;
    _saveLanguage(value);
    notifyListeners();
  }

  set notificationsEnabled(bool value) {
    _notificationsEnabled = value;
    _saveNotificationsEnabled(value);
    notifyListeners();
  }

  set emailNotificationsEnabled(bool value) {
    _emailNotificationsEnabled = value;
    _saveEmailNotificationsEnabled(value);
    notifyListeners();
  }

  set orderNotificationsEnabled(bool value) {
    _orderNotificationsEnabled = value;
    _saveOrderNotificationsEnabled(value);
    notifyListeners();
  }

  set promotionNotificationsEnabled(bool value) {
    _promotionNotificationsEnabled = value;
    _savePromotionNotificationsEnabled(value);
    notifyListeners();
  }

  SettingsProvider() {
    _initPrefs();
  }

  Future<void> _initPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    _loadSettings();
    _isLoading = false;
    notifyListeners();
  }

  /// Cargar todas las configuraciones
  void _loadSettings() {
    if (_prefs == null) return;
    // Cargar tema
    final themeModeString = _prefs!.getString(_themeKey) ?? 'light';
    switch (themeModeString) {
      case 'dark':
        _themeMode = ThemeMode.dark;
        break;
      case 'system':
        _themeMode = ThemeMode.system;
        break;
      default:
        _themeMode = ThemeMode.light;
    }

    // Cargar idioma
    _language = _prefs!.getString(_languageKey) ?? 'es';

    // Cargar notificaciones
    _notificationsEnabled = _prefs!.getBool(_notificationsKey) ?? true;
    _emailNotificationsEnabled = _prefs!.getBool(_emailNotificationsKey) ?? true;
    _orderNotificationsEnabled = _prefs!.getBool(_orderNotificationsKey) ?? true;
    _promotionNotificationsEnabled =
        _prefs!.getBool(_promotionNotificationsKey) ?? true;
  }

  /// Guardar tema
  Future<void> _saveThemeMode(ThemeMode mode) async {
    if (_prefs == null) return;
    String value;
    switch (mode) {
      case ThemeMode.dark:
        value = 'dark';
        break;
      case ThemeMode.system:
        value = 'system';
        break;
      default:
        value = 'light';
    }
    await _prefs!.setString(_themeKey, value);
  }

  /// Guardar idioma
  Future<void> _saveLanguage(String lang) async {
    if (_prefs == null) return;
    await _prefs!.setString(_languageKey, lang);
  }

  /// Guardar notificaciones
  Future<void> _saveNotificationsEnabled(bool enabled) async {
    if (_prefs == null) return;
    await _prefs!.setBool(_notificationsKey, enabled);
  }

  /// Guardar notificaciones por email
  Future<void> _saveEmailNotificationsEnabled(bool enabled) async {
    if (_prefs == null) return;
    await _prefs!.setBool(_emailNotificationsKey, enabled);
  }

  /// Guardar notificaciones de pedidos
  Future<void> _saveOrderNotificationsEnabled(bool enabled) async {
    if (_prefs == null) return;
    await _prefs!.setBool(_orderNotificationsKey, enabled);
  }

  /// Guardar notificaciones de promociones
  Future<void> _savePromotionNotificationsEnabled(bool enabled) async {
    if (_prefs == null) return;
    await _prefs!.setBool(_promotionNotificationsKey, enabled);
  }

  /// Resetear a valores por defecto
  Future<void> resetToDefaults() async {
    themeMode = ThemeMode.light;
    language = 'es';
    notificationsEnabled = true;
    emailNotificationsEnabled = true;
    orderNotificationsEnabled = true;
    promotionNotificationsEnabled = true;
  }

  /// Obtener el Locale correspondiente al idioma seleccionado
  Locale get appLocale {
    switch (_language) {
      case 'en':
        return const Locale('en', 'US');
      case 'fr':
        return const Locale('fr', 'FR');
      case 'es':
      default:
        return const Locale('es', 'ES');
    }
  }

  /// Obtener descripción legible del idioma
  String getLanguageDisplay() {
    switch (_language) {
      case 'es':
        return 'Español';
      case 'en':
        return 'English';
      case 'fr':
        return 'Français';
      default:
        return 'Español';
    }
  }

  /// Obtener descripción legible del tema
  String getThemeModeDisplay() {
    switch (_themeMode) {
      case ThemeMode.dark:
        return 'Oscuro';
      case ThemeMode.light:
        return 'Claro';
      case ThemeMode.system:
        return 'Sistema';
    }
  }
}
