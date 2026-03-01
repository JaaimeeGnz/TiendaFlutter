import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/product_provider.dart';
import '../../widgets/product_card.dart';
import '../../widgets/product_filters.dart';
import '../../models/product.dart';
import '../../models/category.dart';
import '../../services/category_service.dart';

/// ProductListScreen - Lista de productos con filtros
/// Replica la funcionalidad de /productos y /categoria/[slug] de Astro
/// Soporta parámetros: categoria, soloRebajas, búsqueda
class ProductListScreen extends StatefulWidget {
  final String? categorySlug;
  final bool onlyOnSale;
  final String searchQuery;
  final String? brandFilter;

  const ProductListScreen({
    super.key,
    this.categorySlug,
    this.onlyOnSale = false,
    this.searchQuery = '',
    this.brandFilter,
  });

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final CategoryService _categoryService = CategoryService();

  List<Product> _filteredProducts = [];
  List<_NavSection> _sections = [];
  int _selectedSectionIndex = 0;
  bool _isSearching = false;
  bool _showFilters = false;

  // Estado de filtros
  ProductFilterState _filterState = ProductFilterState();
  List<String> _availableBrands = [];
  List<String> _availableSizes = [];

  @override
  void initState() {
    super.initState();
    _filterState = ProductFilterState(
      onlyOnSale: widget.onlyOnSale,
      brand: widget.brandFilter,
    );
    // Pre-rellenar búsqueda si viene del home
    if (widget.searchQuery.isNotEmpty) {
      _searchController.text = widget.searchQuery;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  Future<void> _loadInitialData() async {
    final provider = context.read<ProductProvider>();

    // Construir secciones de navegación principal (como la web)
    final mainCategories = await _categoryService.getMainCategories();
    final sections = <_NavSection>[
      const _NavSection(label: 'PRODUCTOS'), // Todos los productos
    ];

    for (final mainCat in mainCategories) {
      final subcategories = await _categoryService.getSubcategories(mainCat.id);
      final allIds = [mainCat.id, ...subcategories.map((s) => s.id)];
      sections.add(_NavSection(
        label: mainCat.name.toUpperCase(),
        slug: mainCat.slug,
        categoryIds: allIds,
      ));
    }

    sections.add(const _NavSection(label: 'REBAJAS', isSaleFilter: true));

    setState(() {
      _sections = sections;
      // Seleccionar sección según parámetros
      if (widget.categorySlug != null) {
        final idx = sections.indexWhere((s) => s.slug == widget.categorySlug);
        if (idx != -1) _selectedSectionIndex = idx;
      }
      if (widget.onlyOnSale) {
        _selectedSectionIndex = sections.length - 1; // REBAJAS
      }
    });

    if (provider.products.isEmpty) {
      await provider.loadProducts();
    }

    _extractFiltersFromProducts(provider.products);
    _applyFilters();
  }

  void _extractFiltersFromProducts(List<Product> products) {
    // Extraer marcas únicas
    final brands = products
        .where((p) => p.brand != null && p.brand!.isNotEmpty)
        .map((p) => p.brand!)
        .toSet()
        .toList();
    brands.sort();

    // Extraer tallas únicas
    final sizes = <String>{};
    for (final product in products) {
      sizes.addAll(product.sizes);
    }
    final sizesList = sizes.toList();
    // Ordenar tallas numéricas y alfabéticas
    sizesList.sort((a, b) {
      final aNum = int.tryParse(a);
      final bNum = int.tryParse(b);
      if (aNum != null && bNum != null) return aNum.compareTo(bNum);
      return a.compareTo(b);
    });

    setState(() {
      _availableBrands = brands;
      _availableSizes = sizesList;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch(String query) {
    _isSearching = query.isNotEmpty;
    _applyFilters();
  }

  void _applyFilters() {
    final provider = context.read<ProductProvider>();
    var products = List<Product>.from(provider.products);

    // Filtro por búsqueda
    final query = _searchController.text.toLowerCase();
    if (query.isNotEmpty) {
      products = products
          .where(
            (p) =>
                p.name.toLowerCase().contains(query) ||
                p.description.toLowerCase().contains(query) ||
                (p.brand?.toLowerCase().contains(query) ?? false),
          )
          .toList();
    }

    // Filtro por sección de navegación
    if (_selectedSectionIndex > 0 && _selectedSectionIndex < _sections.length) {
      final section = _sections[_selectedSectionIndex];
      if (section.isSaleFilter) {
        products = products.where((p) => p.isOnSale).toList();
      } else if (section.categoryIds.isNotEmpty) {
        products = products
            .where((p) => section.categoryIds.contains(p.categoryId))
            .toList();
      }
    }

    // Filtro solo rebajas
    if (_filterState.onlyOnSale) {
      products = products.where((p) => p.isOnSale).toList();
    }

    // Filtro por precio (convertir de euros a centavos)
    if (_filterState.minPrice != null) {
      final minCents = (_filterState.minPrice! * 100).toInt();
      products = products.where((p) => p.priceCents >= minCents).toList();
    }
    if (_filterState.maxPrice != null) {
      final maxCents = (_filterState.maxPrice! * 100).toInt();
      products = products.where((p) => p.priceCents <= maxCents).toList();
    }

    // Filtro por marca
    if (_filterState.brand != null) {
      products = products
          .where(
            (p) => p.brand?.toLowerCase() == _filterState.brand!.toLowerCase(),
          )
          .toList();
    }

    // Filtro por talla
    if (_filterState.size != null) {
      products = products
          .where((p) => p.sizes.contains(_filterState.size!))
          .toList();
    }

    setState(() {
      _filteredProducts = products;
    });
  }

  String _getPageTitle() {
    if (_selectedSectionIndex > 0 && _selectedSectionIndex < _sections.length) {
      return _sections[_selectedSectionIndex].label;
    }
    if (_filterState.brand != null) {
      return _filterState.brand!.toUpperCase();
    }
    if (_filterState.onlyOnSale) {
      return 'REBAJAS';
    }
    return 'PRODUCTOS';
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = context.watch<ProductProvider>();

    // Actualizar filtros cuando cambien los productos
    if (productProvider.products.isNotEmpty && _filteredProducts.isEmpty) {
      _extractFiltersFromProducts(productProvider.products);
      _applyFilters();
    }

    return Scaffold(

      appBar: AppBar(
        title: Text(_getPageTitle()),
        actions: [
          // Botón de filtros
          IconButton(
            icon: Badge(
              isLabelVisible: _filterState.hasFilters,
              child: Icon(
                _showFilters ? Icons.filter_list_off : Icons.filter_list,
              ),
            ),
            onPressed: () {
              setState(() {
                _showFilters = !_showFilters;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: () {
              Navigator.pushNamed(context, '/cart');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Barra de búsqueda
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.white,
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: _performSearch,
                  decoration: InputDecoration(
                    hintText: 'Buscar productos...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _performSearch('');
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),

                // Tabs de secciones principales (como la web)
                if (_sections.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 40,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        // Chip "Todos"
                        ..._sections.asMap().entries.map(
                          (entry) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(entry.value.label),
                              selected: _selectedSectionIndex == entry.key,
                              onSelected: (selected) {
                                setState(() {
                                  _selectedSectionIndex = selected
                                      ? entry.key
                                      : 0;
                                });
                                _applyFilters();
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Panel de filtros expandible
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Container(
              margin: const EdgeInsets.all(16),
              child: ProductFilters(
                minPrice: _filterState.minPrice,
                maxPrice: _filterState.maxPrice,
                selectedBrand: _filterState.brand,
                selectedSize: _filterState.size,
                onlyOnSale: _filterState.onlyOnSale,
                availableBrands: _availableBrands,
                availableSizes: _availableSizes,
                onFilterChanged: (state) {
                  setState(() {
                    _filterState = state;
                  });
                  _applyFilters();
                },
              ),
            ),
            crossFadeState: _showFilters
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),

          // Contador de resultados
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_filteredProducts.length} producto${_filteredProducts.length != 1 ? 's' : ''}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    color: AppColors.darkGray,
                  ),
                ),
                if (_filterState.hasFilters)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _filterState = ProductFilterState();
                        _selectedSectionIndex = 0;
                      });
                      _applyFilters();
                    },
                    child: const Text('Limpiar filtros'),
                  ),
              ],
            ),
          ),

          // Lista de productos
          Expanded(
            child: productProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredProducts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.search_off,
                          size: 64,
                          color: AppColors.mediumGray,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _isSearching || _filterState.hasFilters
                              ? 'No se encontraron productos con los filtros aplicados'
                              : 'No hay productos disponibles',
                          style: const TextStyle(
                            fontSize: 16,
                            color: AppColors.mediumGray,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (_filterState.hasFilters) ...[
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _filterState = ProductFilterState();
                                _selectedSectionIndex = 0;
                                _searchController.clear();
                              });
                              _applyFilters();
                            },
                            child: const Text('Limpiar filtros'),
                          ),
                        ],
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () async {
                      await productProvider.loadProducts();
                      _applyFilters();
                    },
                    child: GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.65,
                          ),
                      itemCount: _filteredProducts.length,
                      itemBuilder: (context, index) {
                        return ProductCard(product: _filteredProducts[index]);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

/// Sección de navegación principal para filtrar productos
/// Replica las secciones del nav de la web: PRODUCTOS, ZAPATILLAS, ROPA, ACCESORIOS, REBAJAS
class _NavSection {
  final String label;
  final String? slug;
  final List<String> categoryIds;
  final bool isSaleFilter;

  const _NavSection({
    required this.label,
    this.slug,
    this.categoryIds = const [],
    this.isSaleFilter = false,
  });
}
