import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

/// StockService - Gestión de reserva y liberación de stock POR TALLA
/// Replica la funcionalidad de /api/cart/reserve-stock y /api/cart/release-stock de Astro
/// Usa la tabla product_sizes (product_id, size, stock) para stock por talla
class StockService {
  final SupabaseClient _client = SupabaseService.instance.client;

  /// Reservar stock cuando se añade al carrito
  /// Equivalente a POST /api/cart/reserve-stock en Astro
  /// Descuenta stock de product_sizes y sincroniza products.stock
  Future<StockResult> reserveStock({
    required String productId,
    required int quantity,
    String? size,
  }) async {
    try {
      // Validaciones
      if (quantity <= 0) {
        return StockResult.error('La cantidad debe ser mayor a 0');
      }

      // Obtener nombre del producto
      final productResponse = await _client
          .from('products')
          .select('name')
          .eq('id', productId)
          .single();
      final productName = productResponse['name'] as String;

      // Si hay talla, usar product_sizes
      if (size != null && size.isNotEmpty) {
        try {
          final sizeResponse = await _client
              .from('product_sizes')
              .select('id, stock')
              .eq('product_id', productId)
              .eq('size', size)
              .single();

          final currentStock = sizeResponse['stock'] as int;
          final sizeId = sizeResponse['id'] as String;

          if (currentStock < quantity) {
            return StockResult.error(
              'Stock insuficiente para talla $size. Disponible: $currentStock',
              availableStock: currentStock,
            );
          }

          final newStock = currentStock - quantity;
          await _client
              .from('product_sizes')
              .update({'stock': newStock})
              .eq('id', sizeId);

          // Sincronizar stock total en products
          await _syncTotalStock(productId);

          print(
            '✅ Stock reservado para $productName (talla $size): '
            'cantidad=$quantity, stockAnterior=$currentStock, stockNuevo=$newStock',
          );

          return StockResult.success(
            message: 'Stock reservado correctamente',
            productId: productId,
            productName: productName,
            stockReserved: quantity,
            stockRemaining: newStock,
          );
        } catch (e) {
          // Si no existe la fila en product_sizes, fallback al stock global
          print('⚠️ product_sizes no encontrado para $productId/$size, usando stock global');
        }
      }

      // Fallback: stock global (para productos sin tallas)
      final response = await _client
          .from('products')
          .select('id, name, stock')
          .eq('id', productId)
          .single();

      final currentStock = response['stock'] as int;

      if (currentStock < quantity) {
        return StockResult.error(
          'Stock insuficiente. Disponible: $currentStock',
          availableStock: currentStock,
        );
      }

      final newStock = currentStock - quantity;
      await _client
          .from('products')
          .update({'stock': newStock})
          .eq('id', productId);

      print(
        '✅ Stock reservado para $productName: '
        'cantidad=$quantity, stockAnterior=$currentStock, stockNuevo=$newStock',
      );

      return StockResult.success(
        message: 'Stock reservado correctamente',
        productId: productId,
        productName: productName,
        stockReserved: quantity,
        stockRemaining: newStock,
      );
    } catch (e) {
      print('❌ Error en reserveStock: $e');
      return StockResult.error('Error al reservar stock: $e');
    }
  }

