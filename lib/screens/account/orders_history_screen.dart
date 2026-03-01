import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/order.dart';
import '../../services/order_service.dart';
import '../../services/invoice_service.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

/// OrdersHistoryScreen - Historial de pedidos del usuario
/// Replica la funcionalidad de /account/orders de Astro
class OrdersHistoryScreen extends StatefulWidget {
  const OrdersHistoryScreen({super.key});

  @override
  State<OrdersHistoryScreen> createState() => _OrdersHistoryScreenState();
}

class _OrdersHistoryScreenState extends State<OrdersHistoryScreen> {
  final OrderService _orderService = OrderService();
  List<Order> _orders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);

    try {
      _orders = await _orderService.getUserOrders();
    } catch (e) {
      print('Error loading orders: $e');
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: AppBar(title: const Text('MIS PEDIDOS')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _orders.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
              onRefresh: _loadOrders,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _orders.length,
                itemBuilder: (context, index) =>
                    _buildOrderCard(_orders[index]),
              ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined, size: 100, color: Colors.grey[400]),
          const SizedBox(height: 24),
          Text(
            'No tienes pedidos todavía',
            style: TextStyle(fontSize: 20, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            '¡Explora nuestra tienda y haz tu primer pedido!',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(context, '/products');
            },
            child: const Text('VER PRODUCTOS'),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(Order order) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => _showOrderDetails(order),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cabecera con número y estado
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      'Pedido #${order.orderNumber}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildStatusChip(order.status),
                ],
              ),
              const SizedBox(height: 8),

              // Fecha
              Text(
                'Realizado el ${_formatDate(order.createdAt)}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),

              const Divider(height: 24),

              // Items del pedido
              if (order.items.isNotEmpty) ...[
                ...order.items
                    .take(3)
                    .map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            // Imagen
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: item.productImage != null
                                  ? Image.network(
                                      item.productImage!,
                                      width: 50,
                                      height: 50,
                                      fit: BoxFit.cover,
                                    )
                                  : Container(
                                      width: 50,
                                      height: 50,
                                      color: AppColors.lightGray,
                                      child: const Icon(Icons.image),
                                    ),
                            ),
                            const SizedBox(width: 12),
                            // Info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.productName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '${item.quantity} x ${(item.priceCents / 100).toStringAsFixed(2)}€',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                if (order.items.length > 3)
                  Text(
                    '+${order.items.length - 3} productos más',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
              ],

              const Divider(height: 24),

              // Total y acción
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total: ${(order.totalCents / 100).toStringAsFixed(2)}€',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _showOrderDetails(order),
                    icon: const Icon(Icons.visibility),
                    label: const Text('Ver detalles'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color backgroundColor;
    Color textColor;
    String text;
    IconData icon;

    switch (status) {
      case 'pending':
        backgroundColor = Colors.orange.withOpacity(0.1);
        textColor = Colors.orange;
        text = 'Pendiente';
        icon = Icons.schedule;
        break;
      case 'paid':
        backgroundColor = Colors.blue.withOpacity(0.1);
        textColor = Colors.blue;
        text = 'Pagado';
        icon = Icons.payments;
        break;
      case 'shipped':
        backgroundColor = AppColors.jdTurquoise.withOpacity(0.1);
        textColor = AppColors.jdTurquoise;
        text = 'Enviado';
        icon = Icons.local_shipping;
        break;
      case 'delivered':
        backgroundColor = AppColors.success.withOpacity(0.1);
        textColor = AppColors.success;
        text = 'Entregado';
        icon = Icons.check_circle;
        break;
      case 'cancelled':
        backgroundColor = AppColors.error.withOpacity(0.1);
        textColor = AppColors.error;
        text = 'Cancelado';
        icon = Icons.cancel;
        break;
      default:
        backgroundColor = AppColors.lightGray;
        textColor = AppColors.mediumGray;
        text = status;
        icon = Icons.help_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  void _showOrderDetails(Order order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Título
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        'Pedido #${order.orderNumber}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),

              const Divider(),

              // Contenido
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Estado
                    Row(
                      children: [
                        const Text('Estado: ', style: TextStyle(fontSize: 16)),
                        _buildStatusChip(order.status),
                      ],
                    ),
                    const SizedBox(height: 6),

                    Text(
                      'Fecha: ${_formatDate(order.createdAt)} a las ${order.createdAt.hour}:${order.createdAt.minute.toString().padLeft(2, '0')}',
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),

                    const SizedBox(height: 20),

                    // Stepper visual del estado del envío
                    _buildOrderStatusStepper(order.status),

                    const SizedBox(height: 24),
                    const Text(
                      'Productos',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Lista de productos
                    if (order.items.isEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.orange[700], size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Los detalles de los productos no están disponibles para este pedido.',
                                style: TextStyle(fontSize: 13, color: Colors.orange[800]),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ...order.items.map(
                      (item) => Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.jdGray,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: item.productImage != null
                                  ? Image.network(
                                      item.productImage!,
                                      width: 60,
                                      height: 60,
                                      fit: BoxFit.cover,
                                    )
                                  : Container(
                                      width: 60,
                                      height: 60,
                                      color: AppColors.lightGray,
                                      child: const Icon(Icons.image),
                                    ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.productName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (item.size != null)
                                    Text(
                                      'Talla: ${item.size}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  Text(
                                    '${item.quantity} x ${(item.priceCents / 100).toStringAsFixed(2)}€',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '${((item.priceCents * item.quantity) / 100).toStringAsFixed(2)}€',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const Divider(height: 32),

                    // Resumen de pago
                    const Text(
                      'Resumen',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    _buildSummaryRow(
                      'Subtotal',
                      order.items.isNotEmpty
                          ? order.items.fold<int>(
                              0,
                              (sum, item) => sum + (item.priceCents * item.quantity),
                            )
                          : order.totalCents - order.shippingCents + (order.discountCents ?? 0),
                    ),
                    _buildSummaryRow('Envío', order.shippingCents),
                    if (order.discountCents != null && order.discountCents! > 0)
                      _buildSummaryRow(
                        'Descuento',
                        -order.discountCents!,
                        isDiscount: true,
                      ),

                    const Divider(height: 16),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${(order.totalCents / 100).toStringAsFixed(2)}€',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.jdTurquoise,
                          ),
                        ),
                      ],
                    ),

                    if (order.discountCode != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Código aplicado: ${order.discountCode}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.success,
                          ),
                        ),
                      ),
                    ],

                    // Dirección de envío
                    if (order.shippingAddress != null) ...[
                      const SizedBox(height: 24),
                      const Text(
                        'Dirección de envío',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.jdGray,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              order.shippingAddress!.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(order.shippingAddress!.street),
                            Text(
                              '${order.shippingAddress!.postalCode} ${order.shippingAddress!.city}',
                            ),
                            Text(
                              '${order.shippingAddress!.state}, ${order.shippingAddress!.country}',
                            ),
                            if (order.shippingAddress!.phone.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text('Tel: ${order.shippingAddress!.phone}'),
                            ],
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 12),

                    // Botón descargar factura
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          try {
                            await InvoiceService.shareInvoice(order);
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error al generar la factura: $e'),
                                  backgroundColor: AppColors.error,
                                ),
                              );
                            }
                          }
                        },
                        icon: const Icon(Icons.download),
                        label: const Text('DESCARGAR FACTURA'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.jdTurquoise,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Cancelar pedido (pending o paid)
                    if (order.status == 'pending' || order.status == 'paid')
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => _showCancelDialog(context, order),
                          icon: const Icon(Icons.cancel_outlined, color: AppColors.error),
                          label: const Text(
                            'CANCELAR PEDIDO',
                            style: TextStyle(color: AppColors.error),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.error),
                          ),
                        ),
                      ),

                    // Solicitar devolución (entregado)
                    if (order.status == 'delivered')
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => _showRefundDialog(context, order),
                          icon: const Icon(Icons.assignment_return_outlined),
                          label: const Text('SOLICITAR DEVOLUCIÓN'),
                        ),
                      ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, int cents, {bool isDiscount = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            '${isDiscount ? '-' : ''}${(cents.abs() / 100).toStringAsFixed(2)}€',
            style: TextStyle(color: isDiscount ? AppColors.success : null),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'enero',
      'febrero',
      'marzo',
      'abril',
      'mayo',
      'junio',
      'julio',
      'agosto',
      'septiembre',
      'octubre',
      'noviembre',
      'diciembre',
    ];
    return '${date.day} de ${months[date.month - 1]} de ${date.year}';
  }

  // ── CANCELAR PEDIDO ──────────────────────────────────────────────────────
  void _showCancelDialog(BuildContext ctx, Order order) {
    const reasons = [
      'Cambié de opinión',
      'Encontré mejor precio',
      'El envío tarda demasiado',
      'Pedí el artículo equivocado',
      'Problemas con el pago',
      'Otro motivo',
    ];
    String selectedReason = reasons[0];
    bool isCancelling = false;

    showDialog(
      context: ctx,
      barrierDismissible: true,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (dialogCtx, setD) {
            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.cancel_outlined, color: AppColors.error),
                  SizedBox(width: 8),
                  Text('Cancelar pedido'),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pedido #${order.orderNumber}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Esta acción cancelará el pedido. Si ya fue pagado, el dinero será reembolsado en 5-7 días hábiles al método de pago original.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '¿Cuál es el motivo de la cancelación?',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    ...reasons.map(
                      (r) => RadioListTile<String>(
                        title: Text(r, style: const TextStyle(fontSize: 13)),
                        value: r,
                        groupValue: selectedReason,
                        dense: true,
                        activeColor: AppColors.error,
                        onChanged: isCancelling
                            ? null
                            : (v) => setD(() => selectedReason = v!),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed:
                      isCancelling ? null : () => Navigator.pop(dialogCtx),
                  child: const Text('VOLVER'),
                ),
                ElevatedButton(
                  onPressed: isCancelling
                      ? null
                      : () async {
                          setD(() => isCancelling = true);
                          final ok =
                              await _orderService.cancelOrder(order.id);
                          if (!mounted) return;
                          Navigator.pop(dialogCtx); // cierra diálogo
                          Navigator.pop(ctx); // cierra bottom sheet
                          if (ok) {
                            setState(() =>
                                _orders.removeWhere((o) => o.id == order.id));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Pedido cancelado. El dinero será reembolsado en 5-7 días hábiles.',
                                ),
                                backgroundColor: AppColors.success,
                                duration: Duration(seconds: 4),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Error al cancelar el pedido'),
                                backgroundColor: AppColors.error,
                              ),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error),
                  child: isCancelling
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('CONFIRMAR CANCELACIÓN'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ── SOLICITAR DEVOLUCIÓN (2 pasos como Astro) ────────────────────────────
  void _showRefundDialog(BuildContext ctx, Order order) {
    // Paso 1: selección de productos, Paso 2: motivo
    String step = 'items';
    final selected = <int, bool>{};
    for (int i = 0; i < order.items.length; i++) {
      selected[i] = false;
    }
    String selectedReason = '';
    bool isSending = false;

    final authProvider = Provider.of<AuthProvider>(ctx, listen: false);
    final email = authProvider.checkoutEmail ??
        authProvider.user?.email ??
        '';

    const reasons = [
      'Producto defectuoso o dañado',
      'Talla incorrecta',
      'No coincide con la descripción',
      'Recibí un producto equivocado',
      'No estoy satisfecho con la calidad',
      'Otro motivo',
    ];

    showDialog(
      context: ctx,
      barrierDismissible: true,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (dialogCtx, setD) {
            final hasSelection = selected.values.any((v) => v);
            final totalRefundCents = order.items.asMap().entries.fold<int>(
              0,
              (sum, e) => selected[e.key] == true
                  ? sum + (e.value.priceCents * e.value.quantity)
                  : sum,
            );
            final allSelected = selected.values.every((v) => v);

            return AlertDialog(
              titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              actionsPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(Icons.assignment_return_outlined,
                        color: Colors.orange.shade700, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Solicitar Devolución',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        Text(
                          step == 'items'
                              ? 'Selecciona los productos a devolver'
                              : 'Indica el motivo de la devolución',
                          style: const TextStyle(
                              fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: step == 'items'
                      ? _buildRefundStepItems(
                          order: order,
                          selected: selected,
                          allSelected: allSelected,
                          hasSelection: hasSelection,
                          totalRefundCents: totalRefundCents,
                          onToggleAll: () {
                            final newVal = !allSelected;
                            for (int i = 0; i < order.items.length; i++) {
                              selected[i] = newVal;
                            }
                            setD(() {});
                          },
                          onToggle: (idx) {
                            selected[idx] = !(selected[idx] ?? false);
                            setD(() {});
                          },
                        )
                      : _buildRefundStepReason(
                          reasons: reasons,
                          selectedReason: selectedReason,
                          totalRefundCents: totalRefundCents,
                          isSending: isSending,
                          onSelectReason: (r) {
                            setD(() => selectedReason = r);
                          },
                        ),
                ),
              ),
              actions: step == 'items'
                  ? [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogCtx),
                        child: const Text('CANCELAR'),
                      ),
                      ElevatedButton(
                        onPressed: hasSelection
                            ? () => setD(() => step = 'reason')
                            : null,
                        child: const Text('CONTINUAR'),
                      ),
                    ]
                  : [
                      TextButton(
                        onPressed: isSending
                            ? null
                            : () => setD(() => step = 'items'),
                        child: const Text('ATRÁS'),
                      ),
                      ElevatedButton(
                        onPressed: (selectedReason.isEmpty || isSending)
                            ? null
                            : () async {
                                setD(() => isSending = true);
                                // Solo los items seleccionados
                                final selectedItems = <OrderItem>[];
                                for (int i = 0;
                                    i < order.items.length;
                                    i++) {
                                  if (selected[i] == true) {
                                    selectedItems.add(order.items[i]);
                                  }
                                }
                                final ok =
                                    await _orderService.requestRefund(
                                  orderId: order.id,
                                  reason: selectedReason,
                                  customerEmail: email,
                                  items: selectedItems,
                                );
                                if (!mounted) return;
                                Navigator.pop(dialogCtx);
                                Navigator.pop(ctx);
                                if (ok) {
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Devolución procesada. Se reembolsarán '
                                        '${(totalRefundCents / 100).toStringAsFixed(2)}€ '
                                        'en 5-7 días hábiles.',
                                      ),
                                      backgroundColor: AppColors.success,
                                      duration:
                                          const Duration(seconds: 4),
                                    ),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Error al solicitar la devolución'),
                                      backgroundColor: AppColors.error,
                                    ),
                                  );
                                }
                              },
                        child: isSending
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('CONFIRMAR DEVOLUCIÓN'),
                      ),
                    ],
            );
          },
        );
      },
    );
  }

  /// Paso 1: selección de productos con checkboxes
  Widget _buildRefundStepItems({
    required Order order,
    required Map<int, bool> selected,
    required bool allSelected,
    required bool hasSelection,
    required int totalRefundCents,
    required VoidCallback onToggleAll,
    required void Function(int) onToggle,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Seleccionar todos
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Productos del pedido',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            GestureDetector(
              onTap: onToggleAll,
              child: Text(
                allSelected ? 'Deseleccionar todos' : 'Seleccionar todos',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Lista de productos
        ...order.items.asMap().entries.map((e) {
          final idx = e.key;
          final item = e.value;
          final isSelected = selected[idx] ?? false;
          final itemTotal =
              (item.priceCents * item.quantity / 100).toStringAsFixed(2);
          return GestureDetector(
            onTap: () => onToggle(idx),
            child: Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                border: Border.all(
                  color: isSelected
                      ? Colors.orange.shade600
                      : Colors.grey.shade300,
                  width: isSelected ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(10),
                color: isSelected ? Colors.orange.shade50 : Colors.transparent,
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: Checkbox(
                      value: isSelected,
                      onChanged: (_) => onToggle(idx),
                      activeColor: Colors.orange.shade600,
                      materialTapTargetSize:
                          MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.productName,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${item.size != null ? 'Talla: ${item.size} · ' : ''}'
                          'Cant: ${item.quantity} · '
                          '${(item.priceCents / 100).toStringAsFixed(2)}€/ud',
                          style: const TextStyle(
                              fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '$itemTotal€',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ],
              ),
            ),
          );
        }),
        // Importe a devolver
        if (hasSelection) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              border: Border.all(color: Colors.orange.shade200),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Importe a devolver:',
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: Colors.orange.shade800)),
                Text(
                  '${(totalRefundCents / 100).toStringAsFixed(2)}€',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.orange.shade700),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  /// Paso 2: selección de motivo
  Widget _buildRefundStepReason({
    required List<String> reasons,
    required String selectedReason,
    required int totalRefundCents,
    required bool isSending,
    required void Function(String) onSelectReason,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...reasons.map(
          (r) => GestureDetector(
            onTap: isSending ? null : () => onSelectReason(r),
            child: Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                border: Border.all(
                  color: selectedReason == r
                      ? Colors.orange.shade600
                      : Colors.grey.shade300,
                  width: selectedReason == r ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(10),
                color: selectedReason == r
                    ? Colors.orange.shade50
                    : Colors.transparent,
              ),
              child: Row(
                children: [
                  Radio<String>(
                    value: r,
                    groupValue: selectedReason,
                    onChanged:
                        isSending ? null : (v) => onSelectReason(v!),
                    activeColor: Colors.orange.shade600,
                    materialTapTargetSize:
                        MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(r,
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w500)),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            border: Border.all(color: Colors.orange.shade200),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Reembolso total:',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: Colors.orange.shade800)),
                  Text(
                    '${(totalRefundCents / 100).toStringAsFixed(2)}€',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.orange.shade700),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'El reembolso se procesará en 5-7 días hábiles',
                style: TextStyle(
                    fontSize: 11, color: Colors.orange.shade700),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Stepper visual de 4 estados: Pendiente → Pagado → Enviado → Entregado
  Widget _buildOrderStatusStepper(String status) {
    if (status == 'cancelled') {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.error.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cancel, color: AppColors.error),
            SizedBox(width: 8),
            Text(
              'PEDIDO CANCELADO',
              style: TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    const steps = [
      {'key': 'pending', 'label': 'Pendiente'},
      {'key': 'paid', 'label': 'Pagado'},
      {'key': 'shipped', 'label': 'Enviado'},
      {'key': 'delivered', 'label': 'Entregado'},
    ];

    final currentIndex = steps.indexWhere((s) => s['key'] == status);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
      decoration: BoxDecoration(
        color: AppColors.jdGray,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: steps.asMap().entries.map((entry) {
          final index = entry.key;
          final step = entry.value;
          final isCompleted = currentIndex >= 0 && index <= currentIndex;

          return Expanded(
            child: Column(
              children: [
                Row(
                  children: [
                    if (index > 0)
                      Expanded(
                        child: Container(
                          height: 2,
                          color: index <= currentIndex
                              ? AppColors.success
                              : Colors.grey.shade300,
                        ),
                      ),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isCompleted
                            ? AppColors.success
                            : Colors.grey.shade300,
                      ),
                      child: Icon(
                        Icons.check,
                        size: 20,
                        color: isCompleted ? Colors.white : Colors.grey.shade400,
                      ),
                    ),
                    if (index < steps.length - 1)
                      Expanded(
                        child: Container(
                          height: 2,
                          color: index < currentIndex
                              ? AppColors.success
                              : Colors.grey.shade300,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  step['label']!,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight:
                        isCompleted ? FontWeight.bold : FontWeight.normal,
                    color: isCompleted ? AppColors.success : Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
