import 'package:flutter/material.dart';

/// ProductFilters - Widget de filtros para lista de productos
/// Replica la funcionalidad de ProductFilters.tsx de Astro
/// Incluye filtros por precio, marca, talla y solo rebajas
class ProductFilters extends StatefulWidget {
  final double? minPrice;
  final double? maxPrice;
  final String? selectedBrand;
  final String? selectedSize;
  final bool onlyOnSale;
  final List<String> availableBrands;
  final List<String> availableSizes;
  final Function(ProductFilterState) onFilterChanged;

  const ProductFilters({
    super.key,
    this.minPrice,
    this.maxPrice,
    this.selectedBrand,
    this.selectedSize,
    this.onlyOnSale = false,
    required this.availableBrands,
    required this.availableSizes,
    required this.onFilterChanged,
  });

  @override
  State<ProductFilters> createState() => _ProductFiltersState();
}

class _ProductFiltersState extends State<ProductFilters> {
  late RangeValues _priceRange;
  String? _selectedBrand;
  String? _selectedSize;
  bool _onlyOnSale = false;

  // Rango de precios predeterminado (en euros)
  static const double _minPriceDefault = 0;
  static const double _maxPriceDefault = 500;

  @override
  void initState() {
    super.initState();
    _priceRange = RangeValues(
      widget.minPrice ?? _minPriceDefault,
      widget.maxPrice ?? _maxPriceDefault,
    );
    _selectedBrand = widget.selectedBrand;
    _selectedSize = widget.selectedSize;
    _onlyOnSale = widget.onlyOnSale;
  }

  void _notifyFilterChanged() {
    widget.onFilterChanged(
      ProductFilterState(
        minPrice: _priceRange.start > _minPriceDefault
            ? _priceRange.start
            : null,
        maxPrice: _priceRange.end < _maxPriceDefault ? _priceRange.end : null,
        brand: _selectedBrand,
        size: _selectedSize,
        onlyOnSale: _onlyOnSale,
      ),
    );
  }

  void _resetFilters() {
    setState(() {
      _priceRange = const RangeValues(_minPriceDefault, _maxPriceDefault);
      _selectedBrand = null;
      _selectedSize = null;
      _onlyOnSale = false;
    });
    _notifyFilterChanged();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header con botón de reset
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filtros',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              TextButton.icon(
                onPressed: _resetFilters,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Limpiar'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Filtro solo rebajas
          _buildSaleToggle(),
          const Divider(height: 24),

          // Filtro de precio
          _buildPriceFilter(),
          const Divider(height: 24),

          // Filtro de marca
          if (widget.availableBrands.isNotEmpty) ...[
            _buildBrandFilter(),
            const Divider(height: 24),
          ],

          // Filtro de talla
          if (widget.availableSizes.isNotEmpty) _buildSizeFilter(),
        ],
      ),
    );
  }

  Widget _buildSaleToggle() {
    return SwitchListTile(
      title: const Text('Solo productos en rebajas'),
      subtitle: const Text('Mostrar únicamente ofertas'),
      value: _onlyOnSale,
      activeThumbColor: Colors.red,
      contentPadding: EdgeInsets.zero,
      onChanged: (value) {
        setState(() {
          _onlyOnSale = value;
        });
        _notifyFilterChanged();
      },
    );
  }

  Widget _buildPriceFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Precio',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            Text(
              '${_priceRange.start.toInt()}€ - ${_priceRange.end.toInt()}€',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        RangeSlider(
          values: _priceRange,
          min: _minPriceDefault,
          max: _maxPriceDefault,
          divisions: 50,
          labels: RangeLabels(
            '${_priceRange.start.toInt()}€',
            '${_priceRange.end.toInt()}€',
          ),
          onChanged: (values) {
            setState(() {
              _priceRange = values;
            });
          },
          onChangeEnd: (values) {
            _notifyFilterChanged();
          },
        ),
      ],
    );
  }

  Widget _buildBrandFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Marca',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final brand in widget.availableBrands)
              ChoiceChip(
                label: Text(brand),
                selected: _selectedBrand == brand,
                onSelected: (selected) {
                  setState(() {
                    _selectedBrand = selected ? brand : null;
                  });
                  _notifyFilterChanged();
                },
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildSizeFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Talla',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final size in widget.availableSizes)
              ChoiceChip(
                label: Text(size),
                selected: _selectedSize == size,
                onSelected: (selected) {
                  setState(() {
                    _selectedSize = selected ? size : null;
                  });
                  _notifyFilterChanged();
                },
              ),
          ],
        ),
      ],
    );
  }
}

/// Estado de los filtros de producto
class ProductFilterState {
  final double? minPrice;
  final double? maxPrice;
  final String? brand;
  final String? size;
  final bool onlyOnSale;

  ProductFilterState({
    this.minPrice,
    this.maxPrice,
    this.brand,
    this.size,
    this.onlyOnSale = false,
  });

  bool get hasFilters =>
      minPrice != null ||
      maxPrice != null ||
      brand != null ||
      size != null ||
      onlyOnSale;
}
