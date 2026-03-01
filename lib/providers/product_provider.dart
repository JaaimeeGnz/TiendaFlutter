import 'package:flutter/material.dart';
import '../models/product.dart';
import '../models/category.dart';
import '../services/product_service.dart';
import '../services/category_service.dart';

/// ProductProvider - Gestión del estado de productos y categorías
/// Replica los patrones de carga de datos de los archivos Astro:
///   - index.astro: productos destacados + en oferta
///   - productos/index.astro: todos los productos, por categoría, por subcategorías
///   - marcas/index.astro: listado de marcas
///   - marcas/[brand].astro: productos por marca
///   - categoria/[slug].astro: categoría con subcategorías y sus productos
class ProductProvider with ChangeNotifier {
  final ProductService _productService = ProductService();
  final CategoryService _categoryService = CategoryService();

  List<Product> _products = [];
  List<Product> _featuredProducts = [];
  List<Product> _saleProducts = [];
  List<Category> _categories = [];
  List<Category> _mainCategories = [];
  List<BrandInfo> _brands = [];

  bool _isLoading = false;
  bool _isCategoriesLoading = false;
  String? _errorMessage;

  // Getters
  List<Product> get products => _products;
  List<Product> get featuredProducts => _featuredProducts;
  List<Product> get saleProducts => _saleProducts;
  List<Category> get categories => _categories;
  List<Category> get mainCategories => _mainCategories;
  List<BrandInfo> get brands => _brands;
  bool get isLoading => _isLoading;
  bool get isCategoriesLoading => _isCategoriesLoading;
  String? get errorMessage => _errorMessage;

  /// Cargar todos los productos activos
  /// Replica: productos/index.astro (sin filtro de categoría)
  Future<void> loadProducts() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _products = await _productService.getAllProducts();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Cargar productos destacados
  /// Replica: index.astro → featured=true, is_active=true, limit 8
  Future<void> loadFeaturedProducts({int limit = 8}) async {
    try {
      _featuredProducts = await _productService.getFeaturedProducts(
        limit: limit,
      );
      notifyListeners();
    } catch (e) {
      print('Error loading featured products: $e');
    }
  }

  /// Cargar productos en oferta
  /// Replica: index.astro → original_price_cents NOT NULL, limit 4
  Future<void> loadSaleProducts({int limit = 4}) async {
    try {
      _saleProducts = await _productService.getSaleProducts(limit: limit);
      notifyListeners();
    } catch (e) {
      print('Error loading sale products: $e');
    }
  }

  /// Cargar categorías activas
  /// Replica: productos/index.astro → categorías con is_active=true
  Future<void> loadCategories() async {
    _isCategoriesLoading = true;
    notifyListeners();

    try {
      _categories = await _categoryService.getAllActiveCategories();
    } catch (e) {
      print('Error loading categories: $e');
    } finally {
      _isCategoriesLoading = false;
      notifyListeners();
    }
  }

  /// Cargar categorías principales (sin parent_id)
  /// Replica: productos/index.astro → .is("parent_id", null).eq("is_active", true)
  Future<void> loadMainCategories() async {
    _isCategoriesLoading = true;
    notifyListeners();

    try {
      _mainCategories = await _categoryService.getMainCategories();
    } catch (e) {
      print('Error loading main categories: $e');
    } finally {
      _isCategoriesLoading = false;
      notifyListeners();
    }
  }

  /// Cargar marcas con conteo
  /// Replica: marcas/index.astro
  Future<void> loadBrands() async {
    try {
      _brands = await _productService.getBrands();
      notifyListeners();
    } catch (e) {
      print('Error loading brands: $e');
    }
  }

  /// Obtener producto por slug
  Future<Product?> getProductBySlug(String slug) async {
    return await _productService.getProductBySlug(slug);
  }

  /// Obtener productos por categoría (incluye productos de subcategorías)
  /// Replica el patrón de categoria/[slug].astro:
  /// 1. Busca subcategorías de la categoría padre
  /// 2. Si hay subcategorías, obtiene productos de todas ellas (.in("category_id", subIds))
  /// 3. Si no hay subcategorías, obtiene productos directos (.eq("category_id", id))
  Future<List<Product>> getProductsByCategory(String categoryId) async {
    try {
      // Buscar subcategorías
      final subcategories = await _categoryService.getSubcategories(categoryId);

      if (subcategories.isNotEmpty) {
        // Obtener productos de todas las subcategorías + la categoría padre
        final allCategoryIds = [
          categoryId,
          ...subcategories.map((s) => s.id),
        ];
        return await _productService.getProductsByCategoryIds(allCategoryIds);
      } else {
        // Sin subcategorías: productos directos
        return await _productService.getProductsByCategory(categoryId);
      }
    } catch (e) {
      print('Error getting products by category: $e');
      return [];
    }
  }

  /// Obtener subcategorías de una categoría
  Future<List<Category>> getSubcategories(String parentId) async {
    return await _categoryService.getSubcategories(parentId);
  }

  /// Obtener productos por marca
  /// Replica: marcas/[brand].astro
  Future<List<Product>> getProductsByBrand(String brand) async {
    return await _productService.getProductsByBrand(brand);
  }

  /// Buscar productos
  /// Replica: api/search.ts → .ilike("name", "%q%").eq("is_active", true).limit(10)
  Future<List<Product>> searchProducts(String query) async {
    return await _productService.searchProducts(query);
  }

  /// Obtener categoría por slug
  Future<Category?> getCategoryBySlug(String slug) async {
    return await _categoryService.getCategoryBySlug(slug);
  }

  /// Obtener categoría por ID
  Future<Category?> getCategoryById(String id) async {
    return await _categoryService.getCategoryById(id);
  }

  /// Obtener productos por IDs (para favoritos)
  /// Replica: api/productos.ts → .in("id", ids)
  Future<List<Product>> getProductsByIds(List<String> ids) async {
    return await _productService.getProductsByIds(ids);
  }

  // Limpiar error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Refrescar todo - carga inicial de la app
  /// Replica la carga de index.astro + productos/index.astro
  Future<void> refreshAll() async {
    await Future.wait([
      loadProducts(),
      loadFeaturedProducts(),
      loadSaleProducts(),
      loadCategories(),
      loadMainCategories(),
      loadBrands(),
    ]);
  }
}
