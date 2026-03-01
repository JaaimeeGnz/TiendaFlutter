import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/product.dart';
import 'supabase_service.dart';

/// ProductService - Consumo de datos de la tabla 'products' en Supabase
/// Replica exactamente las queries usadas en la versión Astro:
///   - index.astro: productos destacados, en oferta
///   - productos/index.astro: todos los productos, por categoría, por subcategorías múltiples
///   - productos/[slug].astro: producto por slug
///   - marcas/index.astro: obtener marcas únicas
///   - marcas/[brand].astro: productos por marca
///   - api/search.ts: búsqueda ilike
///   - api/productos.ts: productos por IDs
///   - admin/productos/index.astro: todos con JOIN a categorías
///   - admin/productos/fotos-masivo.astro: productos sin imágenes
///
/// Stock por tallas: usa tabla product_sizes (product_id, size, stock)
class ProductService {
  final SupabaseClient _client = SupabaseService.instance.client;

  /// Obtener todos los productos activos
  /// Replica: productos/index.astro (sin filtro de categoría)
  /// Orden: featured DESC, created_at DESC
  Future<List<Product>> getAllProducts() async {
    try {
      final response = await _client
          .from('products')
          .select('*, product_sizes(size, stock)')
          .eq('is_active', true)
          .order('featured', ascending: false)
          .order('created_at', ascending: false);

      return (response as List).map((json) => Product.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching products: $e');
      return [];
    }
  }

  /// Obtener productos destacados
  /// Replica: index.astro → .eq("featured", true).eq("is_active", true).limit(8)
  Future<List<Product>> getFeaturedProducts({int limit = 8}) async {
    try {
      final response = await _client
          .from('products')
          .select('*, product_sizes(size, stock)')
          .eq('is_active', true)
          .eq('featured', true)
          .limit(limit);

      return (response as List).map((json) => Product.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching featured products: $e');
      return [];
    }
  }

  /// Obtener productos en oferta
  /// Replica: index.astro → .eq("is_active", true).not("original_price_cents", "is", null).limit(4)
  Future<List<Product>> getSaleProducts({int limit = 4}) async {
    try {
      final response = await _client
          .from('products')
          .select('*, product_sizes(size, stock)')
          .eq('is_active', true)
          .not('original_price_cents', 'is', null)
          .limit(limit);

      return (response as List).map((json) => Product.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching sale products: $e');
      return [];
    }
  }

  /// Obtener producto por slug
  /// Replica: productos/[slug].astro → .eq("slug", slug).eq("is_active", true).single()
  Future<Product?> getProductBySlug(String slug) async {
    try {
      final response = await _client
          .from('products')
          .select('*, product_sizes(size, stock)')
          .eq('slug', slug)
          .eq('is_active', true)
          .single();

      return Product.fromJson(response);
    } catch (e) {
      print('Error fetching product by slug: $e');
      return null;
    }
  }

  /// Obtener producto por ID (sin filtro is_active, usado en admin)
  /// Replica: admin/productos/[id].astro → .eq("id", id).single()
  Future<Product?> getProductById(String id) async {
    try {
      final response = await _client
          .from('products')
          .select('*, product_sizes(size, stock)')
          .eq('id', id)
          .single();

      return Product.fromJson(response);
    } catch (e) {
      print('Error fetching product by id: $e');
      return null;
    }
  }

  /// Obtener productos por categoría
  /// Replica: productos/index.astro y categoria/[slug].astro
  /// → .eq("category_id", categoryId).eq("is_active", true)
  /// Orden: featured DESC, created_at DESC
  Future<List<Product>> getProductsByCategory(String categoryId) async {
    try {
      final response = await _client
          .from('products')
          .select('*, product_sizes(size, stock)')
          .eq('category_id', categoryId)
          .eq('is_active', true)
          .order('featured', ascending: false)
          .order('created_at', ascending: false);

      return (response as List).map((json) => Product.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching products by category: $e');
      return [];
    }
  }

  /// Obtener productos por múltiples IDs de categoría (subcategorías)
  /// Replica: productos/index.astro y categoria/[slug].astro
  /// → .in("category_id", subIds).eq("is_active", true)
  /// Orden: featured DESC, created_at DESC
  Future<List<Product>> getProductsByCategoryIds(List<String> categoryIds) async {
    if (categoryIds.isEmpty) return [];

    try {
      final response = await _client
          .from('products')
          .select('*, product_sizes(size, stock)')
          .inFilter('category_id', categoryIds)
          .eq('is_active', true)
          .order('featured', ascending: false)
          .order('created_at', ascending: false);

      return (response as List).map((json) => Product.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching products by category ids: $e');
      return [];
    }
  }

  /// Obtener productos por marca
  /// Replica: marcas/[brand].astro → .eq("brand", brandName).eq("is_active", true)
  /// Orden: featured DESC, created_at DESC
  Future<List<Product>> getProductsByBrand(String brand) async {
    try {
      final response = await _client
          .from('products')
          .select('*, product_sizes(size, stock)')
          .eq('brand', brand)
          .eq('is_active', true)
          .order('featured', ascending: false)
          .order('created_at', ascending: false);

      return (response as List).map((json) => Product.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching products by brand: $e');
      return [];
    }
  }

  /// Obtener marcas únicas con conteo de productos
  /// Replica: marcas/index.astro → .eq("is_active", true).not("brand", "is", null)
  /// Post-procesamiento JS para extraer marcas únicas y contar
  Future<List<BrandInfo>> getBrands() async {
    try {
      final response = await _client
          .from('products')
          .select('brand')
          .eq('is_active', true)
          .not('brand', 'is', null);

      // Post-procesamiento: extraer marcas únicas y contar
      final Map<String, int> brandCounts = {};
      for (final row in (response as List)) {
        final brand = row['brand'] as String?;
        if (brand != null && brand.isNotEmpty) {
          brandCounts[brand] = (brandCounts[brand] ?? 0) + 1;
        }
      }

      return brandCounts.entries
          .map((e) => BrandInfo(name: e.key, productCount: e.value))
          .toList()
        ..sort((a, b) => a.name.compareTo(b.name));
    } catch (e) {
      print('Error fetching brands: $e');
      return [];
    }
  }

  /// Buscar productos
  /// Replica: api/search.ts → .ilike("name", "%query%").eq("is_active", true).limit(10)
  /// Selecciona: id, name, slug, price_cents, is_active
  Future<List<Product>> searchProducts(String query) async {
    if (query.trim().isEmpty) return [];

    try {
      final response = await _client
          .from('products')
          .select('*, product_sizes(size, stock)')
          .ilike('name', '%${query.trim().toLowerCase()}%')
          .eq('is_active', true)
          .limit(10);

      return (response as List).map((json) => Product.fromJson(json)).toList();
    } catch (e) {
      print('Error searching products: $e');
      return [];
    }
  }

  /// Obtener productos por IDs
  /// Replica: api/productos.ts → .in("id", ids)
  Future<List<Product>> getProductsByIds(List<String> ids) async {
    if (ids.isEmpty) return [];

    try {
      final response = await _client
          .from('products')
          .select('*, product_sizes(size, stock)')
          .inFilter('id', ids);

      return (response as List).map((json) => Product.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching products by ids: $e');
      return [];
    }
  }

  // ─── ADMIN ────────────────────────────────────────────────────────────

  /// ADMIN: Obtener todos los productos con nombre de categoría
  /// Replica: admin/productos/index.astro → .select("*, categories(name)").order("created_at", DESC)
  Future<List<Map<String, dynamic>>> getAllProductsAdmin() async {
    try {
      final response = await _client
          .from('products')
          .select('*, categories(name), product_sizes(size, stock)')
          .order('created_at', ascending: false);

      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      print('Error fetching admin products: $e');
      return [];
    }
  }

  /// ADMIN: Obtener productos sin imágenes
  /// Replica: admin/productos/fotos-masivo.astro → .filter("images", "is", null)
  Future<List<Product>> getProductsWithoutImages() async {
    try {
      final response = await _client
          .from('products')
          .select('id, name, slug, images')
          .filter('images', 'is', null)
          .order('created_at', ascending: false);

      return (response as List).map((json) => Product.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching products without images: $e');
      return [];
    }
  }

  /// ADMIN: Crear producto
  /// Replica: api/admin/products.ts POST
  /// Genera slug automáticamente desde el nombre
  /// También crea product_sizes para stock por talla
  Future<Product?> createProduct(dynamic productData) async {
    try {
      Map<String, dynamic> data;
      if (productData is Product) {
        data = productData.toJson();
      } else if (productData is Map<String, dynamic>) {
        data = Map<String, dynamic>.from(productData);
      } else {
        throw ArgumentError(
          'productData debe ser Product o Map<String, dynamic>',
        );
      }

      // Extraer sizeStocks antes de enviar a products
      final sizeStocks = data.remove('size_stocks') as List<Map<String, dynamic>>?;

      // Generar slug si no existe (igual que en Astro)
      if (data['slug'] == null || (data['slug'] as String).isEmpty) {
        data['slug'] = _generateSlug(data['name'] as String);
      }

      // Asegurar is_active por defecto
      data['is_active'] = data['is_active'] ?? true;

      // Remover campos que no deben enviarse al crear
      data.remove('id');
      data.remove('created_at');
      data.remove('updated_at');
      data.remove('product_sizes');

      final response = await _client
          .from('products')
          .insert(data)
          .select()
          .single();

      final productId = response['id'] as String;

      // Crear product_sizes si hay datos de stock por talla
      if (sizeStocks != null && sizeStocks.isNotEmpty) {
        await _upsertSizeStocks(productId, sizeStocks);
        // Sincronizar stock total en products
        final totalStock = sizeStocks.fold<int>(0, (sum, s) => sum + (s['stock'] as int? ?? 0));
        await _client.from('products').update({'stock': totalStock}).eq('id', productId);
      }

      return Product.fromJson(response);
    } catch (e) {
      print('Error creating product: $e');
      return null;
    }
  }

  /// ADMIN: Actualizar producto
  /// Replica: api/admin/products/[id].ts POST
  /// También actualiza product_sizes para stock por talla
  Future<Product?> updateProduct(
    String id,
    Map<String, dynamic> updates,
  ) async {
    try {
      // Extraer sizeStocks antes de enviar a products
      final sizeStocks = updates.remove('size_stocks') as List<Map<String, dynamic>>?;

      // Remover campos que no deben enviarse
      updates.remove('id');
      updates.remove('created_at');
      updates.remove('product_sizes');

      // Actualizar product_sizes si hay datos de stock por talla
      if (sizeStocks != null && sizeStocks.isNotEmpty) {
        await _upsertSizeStocks(id, sizeStocks);
        // Sincronizar stock total en products
        final totalStock = sizeStocks.fold<int>(0, (sum, s) => sum + (s['stock'] as int? ?? 0));
        updates['stock'] = totalStock;
      }

      final response = await _client
          .from('products')
          .update(updates)
          .eq('id', id)
          .select()
          .single();

      return Product.fromJson(response);
    } catch (e) {
      print('Error updating product: $e');
      return null;
    }
  }

  /// Upsert product_sizes para un producto
  /// Replica: api/admin/products/[id].ts en Astro
  Future<void> _upsertSizeStocks(String productId, List<Map<String, dynamic>> sizeStocks) async {
    for (final ss in sizeStocks) {
      await _client.from('product_sizes').upsert({
        'product_id': productId,
        'size': ss['size'],
        'stock': ss['stock'] ?? 0,
      }, onConflict: 'product_id,size');
    }

    // Eliminar tallas que ya no están en la lista
    final activeSizes = sizeStocks.map((s) => s['size'] as String).toList();
    if (activeSizes.isNotEmpty) {
      await _client
          .from('product_sizes')
          .delete()
          .eq('product_id', productId)
          .not('size', 'in', '(${activeSizes.map((s) => '"$s"').join(',')})');
    }
  }

  /// Obtener stock por tallas de un producto
  Future<List<SizeStock>> getSizeStocks(String productId) async {
    try {
      final response = await _client
          .from('product_sizes')
          .select('size, stock')
          .eq('product_id', productId)
          .order('size');

      return (response as List)
          .map((json) => SizeStock.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error fetching size stocks: $e');
      return [];
    }
  }

  /// ADMIN: Eliminar producto (soft delete)
  Future<bool> deleteProduct(String id) async {
    try {
      await _client.from('products').update({'is_active': false}).eq('id', id);

      return true;
    } catch (e) {
      print('Error deleting product: $e');
      return false;
    }
  }

  /// Genera slug desde nombre (igual que en Astro)
  String _generateSlug(String name) {
    return name
        .toLowerCase()
        .replaceAll(RegExp(r'[áàäâã]'), 'a')
        .replaceAll(RegExp(r'[éèëê]'), 'e')
        .replaceAll(RegExp(r'[íìïî]'), 'i')
        .replaceAll(RegExp(r'[óòöôõ]'), 'o')
        .replaceAll(RegExp(r'[úùüû]'), 'u')
        .replaceAll(RegExp(r'ñ'), 'n')
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
  }
}

/// Información de una marca con conteo de productos
class BrandInfo {
  final String name;
  final int productCount;

  BrandInfo({required this.name, required this.productCount});
}