  /// Liberar stock cuando se elimina del carrito
  /// Equivalente a POST /api/cart/release-stock en Astro
  Future<StockResult> releaseStock({
    required String productId,
    required int quantity,
    String? size,
  }) async {
    try {
      if (quantity <= 0) {
        return StockResult.error('La cantidad debe ser mayor a 0');
      }

      final productResponse = await _client
          .from('products')
          .select('name')
          .eq('id', productId)
          .single();
      final productName = productResponse['name'] as String;

      // Si hay talla, usar product_sizes
      if (size != null && size.isNotEmpty) {
        try {
          final sizeResponse = await _client
              .from('product_sizes')
              .select('id, stock')
              .eq('product_id', productId)
              .eq('size', size)
              .single();

          final currentStock = sizeResponse['stock'] as int;
          final sizeId = sizeResponse['id'] as String;
          final newStock = currentStock + quantity;

          await _client
              .from('product_sizes')
              .update({'stock': newStock})
              .eq('id', sizeId);

          // Sincronizar stock total en products
          await _syncTotalStock(productId);

          print(
            '✅ Stock liberado para $productName (talla $size): '
            'cantidad=$quantity, stockAnterior=$currentStock, stockNuevo=$newStock',
          );

          return StockResult.success(
            message: 'Stock liberado correctamente',
            productId: productId,
            productName: productName,
            stockReleased: quantity,
            stockRemaining: newStock,
          );
        } catch (e) {
          print('⚠️ product_sizes no encontrado para $productId/$size, usando stock global');
        }
      }

      // Fallback: stock global
      final response = await _client
          .from('products')
          .select('id, name, stock')
          .eq('id', productId)
          .single();

      final currentStock = response['stock'] as int;
      final newStock = currentStock + quantity;

      await _client
          .from('products')
          .update({'stock': newStock})
          .eq('id', productId);

      print(
        '✅ Stock liberado para $productName: '
        'cantidad=$quantity, stockAnterior=$currentStock, stockNuevo=$newStock',
      );

      return StockResult.success(
        message: 'Stock liberado correctamente',
        productId: productId,
        productName: productName,
        stockReleased: quantity,
        stockRemaining: newStock,
      );
    } catch (e) {
      print('❌ Error en releaseStock: $e');
      return StockResult.error('Error al liberar stock: $e');
    }
  }

  /// Obtener stock de una talla específica
  Future<int?> getSizeStock(String productId, String size) async {
    try {
      final response = await _client
          .from('product_sizes')
          .select('stock')
          .eq('product_id', productId)
          .eq('size', size)
          .single();
      return response['stock'] as int;
    } catch (e) {
      return null;
    }
  }

  /// Verificar stock actual de un producto (global)
  Future<int?> getProductStock(String productId) async {
    try {
      final response = await _client
          .from('products')
          .select('stock')
          .eq('id', productId)
          .single();

      return response['stock'] as int;
    } catch (e) {
      print('Error obteniendo stock: $e');
      return null;
    }
  }

  /// Verificar si hay stock suficiente (por talla o global)
  Future<bool> hasEnoughStock({
    required String productId,
    required int requiredQuantity,
    String? size,
  }) async {
    if (size != null && size.isNotEmpty) {
      final stock = await getSizeStock(productId, size);
      if (stock != null) return stock >= requiredQuantity;
    }
    final stock = await getProductStock(productId);
    return stock != null && stock >= requiredQuantity;
  }

  /// Sincronizar products.stock = SUM(product_sizes.stock)
  Future<void> _syncTotalStock(String productId) async {
    try {
      final response = await _client
          .from('product_sizes')
          .select('stock')
          .eq('product_id', productId);

      final totalStock = (response as List)
          .fold<int>(0, (sum, row) => sum + (row['stock'] as int));

      await _client
          .from('products')
          .update({'stock': totalStock})
          .eq('id', productId);
    } catch (e) {
      print('Error syncing total stock: $e');
    }
  }
}

/// Resultado de operaciones de stock
class StockResult {
  final bool success;
  final String message;
  final String? productId;
  final String? productName;
  final int? stockReserved;
  final int? stockReleased;
  final int? stockRemaining;
  final int? availableStock;

  StockResult._({
    required this.success,
    required this.message,
    this.productId,
    this.productName,
    this.stockReserved,
    this.stockReleased,
    this.stockRemaining,
    this.availableStock,
  });

  factory StockResult.success({
    required String message,
    required String productId,
    required String productName,
    int? stockReserved,
    int? stockReleased,
    required int stockRemaining,
  }) {
    return StockResult._(
      success: true,
      message: message,
      productId: productId,
      productName: productName,
      stockReserved: stockReserved,
      stockReleased: stockReleased,
      stockRemaining: stockRemaining,
    );
  }

  factory StockResult.error(String message, {int? availableStock}) {
    return StockResult._(
      success: false,
      message: message,
      availableStock: availableStock,
    );
  }
}
