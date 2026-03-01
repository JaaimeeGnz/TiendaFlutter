import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/format_utils.dart';
import '../../models/product.dart';
import '../../providers/product_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/favorites_provider.dart';

/// ProductDetailScreen - Detalle de producto
/// Replica la funcionalidad de /productos/[slug] de Astro
/// Incluye galería de imágenes, selector de talla, stock display y botón de favoritos
class ProductDetailScreen extends StatefulWidget {
  final String slug;

  const ProductDetailScreen({super.key, required this.slug});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  Product? _product;
  bool _isLoading = true;
  bool _isAddingToCart = false;
  String? _selectedSize;
  int _quantity = 1;
  int _currentImageIndex = 0;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _loadProduct();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadProduct() async {
    setState(() => _isLoading = true);

    final provider = context.read<ProductProvider>();
    final product = await provider.getProductBySlug(widget.slug);

    setState(() {
      _product = product;
      _isLoading = false;
      if (product != null && product.sizes.isNotEmpty) {
        // Seleccionar la primera talla con stock disponible
        _selectedSize = product.sizeStocks.isNotEmpty
            ? (product.sizeStocks.where((s) => s.stock > 0).isNotEmpty
                ? product.sizeStocks.firstWhere((s) => s.stock > 0).size
                : product.sizes.first)
            : product.sizes.first;
      }
    });
  }

