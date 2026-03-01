import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cart_item.dart';
import '../models/product.dart';
import '../services/stock_service.dart';
import '../services/discount_service.dart';

/// CartProvider - Gestión del carrito de compras
/// Replica la funcionalidad de cart.ts (nanostores) de Astro
/// Incluye reserva de stock y códigos de descuento
class CartProvider with ChangeNotifier {
  static const String _cartKey = 'cartItems';
  static const String _discountKey = 'appliedDiscount';

  final StockService _stockService = StockService();
  final DiscountService _discountService = DiscountService();

  List<CartItem> _items = [];
  bool _isLoading = false;

  // Código de descuento aplicado
  String? _discountCode;
  int _discountPercentage = 0;

  List<CartItem> get items => _items;
  bool get isLoading => _isLoading;
  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);

  /// Subtotal sin descuento (en centavos)
  int get subtotalCents =>
      _items.fold(0, (sum, item) => sum + (item.priceCents * item.quantity));

  /// Descuento aplicado (en centavos)
  int get discountCents => (subtotalCents * _discountPercentage / 100).round();

  /// Total con descuento (en centavos)
  int get totalCents => subtotalCents - discountCents;

  /// Código de descuento aplicado
  String? get discountCode => _discountCode;
  int get discountPercentage => _discountPercentage;
  bool get hasDiscount => _discountCode != null && _discountPercentage > 0;

  bool get isEmpty => _items.isEmpty;
  bool get isNotEmpty => _items.isNotEmpty;

  CartProvider() {
    _loadCart();
  }

  Future<void> _loadCart() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();

      // Cargar items del carrito
      final cartJson = prefs.getString(_cartKey);
      if (cartJson != null && cartJson.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(cartJson);
        _items = decoded.map((json) => CartItem.fromJson(json)).toList();
      }

      // Cargar descuento aplicado
      final discountJson = prefs.getString(_discountKey);
      if (discountJson != null && discountJson.isNotEmpty) {
        final Map<String, dynamic> discountData = jsonDecode(discountJson);
        _discountCode = discountData['code'];
        _discountPercentage = discountData['percentage'] ?? 0;
      }
    } catch (e) {
      print('Error loading cart: $e');
      _items = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _saveCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Guardar items del carrito
      final cartJson = jsonEncode(_items.map((item) => item.toJson()).toList());
      await prefs.setString(_cartKey, cartJson);

      // Guardar descuento aplicado
      if (_discountCode != null) {
        final discountJson = jsonEncode({
          'code': _discountCode,
          'percentage': _discountPercentage,
        });
        await prefs.setString(_discountKey, discountJson);
      } else {
        await prefs.remove(_discountKey);
      }
    } catch (e) {
      print('Error saving cart: $e');
    }
  }

  /// Añadir producto al carrito con reserva de stock
  /// Replica la funcionalidad de AddToCartButton.tsx de Astro
  Future<AddToCartResult> addToCart(
    Product product, {
    String? size,
    int quantity = 1,
  }) async {
    if (quantity <= 0) {
      return AddToCartResult.error('Cantidad inválida');
    }

    if (product.stock <= 0) {
      return AddToCartResult.error('Producto sin stock');
    }

    // Verificar stock por talla si aplica
    if (size != null && product.sizeStocks.isNotEmpty) {
      final sizeStock = product.getStockForSize(size);
      if (sizeStock <= 0) {
        return AddToCartResult.error('Talla $size agotada');
      }
    }

    final existingIndex = _items.indexWhere(
      (item) => item.id == product.id && item.size == size,
    );

    // Calcular nueva cantidad total
    int currentQty = 0;
    if (existingIndex >= 0) {
      currentQty = _items[existingIndex].quantity;
    }
    final newTotalQty = currentQty + quantity;

    // Verificar stock disponible (por talla si aplica)
    final maxStock = (size != null && product.sizeStocks.isNotEmpty)
        ? product.getStockForSize(size)
        : product.stock;
    if (newTotalQty > maxStock) {
      return AddToCartResult.error('No hay suficiente stock disponible');
    }

    // Reservar stock en la base de datos (por talla)
    final stockResult = await _stockService.reserveStock(
      productId: product.id,
      quantity: quantity,
      size: size,
    );
    if (!stockResult.success) {
      return AddToCartResult.error(stockResult.message);
    }

    // Actualizar carrito local
    if (existingIndex >= 0) {
      final existingItem = _items[existingIndex];
      _items[existingIndex] = existingItem.copyWith(quantity: newTotalQty);
    } else {
      final newItem = CartItem(
        id: product.id,
        name: product.name,
        slug: product.slug,
        priceCents: product.priceCents,
        quantity: quantity.clamp(1, maxStock),
        size: size,
        imageUrl: product.images.isNotEmpty ? product.images[0] : null,
        stock: maxStock,
      );
      _items.add(newItem);
    }

    await _saveCart();
    notifyListeners();

    return AddToCartResult.success('Producto añadido al carrito');
  }

  /// Quitar producto del carrito y liberar stock
  Future<void> removeFromCart(String productId, {String? size}) async {
    final item = _items.firstWhere(
      (item) => item.id == productId && item.size == size,
      orElse: () => CartItem(
        id: '',
        name: '',
        slug: '',
        priceCents: 0,
        quantity: 0,
        stock: 0,
      ),
    );

    if (item.id.isNotEmpty) {
      // Liberar stock reservado (por talla)
      await _stockService.releaseStock(
        productId: productId,
        quantity: item.quantity,
        size: size,
      );
    }

    _items.removeWhere((item) => item.id == productId && item.size == size);
    await _saveCart();
    notifyListeners();
  }

  /// Actualizar cantidad de un item
  Future<void> updateQuantity(
    String productId,
    int quantity, {
    String? size,
  }) async {
    if (quantity <= 0) {
      await removeFromCart(productId, size: size);
      return;
    }

    final index = _items.indexWhere(
      (item) => item.id == productId && item.size == size,
    );

    if (index >= 0) {
      final item = _items[index];
      final diff = quantity - item.quantity;

      if (diff > 0) {
        // Reservar más stock
        await _stockService.reserveStock(productId: productId, quantity: diff, size: size);
      } else if (diff < 0) {
        // Liberar stock
        await _stockService.releaseStock(productId: productId, quantity: -diff, size: size);
      }

      _items[index] = item.copyWith(quantity: quantity.clamp(1, item.stock));
      await _saveCart();
      notifyListeners();
    }
  }

  Future<void> incrementQuantity(String productId, {String? size}) async {
    final index = _items.indexWhere(
      (item) => item.id == productId && item.size == size,
    );

    if (index >= 0) {
      final item = _items[index];
      if (item.quantity < item.stock) {
        await _stockService.reserveStock(productId: productId, quantity: 1, size: size);
        _items[index] = item.copyWith(quantity: item.quantity + 1);
        await _saveCart();
        notifyListeners();
      }
    }
  }

  Future<void> decrementQuantity(String productId, {String? size}) async {
    final index = _items.indexWhere(
      (item) => item.id == productId && item.size == size,
    );

    if (index >= 0) {
      final item = _items[index];
      if (item.quantity > 1) {
        await _stockService.releaseStock(productId: productId, quantity: 1, size: size);
        _items[index] = item.copyWith(quantity: item.quantity - 1);
        await _saveCart();
        notifyListeners();
      } else {
        await removeFromCart(productId, size: size);
      }
    }
  }

  /// Limpiar carrito y liberar todo el stock
  Future<void> clearCart() async {
    // Liberar stock de todos los items (por talla)
    for (final item in _items) {
      await _stockService.releaseStock(
        productId: item.id,
        quantity: item.quantity,
        size: item.size,
      );
    }

    _items.clear();
    _discountCode = null;
    _discountPercentage = 0;
    await _saveCart();
    notifyListeners();
  }

  /// Aplicar código de descuento
  /// Replica la funcionalidad de StripeCheckout.tsx de Astro
  Future<ApplyDiscountResult> applyDiscountCode(String code) async {
    if (code.isEmpty) {
      return ApplyDiscountResult.error('Por favor ingresa un código');
    }

    final result = await _discountService.validateCode(code);

    if (result.success) {
      _discountCode = result.code;
      _discountPercentage = result.discountPercentage ?? 0;
      await _saveCart();
      notifyListeners();
      return ApplyDiscountResult.success(result.message);
    } else {
      return ApplyDiscountResult.error(result.message);
    }
  }

  /// Quitar código de descuento
  void removeDiscount() {
    _discountCode = null;
    _discountPercentage = 0;
    _saveCart();
    notifyListeners();
  }

  bool hasItem(String productId, {String? size}) {
    return _items.any((item) => item.id == productId && item.size == size);
  }

  CartItem? getItem(String productId, {String? size}) {
    try {
      return _items.firstWhere(
        (item) => item.id == productId && item.size == size,
      );
    } catch (e) {
      return null;
    }
  }

  /// Preparar datos para checkout de Stripe
  Map<String, dynamic> getCheckoutData() {
    return {
      'items': _items
          .map(
            (item) => {
              'id': item.id,
              'name': item.name,
              'price_cents': item.priceCents,
              'quantity': item.quantity,
              'size': item.size,
            },
          )
          .toList(),
      'subtotal_cents': subtotalCents,
      'discount_cents': discountCents,
      'total_cents': totalCents,
      'discount_code': _discountCode,
    };
  }
}

/// Resultado de añadir al carrito
class AddToCartResult {
  final bool success;
  final String message;

  AddToCartResult._(this.success, this.message);

  factory AddToCartResult.success(String message) =>
      AddToCartResult._(true, message);
  factory AddToCartResult.error(String message) =>
      AddToCartResult._(false, message);
}

/// Resultado de aplicar descuento
class ApplyDiscountResult {
  final bool success;
  final String message;

  ApplyDiscountResult._(this.success, this.message);

  factory ApplyDiscountResult.success(String message) =>
      ApplyDiscountResult._(true, message);
  factory ApplyDiscountResult.error(String message) =>
      ApplyDiscountResult._(false, message);
}
