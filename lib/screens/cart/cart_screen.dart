import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/format_utils.dart';
import '../../providers/cart_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/address_provider.dart';
import '../../services/stripe_service.dart';
import '../../services/order_service.dart';

/// CartScreen - Pantalla de carrito de compras
/// Replica la funcionalidad de /carrito de Astro
/// Incluye códigos de descuento, resumen de compra y checkout con Stripe
class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final TextEditingController _discountController = TextEditingController();
  final TextEditingController _guestEmailController = TextEditingController();
  final StripeService _stripeService = StripeService();
  final OrderService _orderService = OrderService();

  bool _isApplyingDiscount = false;
  bool _isCheckingOut = false;
  String? _discountError;
  String? _discountSuccess;

  @override
  void dispose() {
    _discountController.dispose();
    _guestEmailController.dispose();
    super.dispose();
  }

  /// Aplicar código de descuento
  Future<void> _applyDiscount() async {
    final code = _discountController.text.trim();
    if (code.isEmpty) {
      setState(() {
        _discountError = 'Por favor ingresa un código';
        _discountSuccess = null;
      });
      return;
    }

    setState(() {
      _isApplyingDiscount = true;
      _discountError = null;
      _discountSuccess = null;
    });

    final cartProvider = context.read<CartProvider>();
    final result = await cartProvider.applyDiscountCode(code);

    setState(() {
      _isApplyingDiscount = false;
      if (result.success) {
        _discountSuccess = result.message;
        _discountController.clear();
      } else {
        _discountError = result.message;
      }
    });
  }

  /// Proceder al checkout con Stripe
  /// Replica la funcionalidad de StripeCheckout.tsx de Astro
  Future<void> _proceedToCheckout() async {
    final authProvider = context.read<AuthProvider>();
    final cartProvider = context.read<CartProvider>();
    final addressProvider = context.read<AddressProvider>();

    // Verificar si puede hacer checkout
    if (!authProvider.canCheckout) {
      _showAuthDialog();
      return;
    }

    // Si el usuario está autenticado, cargar direcciones antes de continuar
    if (authProvider.isAuthenticated && authProvider.user != null) {
      // Cargar direcciones si aún no se han cargado
      if (addressProvider.addresses.isEmpty && !addressProvider.isLoading) {
        await addressProvider.loadAddresses(authProvider.user!.id);
      }

      // Si tiene direcciones, mostrar selector
      if (addressProvider.isNotEmpty) {
        _showAddressSelectionDialog(addressProvider, cartProvider, authProvider);
        return;
      }
    }

    // Si no hay dirección o es invitado, proceder directamente
    await _executeCheckout(cartProvider, authProvider, null);
  }

  /// Mostrar diálogo de selección de dirección
  void _showAddressSelectionDialog(
    AddressProvider addressProvider,
    CartProvider cartProvider,
    AuthProvider authProvider,
  ) {
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
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'SELECCIONA DIRECCIÓN DE ENVÍO',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: addressProvider.addresses.length,
                  itemBuilder: (context, index) {
                    final address = addressProvider.addresses[index];
                    final isSelected =
                        addressProvider.selectedAddressId == address.id;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        onTap: () {
                          addressProvider.selectAddress(address.id);
                          Navigator.pop(context);
                          _executeCheckout(cartProvider, authProvider, address);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.jdTurquoise
                                  : Colors.transparent,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    address.name,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (isSelected)
                                    const Icon(
                                      Icons.check_circle,
                                      color: AppColors.jdTurquoise,
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                address.fullAddress,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppColors.mediumGray,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                address.phone,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppColors.mediumGray,
                                ),
                              ),
                              if (address.isDefault)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.jdTurquoise,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'Dirección principal',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/addresses');
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('AÑADIR NUEVA DIRECCIÓN'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Ejecutar el checkout con la dirección seleccionada
  /// 1. Procesar pago con Stripe Payment Sheet (in-app)
  /// 2. Solo si el pago es exitoso, crear el pedido en la base de datos
  Future<void> _executeCheckout(
    CartProvider cartProvider,
    AuthProvider authProvider,
    dynamic address,
  ) async {
    setState(() => _isCheckingOut = true);

    try {
      // Obtener email para checkout
      final email = authProvider.checkoutEmail;
      if (email == null) {
        throw Exception('No se pudo obtener el email para el checkout');
      }

      // 1. Procesar pago con Stripe Payment Sheet (sin salir de la app)
      final result = await _stripeService.processPayment(
        items: cartProvider.items,
        totalCents: cartProvider.totalCents,
        email: email,
        customerName: authProvider.user?.username,
        discountCode: cartProvider.discountCode,
        addressId: address?.id,
      );

      if (!mounted) return;

      if (result.cancelled) {
        // El usuario cerró el Payment Sheet, no hacer nada
        return;
      }

      if (!result.success) {
        // Error en el pago
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message ?? 'Error en el pago'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      // 2. Pago exitoso → Crear pedido en la base de datos
      final order = await _orderService.createOrderWithItems(
        items: cartProvider.items,
        totalCents: cartProvider.totalCents,
        email: email,
        addressId: address?.id,
        discountCode: cartProvider.discountCode,
        discountCents: cartProvider.hasDiscount ? cartProvider.discountCents : null,
        paymentMethod: 'stripe',
        paymentIntentId: result.paymentIntentId,
      );

      if (!mounted) return;

      if (order == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pago realizado pero error al registrar el pedido. Contacta con soporte.'),
            backgroundColor: AppColors.error,
            duration: Duration(seconds: 5),
          ),
        );
        return;
      }

      // 3. Todo correcto: limpiar carrito y mostrar confirmación
      cartProvider.clearCart();
      _showPaymentSuccessDialog(order.orderNumber);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCheckingOut = false);
      }
    }
  }

  /// Mostrar diálogo de pago completado con éxito
  void _showPaymentSuccessDialog(String orderNumber) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle,
              color: AppColors.success,
              size: 72,
            ),
            const SizedBox(height: 16),
            Text(
              '¡Pedido realizado!',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Tu pedido $orderNumber se ha procesado correctamente.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            const Text(
              'Puedes ver el estado en "Mis Pedidos".',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.mediumGray, fontSize: 13),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/',
                  (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.jdTurquoise,
              ),
              child: const Text('VOLVER AL INICIO'),
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/orders');
              },
              child: const Text('VER MIS PEDIDOS'),
            ),
          ),
        ],
      ),
    );
  }

  /// Mostrar diálogo de autenticación o modo invitado
  void _showAuthDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 24,
          right: 24,
          top: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),

            Text(
              'Para continuar con la compra',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Inicia sesión o compra como invitado',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Botón iniciar sesión
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/auth');
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: AppColors.jdBlack,
                ),
                child: const Text(
                  'INICIAR SESIÓN',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Divider con texto
            Row(
              children: [
                const Expanded(child: Divider()),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text('o', style: TextStyle(color: Colors.grey[600])),
                ),
                const Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: 12),

            // Comprar como invitado
            const Text(
              'Comprar como invitado',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _guestEmailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                hintText: 'Tu email',
                prefixIcon: Icon(Icons.email_outlined),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () async {
                  final email = _guestEmailController.text.trim();
                  final authProvider = context.read<AuthProvider>();
                  final success = await authProvider.enableGuestMode(email);

                  if (success && mounted) {
                    Navigator.pop(context);
                    _proceedToCheckout();
                  } else if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          authProvider.errorMessage ?? 'Email inválido',
                        ),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'CONTINUAR COMO INVITADO',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = context.watch<CartProvider>();

    return Scaffold(

      appBar: AppBar(
        title: const Text('TU CARRITO'),
        actions: [
          if (cartProvider.isNotEmpty)
            TextButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Vaciar carrito'),
                    content: const Text(
                      '¿Estás seguro de que quieres eliminar todos los productos?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancelar'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          cartProvider.clearCart();
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                        ),
                        child: const Text('Vaciar'),
                      ),
                    ],
                  ),
                );
              },
              child: const Text(
                'VACIAR',
                style: TextStyle(color: AppColors.jdRed),
              ),
            ),
        ],
      ),
      body: cartProvider.isEmpty
          ? _buildEmptyCart(context)
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: cartProvider.items.length + 1,
                    itemBuilder: (context, index) {
                      if (index == cartProvider.items.length) {
                        return _buildDiscountSection();
                      }

                      final item = cartProvider.items[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: AppColors.lightGray,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: item.imageUrl != null
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(
                                          item.imageUrl!,
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.image,
                                        size: 40,
                                        color: AppColors.mediumGray,
                                      ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.name,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (item.size != null) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        'Talla: ${item.size}',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: AppColors.mediumGray,
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 8),
                                    Text(
                                      FormatUtils.formatPrice(item.priceCents),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.jdBlack,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                children: [
                                  Row(
                                    children: [
                                      IconButton(
                                        onPressed: () {
                                          cartProvider.decrementQuantity(
                                            item.id,
                                            size: item.size,
                                          );
                                        },
                                        icon: const Icon(
                                          Icons.remove_circle_outline,
                                        ),
                                        iconSize: 24,
                                      ),
                                      Text(
                                        '${item.quantity}',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: item.quantity < item.stock
                                            ? () {
                                                cartProvider.incrementQuantity(
                                                  item.id,
                                                  size: item.size,
                                                );
                                              }
                                            : null,
                                        icon: const Icon(
                                          Icons.add_circle_outline,
                                        ),
                                        iconSize: 24,
                                      ),
                                    ],
                                  ),
                                  IconButton(
                                    onPressed: () {
                                      cartProvider.removeFromCart(
                                        item.id,
                                        size: item.size,
                                      );
                                    },
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: AppColors.error,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                _buildOrderSummary(cartProvider),
              ],
            ),
    );
  }

  Widget _buildDiscountSection() {
    final cartProvider = context.watch<CartProvider>();

    return Card(
      margin: const EdgeInsets.only(top: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '¿Tienes un código de descuento?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            if (cartProvider.hasDiscount) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.success),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: AppColors.success),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Código: ${cartProvider.discountCode}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${cartProvider.discountPercentage}% de descuento',
                            style: const TextStyle(
                              color: AppColors.success,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        cartProvider.removeDiscount();
                        setState(() {
                          _discountSuccess = null;
                          _discountError = null;
                        });
                      },
                      icon: const Icon(Icons.close, color: AppColors.error),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _discountController,
                      textCapitalization: TextCapitalization.characters,
                      decoration: InputDecoration(
                        hintText: 'Introduce tu código',
                        border: const OutlineInputBorder(),
                        errorText: _discountError,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isApplyingDiscount ? null : _applyDiscount,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                    ),
                    child: _isApplyingDiscount
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('APLICAR'),
                  ),
                ],
              ),
              if (_discountSuccess != null) ...[
                const SizedBox(height: 8),
                Text(
                  _discountSuccess!,
                  style: const TextStyle(color: AppColors.success),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummary(CartProvider cartProvider) {
    return Container(
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
      child: SafeArea(
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Subtotal', style: TextStyle(fontSize: 16)),
                Text(
                  FormatUtils.formatPrice(cartProvider.subtotalCents),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (cartProvider.hasDiscount) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Descuento (${cartProvider.discountPercentage}%)',
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppColors.success,
                    ),
                  ),
                  Text(
                    '-${FormatUtils.formatPrice(cartProvider.discountCents)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Envío', style: TextStyle(fontSize: 16)),
                Text(
                  'GRATIS',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.jdTurquoise,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Text(
                  FormatUtils.formatPrice(cartProvider.totalCents),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.jdBlack,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isCheckingOut ? null : _proceedToCheckout,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: AppColors.jdTurquoise,
                ),
                child: _isCheckingOut
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'PROCEDER AL PAGO',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  'Pago seguro con Stripe',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyCart(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.shopping_cart_outlined,
            size: 100,
            color: AppColors.mediumGray,
          ),
          const SizedBox(height: 24),
          const Text(
            'Tu carrito está vacío',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.jdBlack,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '¡Añade productos para empezar!',
            style: TextStyle(fontSize: 16, color: AppColors.mediumGray),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, '/products'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              backgroundColor: AppColors.jdTurquoise,
            ),
            child: const Text(
              'EXPLORAR PRODUCTOS',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
