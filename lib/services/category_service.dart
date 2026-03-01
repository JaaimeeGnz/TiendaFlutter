import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/category.dart';
import 'supabase_service.dart';

/// CategoryService - Consumo de datos de la tabla 'categories' en Supabase
/// Replica exactamente las queries usadas en la versión Astro:
///   - productos/index.astro: categorías principales, subcategorías
///   - categoria/[slug].astro: categoría por slug con is_active
///   - admin/productos/[id].astro: todas las categorías (sin filtro)
class CategoryService {
  final SupabaseClient _client = SupabaseService.instance.client;

  // Alias para compatibilidad
  Future<List<Category>> getCategories() => getAllActiveCategories();

  /// Obtener todas las categorías activas
  /// Replica: productos/index.astro (filtro habitual)
  /// Orden: display_order ASC
  Future<List<Category>> getAllActiveCategories() async {
    try {
      final response = await _client
          .from('categories')
          .select()
          .eq('is_active', true)
          .order('display_order', ascending: true);

      return (response as List).map((json) => Category.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching active categories: $e');
      return [];
    }
  }

  /// Obtener todas las categorías (incluyendo inactivas) - ADMIN
  /// Replica: admin/productos/[id].astro y nuevo.astro → .select("*") sin filtros
  Future<List<Category>> getAllCategories() async {
    try {
      final response = await _client
          .from('categories')
          .select()
          .order('display_order', ascending: true);

      return (response as List).map((json) => Category.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching categories: $e');
      return [];
    }
  }

  /// Obtener categorías principales (sin parent)
  /// Replica: productos/index.astro → .is("parent_id", null).eq("is_active", true)
  /// Orden: display_order ASC
  Future<List<Category>> getMainCategories() async {
    try {
      final response = await _client
          .from('categories')
          .select()
          .isFilter('parent_id', null)
          .eq('is_active', true)
          .order('display_order', ascending: true);

      return (response as List).map((json) => Category.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching main categories: $e');
      return [];
    }
  }

  /// Obtener subcategorías de una categoría padre
  /// Replica: productos/index.astro y categoria/[slug].astro
  /// → .eq("parent_id", parentId).eq("is_active", true)
  /// Orden: display_order ASC
  Future<List<Category>> getSubcategories(String parentId) async {
    try {
      final response = await _client
          .from('categories')
          .select()
          .eq('parent_id', parentId)
          .eq('is_active', true)
          .order('display_order', ascending: true);

      return (response as List).map((json) => Category.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching subcategories: $e');
      return [];
    }
  }

  /// Obtener categoría por slug (solo activas)
  /// Replica: productos/index.astro y categoria/[slug].astro
  /// → .eq("slug", slug).eq("is_active", true).single()
  Future<Category?> getCategoryBySlug(String slug) async {
    try {
      final response = await _client
          .from('categories')
          .select()
          .eq('slug', slug)
          .eq('is_active', true)
          .single();

      return Category.fromJson(response);
    } catch (e) {
      print('Error fetching category by slug: $e');
      return null;
    }
  }

  /// Obtener categoría por ID
  /// Replica: productos/[slug].astro → .eq("id", id).single()
  Future<Category?> getCategoryById(String id) async {
    try {
      final response = await _client
          .from('categories')
          .select()
          .eq('id', id)
          .single();

      return Category.fromJson(response);
    } catch (e) {
      print('Error fetching category by id: $e');
      return null;
    }
  }

  // ADMIN: Crear categoría
  Future<Category?> createCategory(Category category) async {
    try {
      final data = category.toJson();
      data.remove('id');
      data.remove('created_at');
      data.remove('updated_at');

      final response = await _client
          .from('categories')
          .insert(data)
          .select()
          .single();

      return Category.fromJson(response);
    } catch (e) {
      print('Error creating category: $e');
      return null;
    }
  }

  // ADMIN: Actualizar categoría
  Future<Category?> updateCategory(
    String id,
    Map<String, dynamic> updates,
  ) async {
    try {
      final response = await _client
          .from('categories')
          .update(updates)
          .eq('id', id)
          .select()
          .single();

      return Category.fromJson(response);
    } catch (e) {
      print('Error updating category: $e');
      return null;
    }
  }

  // ADMIN: Eliminar categoría
  Future<bool> deleteCategory(String id) async {
    try {
      await _client.from('categories').delete().eq('id', id);

      return true;
    } catch (e) {
      print('Error deleting category: $e');
      return false;
    }
  }
}
