import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_theme.dart';
import '../../models/category.dart';
import '../../services/product_service.dart';
import '../../services/category_service.dart';
import '../../services/cloudinary_service.dart';

/// AdminProductEditScreen - Crear/Editar producto
/// Replica la funcionalidad de admin/products/[id] de Astro
class AdminProductEditScreen extends StatefulWidget {
  final String? productId;

  const AdminProductEditScreen({super.key, this.productId});

  @override
  State<AdminProductEditScreen> createState() => _AdminProductEditScreenState();
}

class _AdminProductEditScreenState extends State<AdminProductEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final ProductService _productService = ProductService();
  final CategoryService _categoryService = CategoryService();
  final CloudinaryService _cloudinaryService = CloudinaryService();
  final ImagePicker _imagePicker = ImagePicker();

  bool _isLoading = true;
  bool _isSaving = false;
  bool get _isEditing => widget.productId != null;

  // Campos del formulario
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _originalPriceController = TextEditingController();
  final _stockController = TextEditingController();
  final _brandController = TextEditingController();
  final _slugController = TextEditingController();

  List<Category> _categories = [];
  String? _selectedCategoryId;
  List<String> _sizes = [];
  Map<String, int> _sizeStocks = {}; // Stock por talla
  List<String> _imageUrls = [];
  final List<XFile> _newImages = [];
  bool _isOnSale = false;
  bool _isFeatured = false;

  // Tallas disponibles
  final List<String> _availableSizes = [
    'XS',
    'S',
    'M',
    'L',
    'XL',
    'XXL',
    '36',
    '37',
    '38',
    '39',
    '40',
    '41',
    '42',
    '43',
    '44',
    '45',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _originalPriceController.dispose();
    _stockController.dispose();
    _brandController.dispose();
    _slugController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // Cargar categorías
      _categories = await _categoryService.getAllCategories();

      // Si estamos editando, cargar el producto
      if (_isEditing) {
        final product = await _productService.getProductById(widget.productId!);
        if (product != null) {
          _nameController.text = product.name;
          _descriptionController.text = product.description;
          _priceController.text = (product.priceCents / 100).toStringAsFixed(2);
          _originalPriceController.text = product.originalPriceCents != null
              ? (product.originalPriceCents! / 100).toStringAsFixed(2)
              : '';
          _stockController.text = product.stock.toString();
          _brandController.text = product.brand ?? '';
          _slugController.text = product.slug;
          _selectedCategoryId = product.categoryId;
          _sizes = List.from(product.sizes);
          _imageUrls = List.from(product.images);
          _isOnSale = product.isOnSale;
          _isFeatured = product.isFeatured;

          // Cargar stock por tallas
          if (product.sizeStocks.isNotEmpty) {
            _sizeStocks = {
              for (final ss in product.sizeStocks) ss.size: ss.stock
            };
          } else {
            // Si no hay sizeStocks cargados, intentar obtenerlos
            final sizeStocks = await _productService.getSizeStocks(product.id);
            _sizeStocks = {for (final ss in sizeStocks) ss.size: ss.stock};
          }
          // Asegurar que todas las tallas seleccionadas tengan entrada
          for (final size in _sizes) {
            _sizeStocks.putIfAbsent(size, () => 0);
          }
        }
      }
    } catch (e) {
      print('Error loading product data: $e');
    }

    setState(() => _isLoading = false);
  }

  String _generateSlug(String name) {
    return name
        .toLowerCase()
        .replaceAll(RegExp(r'[áàäâã]'), 'a')
        .replaceAll(RegExp(r'[éèëê]'), 'e')
        .replaceAll(RegExp(r'[íìïî]'), 'i')
        .replaceAll(RegExp(r'[óòöôõ]'), 'o')
        .replaceAll(RegExp(r'[úùüû]'), 'u')
        .replaceAll(RegExp(r'[ñ]'), 'n')
        .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .trim();
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage();
      if (images.isNotEmpty) {
        setState(() {
          _newImages.addAll(images);
        });
      }
    } catch (e) {
      print('Error picking images: $e');
    }
  }

  Future<void> _removeExistingImage(int index) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar imagen'),
        content: const Text(
          '¿Estás seguro de que quieres eliminar esta imagen?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        _imageUrls.removeAt(index);
      });
    }
  }

  void _removeNewImage(int index) {
    setState(() {
      _newImages.removeAt(index);
    });
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      // Subir nuevas imágenes a Cloudinary
      List<String> uploadedUrls = List.from(_imageUrls);
      int failedUploads = 0;
      for (final image in _newImages) {
        final url = await _cloudinaryService.uploadImage(File(image.path));
        if (url != null) {
          uploadedUrls.add(url);
        } else {
          failedUploads++;
        }
      }

      if (failedUploads > 0 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$failedUploads imagen(es) no se pudieron subir'),
            backgroundColor: Colors.orange,
          ),
        );
      }

      final priceText = _priceController.text.replaceAll(',', '.');
      final originalPriceText = _originalPriceController.text.replaceAll(
        ',',
        '.',
      );

      final priceCents = (double.parse(priceText) * 100).round();
      final originalPriceCents =
          originalPriceText.isNotEmpty
              ? (double.parse(originalPriceText) * 100).round()
              : null;

      final productData = {
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'slug':
            _slugController.text.trim().isEmpty
                ? _generateSlug(_nameController.text)
                : _slugController.text.trim(),
        'price_cents': priceCents,
        'original_price_cents': _isOnSale ? originalPriceCents : null,
        'stock': _sizes.isNotEmpty
            ? _sizeStocks.values.fold<int>(0, (sum, s) => sum + s)
            : int.parse(_stockController.text),
        'brand':
            _brandController.text.trim().isEmpty
                ? null
                : _brandController.text.trim(),
        'category_id': _selectedCategoryId,
        'sizes': _sizes,
        'images': uploadedUrls,
        'featured': _isFeatured,
        // Stock por talla (se envía a ProductService para upsert en product_sizes)
        if (_sizes.isNotEmpty)
          'size_stocks': _sizes.map((size) => {
            'size': size,
            'stock': _sizeStocks[size] ?? 0,
          }).toList(),
      };

      if (_isEditing) {
        await _productService.updateProduct(widget.productId!, productData);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Producto actualizado correctamente'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } else {
        await _productService.createProduct(productData);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Producto creado correctamente'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      print('Error saving product: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }

    setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: AppBar(
        title: Text(_isEditing ? 'EDITAR PRODUCTO' : 'NUEVO PRODUCTO'),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            TextButton(
              onPressed: _saveProduct,
              child: const Text(
                'GUARDAR',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Imágenes
                  _buildImagesSection(),
                  const SizedBox(height: 24),

                  // Información básica
                  _buildBasicInfoSection(),
                  const SizedBox(height: 24),

                  // Precios y stock
                  _buildPricingSection(),
                  const SizedBox(height: 24),

                  // Categoría y marca
                  _buildCategorySection(),
                  const SizedBox(height: 24),

                  // Tallas
                  _buildSizesSection(),
                  const SizedBox(height: 24),

                  // Opciones
                  _buildOptionsSection(),
                  const SizedBox(height: 32),

                  // Botón guardar
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveProduct,
                      child: _isSaving
                          ? const CircularProgressIndicator()
                          : Text(
                              _isEditing
                                  ? 'ACTUALIZAR PRODUCTO'
                                  : 'CREAR PRODUCTO',
                            ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildImagesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Imágenes',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                OutlinedButton.icon(
                  onPressed: _pickImages,
                  icon: const Icon(Icons.add_photo_alternate),
                  label: const Text('Añadir'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_imageUrls.isEmpty && _newImages.isEmpty)
              Container(
                height: 120,
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.lightGray),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.image, size: 48, color: AppColors.mediumGray),
                      SizedBox(height: 8),
                      Text('No hay imágenes'),
                    ],
                  ),
                ),
              )
            else
              SizedBox(
                height: 120,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    // Imágenes existentes
                    ..._imageUrls.asMap().entries.map(
                      (entry) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                entry.value,
                                height: 120,
                                width: 120,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: () => _removeExistingImage(entry.key),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: AppColors.error,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            if (entry.key == 0)
                              Positioned(
                                bottom: 4,
                                left: 4,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.jdTurquoise,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'Principal',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    // Nuevas imágenes
                    ..._newImages.asMap().entries.map(
                      (entry) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                File(entry.value.path),
                                height: 120,
                                width: 120,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: () => _removeNewImage(entry.key),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: AppColors.error,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 4,
                              left: 4,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'Nueva',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Información básica',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nombre del producto *',
                hintText: 'Ej: Camiseta Nike Dri-FIT',
              ),
              onChanged: (value) {
                if (_slugController.text.isEmpty) {
                  _slugController.text = _generateSlug(value);
                }
              },
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'El nombre es obligatorio';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _slugController,
              decoration: const InputDecoration(
                labelText: 'Slug (URL)',
                hintText: 'Se genera automáticamente',
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Descripción *',
                hintText: 'Describe el producto...',
              ),
              maxLines: 4,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'La descripción es obligatoria';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPricingSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Precios y stock',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _priceController,
                    decoration: const InputDecoration(
                      labelText: 'Precio *',
                      prefixText: '€ ',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
                    ],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Obligatorio';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _originalPriceController,
                    decoration: InputDecoration(
                      labelText: 'Precio original',
                      prefixText: '€ ',
                      enabled: _isOnSale,
                      helperText:
                          _isOnSale
                              ? 'Mostrará descuento sobre este precio'
                              : null,
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Solo mostrar campo de stock global si NO hay tallas seleccionadas
            if (_sizes.isEmpty)
              TextFormField(
                controller: _stockController,
                decoration: const InputDecoration(
                  labelText: 'Stock *',
                  suffixText: 'unidades',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (_sizes.isEmpty && (value == null || value.isEmpty)) {
                    return 'Obligatorio';
                  }
                  return null;
                },
              )
            else
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.jdTurquoise.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.jdTurquoise.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: AppColors.jdTurquoise, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'El stock se gestiona por tallas en la sección "Tallas y stock".\n'
                        'Stock total: ${_sizeStocks.values.fold<int>(0, (s, v) => s + v)} unidades.',
                        style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Categoría y marca',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedCategoryId,
              decoration: const InputDecoration(labelText: 'Categoría *'),
              items: _categories.map((category) {
                return DropdownMenuItem(
                  value: category.id,
                  child: Text(category.name),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategoryId = value;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Selecciona una categoría';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _brandController,
              decoration: const InputDecoration(
                labelText: 'Marca',
                hintText: 'Ej: Nike, Adidas, Puma...',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSizesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tallas y stock',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Selecciona las tallas disponibles y define el stock de cada una',
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _availableSizes.map((size) {
                final isSelected = _sizes.contains(size);
                return FilterChip(
                  label: Text(size),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _sizes.add(size);
                        _sizeStocks.putIfAbsent(size, () => 0);
                      } else {
                        _sizes.remove(size);
                        _sizeStocks.remove(size);
                      }
                    });
                  },
                  selectedColor: AppColors.jdTurquoise.withOpacity(0.2),
                  checkmarkColor: AppColors.jdTurquoise,
                );
              }).toList(),
            ),
            // Stock por cada talla seleccionada
            if (_sizes.isNotEmpty) ...[
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Stock por talla',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    'Total: ${_sizeStocks.values.fold<int>(0, (sum, s) => sum + s)} uds.',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.jdTurquoise,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ..._sizes.map((size) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.jdTurquoise.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          size,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          initialValue: (_sizeStocks[size] ?? 0).toString(),
                          decoration: InputDecoration(
                            labelText: 'Stock talla $size',
                            suffixText: 'uds.',
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          onChanged: (value) {
                            _sizeStocks[size] = int.tryParse(value) ?? 0;
                          },
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOptionsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Opciones',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              title: const Text('Producto en oferta'),
              subtitle: const Text('Mostrar precio rebajado'),
              value: _isOnSale,
              activeThumbColor: AppColors.jdTurquoise,
              onChanged: (value) {
                setState(() {
                  _isOnSale = value;
                });
              },
            ),
            SwitchListTile(
              title: const Text('Producto destacado'),
              subtitle: const Text('Mostrar en la página principal'),
              value: _isFeatured,
              activeThumbColor: AppColors.jdTurquoise,
              onChanged: (value) {
                setState(() {
                  _isFeatured = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}
