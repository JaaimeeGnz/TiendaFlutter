import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FavoritesProvider extends ChangeNotifier {
  final Set<String> _favoriteIds = {};

  Set<String> get favorites => _favoriteIds;

  bool isFavorite(String productId) => _favoriteIds.contains(productId);

  int get favoritesCount => _favoriteIds.length;

  FavoritesProvider() {
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favoritesList = prefs.getStringList('favorites') ?? [];
      _favoriteIds.addAll(favoritesList);
      notifyListeners();
    } catch (e) {
      print('Error loading favorites: $e');
    }
  }

  Future<void> toggleFavorite(String productId) async {
    try {
      if (_favoriteIds.contains(productId)) {
        _favoriteIds.remove(productId);
      } else {
        _favoriteIds.add(productId);
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('favorites', _favoriteIds.toList());
      notifyListeners();
    } catch (e) {
      print('Error toggling favorite: $e');
    }
  }

  Future<void> addFavorite(String productId) async {
    try {
      _favoriteIds.add(productId);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('favorites', _favoriteIds.toList());
      notifyListeners();
    } catch (e) {
      print('Error adding favorite: $e');
    }
  }

  Future<void> removeFavorite(String productId) async {
    try {
      _favoriteIds.remove(productId);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('favorites', _favoriteIds.toList());
      notifyListeners();
    } catch (e) {
      print('Error removing favorite: $e');
    }
  }

  Future<void> clearFavorites() async {
    try {
      _favoriteIds.clear();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('favorites');
      notifyListeners();
    } catch (e) {
      print('Error clearing favorites: $e');
    }
  }
}