  /// Añadir al carrito con reserva de stock
  /// Replica la funcionalidad de AddToCartButton.tsx de Astro
  Future<void> _addToCart() async {
    if (_product == null || _isAddingToCart) return;

    if (_product!.sizes.isNotEmpty && _selectedSize == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona una talla'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() => _isAddingToCart = true);

    final cartProvider = context.read<CartProvider>();
    final result = await cartProvider.addToCart(
      _product!,
      size: _selectedSize,
      quantity: _quantity,
    );

    setState(() => _isAddingToCart = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: result.success ? AppColors.success : AppColors.error,
          duration: const Duration(seconds: 2),
          action: result.success
              ? SnackBarAction(
                  label: 'VER CARRITO',
                  textColor: Colors.white,
                  onPressed: () => Navigator.pushNamed(context, '/cart'),
                )
              : null,
        ),
      );
    }
  }

  void _toggleFavorite() {
    if (_product == null) return;
    context.read<FavoritesProvider>().toggleFavorite(_product!.id);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_product == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Producto no encontrado')),
        body: const Center(child: Text('El producto no existe')),
      );
    }

    final isFavorite = context.watch<FavoritesProvider>().isFavorite(
      _product!.id,
    );

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar con galería de imágenes
          SliverAppBar(
            expandedHeight: 400,
            pinned: true,
            actions: [
              // Botón de favoritos
              IconButton(
                onPressed: _toggleFavorite,
                icon: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: isFavorite ? Colors.red : Colors.white,
                ),
              ),
              // Botón de compartir
              IconButton(
                onPressed: () {
                  // TODO: Implementar compartir
                },
                icon: const Icon(Icons.share, color: Colors.white),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(background: _buildImageGallery()),
          ),

          // Contenido
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badge de rebaja
                  if (_product!.hasDiscount)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: AppColors.jdRed,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '-${_product!.discountPercentage}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),

                  // Marca
                  if (_product!.brand != null && _product!.brand!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        _product!.brand!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                  // Nombre y precio
                  Text(
                    _product!.name,
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                  const SizedBox(height: 8),

                  // Precios
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        FormatUtils.formatPrice(_product!.priceCents),
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: _product!.hasDiscount
                              ? AppColors.jdRed
                              : AppColors.jdBlack,
                        ),
                      ),
                      if (_product!.hasDiscount &&
                          _product!.originalPriceCents != null) ...[
                        const SizedBox(width: 12),
                        Text(
                          FormatUtils.formatPrice(
                            _product!.originalPriceCents!,
                          ),
                          style: const TextStyle(
                            fontSize: 18,
                            color: AppColors.mediumGray,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Stock Display
                  _buildStockDisplay(),

                  const SizedBox(height: 24),

                  // Descripción
                  Text(
                    'Descripción',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _product!.description,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),

                  const SizedBox(height: 24),

                  // Selector de talla
                  if (_product!.sizes.isNotEmpty) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Talla',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        // Guía de tallas (placeholder)
                        TextButton(
                          onPressed: () => _showSizeGuide(),
                          child: const Text('Guía de tallas'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: _product!.sizes.map((size) {
                        final isSelected = _selectedSize == size;
                        final sizeStock = _product!.getStockForSize(size);
                        final isOutOfStock = sizeStock <= 0;
                        return ChoiceChip(
                          label: Text(
                            isOutOfStock ? '$size (Agotado)' : size,
                          ),
                          selected: isSelected,
                          onSelected: isOutOfStock
                              ? null
                              : (selected) {
                                  setState(() {
                                    _selectedSize = size;
                                    // Resetear cantidad al stock disponible de la nueva talla
                                    final maxStock = _product!.getStockForSize(size);
                                    if (_quantity > maxStock) {
                                      _quantity = maxStock > 0 ? 1 : 0;
                                    }
                                  });
                                },
                          selectedColor: AppColors.jdTurquoise,
                          disabledColor: Colors.grey[200],
                          labelStyle: TextStyle(
                            color: isOutOfStock
                                ? Colors.grey
                                : isSelected
                                    ? Colors.white
                                    : AppColors.jdBlack,
                            fontWeight: FontWeight.bold,
                            decoration: isOutOfStock ? TextDecoration.lineThrough : null,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Selector de cantidad
                  Text(
                    'Cantidad',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Builder(builder: (context) {
                    // Obtener stock máximo según talla seleccionada
                    final maxStock = (_selectedSize != null && _product!.sizeStocks.isNotEmpty)
                        ? _product!.getStockForSize(_selectedSize!)
                        : _product!.stock;
                    return Row(
                      children: [
                        IconButton(
                          onPressed: _quantity > 1
                              ? () => setState(() => _quantity--)
                              : null,
                          icon: const Icon(Icons.remove_circle_outline),
                          iconSize: 32,
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.lightGray),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '$_quantity',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: _quantity < maxStock
                              ? () => setState(() => _quantity++)
                              : null,
                          icon: const Icon(Icons.add_circle_outline),
                          iconSize: 32,
                        ),
                        const Spacer(),
                        Text(
                          'Máx: $maxStock',
                          style: TextStyle(color: Colors.grey[600], fontSize: 14),
                        ),
                      ],
                    );
                  }),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: AppColors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                offset: Offset(0, -2),
                blurRadius: 4,
              ),
            ],
          ),
          child: Builder(builder: (context) {
            // Determinar si se puede añadir según stock de talla
            final bool canAdd;
            final String buttonLabel;
            if (_selectedSize != null && _product!.sizeStocks.isNotEmpty) {
              final sizeStock = _product!.getStockForSize(_selectedSize!);
              canAdd = sizeStock > 0;
              buttonLabel = canAdd ? 'AÑADIR AL CARRITO' : 'TALLA AGOTADA';
            } else {
              canAdd = _product!.isInStock;
              buttonLabel = canAdd ? 'AÑADIR AL CARRITO' : 'AGOTADO';
            }

            return ElevatedButton(
              onPressed: canAdd && !_isAddingToCart ? _addToCart : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: AppColors.jdTurquoise,
              ),
              child: _isAddingToCart
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      buttonLabel,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            );
          }),
        ),
      ),
    );
  }

  /// Galería de imágenes con indicadores
  Widget _buildImageGallery() {
    final images = _product!.images;

    if (images.isEmpty) {
      return Container(
        color: AppColors.lightGray,
        child: const Center(
          child: Icon(Icons.image, size: 100, color: AppColors.mediumGray),
        ),
      );
    }

    return Stack(
      children: [
        PageView.builder(
          controller: _pageController,
          itemCount: images.length,
          onPageChanged: (index) {
            setState(() {
              _currentImageIndex = index;
            });
          },
          itemBuilder: (context, index) {
            return Image.network(
              images[index],
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: AppColors.lightGray,
                  child: const Center(
                    child: Icon(Icons.broken_image, size: 50),
                  ),
                );
              },
            );
          },
        ),
        // Indicadores de página
        if (images.length > 1)
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                images.length,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentImageIndex == index ? 12 : 8,
                  height: _currentImageIndex == index ? 12 : 8,
                  decoration: BoxDecoration(
                    color: _currentImageIndex == index
                        ? AppColors.jdTurquoise
                        : Colors.white.withOpacity(0.7),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1),
                  ),
                ),
              ),
            ),
          ),
        // Thumbnails
        if (images.length > 1)
          Positioned(
            bottom: 50,
            left: 16,
            right: 16,
            child: SizedBox(
              height: 60,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: images.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      _pageController.animateToPage(
                        index,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    child: Container(
                      width: 60,
                      height: 60,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _currentImageIndex == index
                              ? AppColors.jdTurquoise
                              : Colors.transparent,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: Image.network(images[index], fit: BoxFit.cover),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }

  /// Widget de stock display
  /// Muestra stock de la talla seleccionada si hay sizeStocks
  Widget _buildStockDisplay() {
    int stock;
    String sizeLabel = '';

    if (_selectedSize != null && _product!.sizeStocks.isNotEmpty) {
      stock = _product!.getStockForSize(_selectedSize!);
      sizeLabel = ' (talla $_selectedSize)';
    } else {
      stock = _product!.stock;
    }

    Color bgColor;
    Color textColor;
    IconData icon;
    String message;

    if (stock == 0) {
      bgColor = AppColors.error.withOpacity(0.1);
      textColor = AppColors.error;
      icon = Icons.remove_shopping_cart;
      message = 'Agotado$sizeLabel';
    } else if (stock <= 5) {
      bgColor = AppColors.warning.withOpacity(0.1);
      textColor = AppColors.warning;
      icon = Icons.warning_amber;
      message = '¡Solo quedan $stock unidades!$sizeLabel';
    } else {
      bgColor = AppColors.success.withOpacity(0.1);
      textColor = AppColors.success;
      icon = Icons.check_circle_outline;
      message = '$stock unidades disponibles$sizeLabel';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: textColor, size: 18),
          const SizedBox(width: 8),
          Text(
            message,
            style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  /// Mostrar guía de tallas
  void _showSizeGuide() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Guía de Tallas',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Encuentra tu talla perfecta midiendo tu pie en centímetros.',
              ),
              const SizedBox(height: 24),
              // Tabla de tallas de ejemplo
              Table(
                border: TableBorder.all(color: Colors.grey[300]!),
                children: const [
                  TableRow(
                    decoration: BoxDecoration(color: Color(0xFFF5F5F5)),
                    children: [
                      Padding(
                        padding: EdgeInsets.all(12),
                        child: Text(
                          'EU',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(12),
                        child: Text(
                          'US',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(12),
                        child: Text(
                          'CM',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  TableRow(
                    children: [
                      Padding(padding: EdgeInsets.all(12), child: Text('38')),
                      Padding(padding: EdgeInsets.all(12), child: Text('6')),
                      Padding(padding: EdgeInsets.all(12), child: Text('24')),
                    ],
                  ),
                  TableRow(
                    children: [
                      Padding(padding: EdgeInsets.all(12), child: Text('40')),
                      Padding(padding: EdgeInsets.all(12), child: Text('7.5')),
                      Padding(padding: EdgeInsets.all(12), child: Text('25.5')),
                    ],
                  ),
                  TableRow(
                    children: [
                      Padding(padding: EdgeInsets.all(12), child: Text('42')),
                      Padding(padding: EdgeInsets.all(12), child: Text('9')),
                      Padding(padding: EdgeInsets.all(12), child: Text('27')),
                    ],
                  ),
                  TableRow(
                    children: [
                      Padding(padding: EdgeInsets.all(12), child: Text('44')),
                      Padding(padding: EdgeInsets.all(12), child: Text('10.5')),
                      Padding(padding: EdgeInsets.all(12), child: Text('28.5')),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
