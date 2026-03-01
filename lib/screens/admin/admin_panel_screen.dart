import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/product_service.dart';
import '../../services/order_service.dart';
import '../../services/contact_message_service.dart';
import '../../services/invoice_admin_service.dart';
import '../../services/invoice_service.dart';
import '../../models/product.dart';
import '../../models/order.dart';
import '../../models/contact_message.dart';
import '../../models/invoice.dart';
import '../../models/refund.dart';

/// AdminPanelScreen - Panel de administración
/// Replica la funcionalidad de /admin de Astro
/// Solo accesible para usuarios con email de administrador
class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ProductService _productService = ProductService();
  final OrderService _orderService = OrderService();
  final ContactMessageService _contactMessageService = ContactMessageService();
  final InvoiceAdminService _invoiceAdminService = InvoiceAdminService();

  List<Product> _products = [];
  List<Order> _orders = [];
  List<ContactMessage> _messages = [];
  List<Invoice> _invoices = [];
  List<Refund> _refunds = [];
  bool _isLoading = true;

  // Estadísticas
  int _totalProducts = 0;
  int _totalOrders = 0;
  int _pendingOrders = 0;
  int _totalRevenueCents = 0;
  int _newMessagesCount = 0;
  Map<String, dynamic> _financialSummary = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // Cargar productos
      _products = await _productService.getAllProducts();
      _totalProducts = _products.length;

      // Cargar pedidos (admin puede ver todos)
      _orders = await _orderService.getAllOrders();
      _totalOrders = _orders.length;
      _pendingOrders = _orders.where((o) => o.status == 'pending').length;
      _totalRevenueCents = _orders
          .where((o) => o.status != 'cancelled')
          .fold(0, (sum, o) => sum + o.totalCents);

      // Cargar mensajes de contacto/reportes
      _messages = await _contactMessageService.getAllMessages();
      _newMessagesCount = _messages.where((m) => m.status == 'new').length;

      // Cargar facturas y devoluciones
      _invoices = await _invoiceAdminService.getAllInvoices();
      _refunds = await _invoiceAdminService.getAllRefunds();
      _financialSummary = await _invoiceAdminService.getFinancialSummary();
    } catch (e) {
      print('Error loading admin data: $e');
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    // Verificar si es admin
    if (!authProvider.isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Acceso Denegado')),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock, size: 80, color: AppColors.error),
              SizedBox(height: 24),
              Text(
                'No tienes permisos de administrador',
                style: TextStyle(fontSize: 18),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(

      appBar: AppBar(
        title: const Text('PANEL DE ADMINISTRACIÓN'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Dashboard'),
            Tab(icon: Icon(Icons.inventory), text: 'Productos'),
            Tab(icon: Icon(Icons.receipt_long), text: 'Pedidos'),
            Tab(icon: Icon(Icons.bug_report), text: 'Reportes'),
            Tab(icon: Icon(Icons.description), text: 'Facturas'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildDashboardTab(),
                _buildProductsTab(),
                _buildOrdersTab(),
                _buildReportsTab(),
                _buildInvoicesTab(),
              ],
            ),
      floatingActionButton: _tabController.index == 1
          ? FloatingActionButton(
              onPressed: () {
                // Navegar a crear producto
                Navigator.pushNamed(context, '/admin/products/new');
              },
              backgroundColor: AppColors.jdTurquoise,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  /// Tab de Dashboard con estadísticas
  Widget _buildDashboardTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Tarjetas de estadísticas
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.3,
            children: [
              _buildStatCard(
                'Productos',
                '$_totalProducts',
                Icons.inventory_2,
                AppColors.jdTurquoise,
              ),
              _buildStatCard(
                'Pedidos',
                '$_totalOrders',
                Icons.shopping_bag,
                Colors.blue,
              ),
              _buildStatCard(
                'Pendientes',
                '$_pendingOrders',
                Icons.pending_actions,
                Colors.orange,
              ),
              _buildStatCard(
                'Ingresos',
                '${(_totalRevenueCents / 100).toStringAsFixed(2)}€',
                Icons.euro,
                AppColors.success,
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Pedidos recientes
          Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Pedidos Recientes',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                const Divider(height: 1),
                if (_orders.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: Text('No hay pedidos')),
                  )
                else
                  ..._orders
                      .take(5)
                      .map(
                        (order) => ListTile(
                          leading: _getOrderStatusIcon(order.status),
                          title: Text('Pedido #${order.orderNumber}'),
                          subtitle: Text(order.userEmail ?? 'Sin email'),
                          trailing: Text(
                            '${(order.totalCents / 100).toStringAsFixed(2)}€',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              '/admin/orders/${order.id}',
                            );
                          },
                        ),
                      ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Productos con bajo stock
          Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Productos con Bajo Stock',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                const Divider(height: 1),
                ..._products
                    .where((p) => p.stock <= 5)
                    .take(5)
                    .map(
                      (product) => ListTile(
                        leading: CircleAvatar(
                          backgroundImage: product.images.isNotEmpty
                              ? NetworkImage(product.images.first)
                              : null,
                          backgroundColor: AppColors.lightGray,
                          child: product.images.isEmpty
                              ? const Icon(Icons.image)
                              : null,
                        ),
                        title: Text(product.name),
                        subtitle: Text(
                          product.stock == 0
                              ? 'Agotado'
                              : '${product.stock} unidades',
                          style: TextStyle(
                            color: product.stock == 0
                                ? AppColors.error
                                : Colors.orange,
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () {
                            Navigator.pushNamed(
                              context,
                              '/admin/products/${product.id}',
                            );
                          },
                        ),
                      ),
                    ),
                if (_products.where((p) => p.stock <= 5).isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(
                      child: Text('No hay productos con bajo stock'),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(
              title,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  /// Tab de productos
  Widget _buildProductsTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _products.length,
        itemBuilder: (context, index) {
          final product = _products[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: CircleAvatar(
                backgroundImage: product.images.isNotEmpty
                    ? NetworkImage(product.images.first)
                    : null,
                backgroundColor: AppColors.lightGray,
                child: product.images.isEmpty ? const Icon(Icons.image) : null,
              ),
              title: Text(product.name),
              subtitle: Row(
                children: [
                  Text('${(product.priceCents / 100).toStringAsFixed(2)}€'),
                  const SizedBox(width: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: product.stock > 0
                          ? AppColors.success.withOpacity(0.1)
                          : AppColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      product.stock > 0 ? '${product.stock} uds' : 'Agotado',
                      style: TextStyle(
                        fontSize: 12,
                        color: product.stock > 0
                            ? AppColors.success
                            : AppColors.error,
                      ),
                    ),
                  ),
                  if (product.isOnSale) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.jdRed,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'OFERTA',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              trailing: PopupMenuButton(
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit),
                        SizedBox(width: 8),
                        Text('Editar'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: AppColors.error),
                        SizedBox(width: 8),
                        Text(
                          'Eliminar',
                          style: TextStyle(color: AppColors.error),
                        ),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) async {
                  if (value == 'edit') {
                    Navigator.pushNamed(
                      context,
                      '/admin/products/${product.id}',
                    );
                  } else if (value == 'delete') {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Eliminar producto'),
                        content: Text(
                          '¿Estás seguro de que quieres eliminar "${product.name}"?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancelar'),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.error,
                            ),
                            child: const Text('Eliminar'),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await _productService.deleteProduct(product.id);
                      _loadData();
                    }
                  }
                },
              ),
            ),
          );
        },
      ),
    );
  }

  /// Tab de pedidos
  Widget _buildOrdersTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _orders.length,
        itemBuilder: (context, index) {
          final order = _orders[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: _getOrderStatusIcon(order.status),
              title: Text('Pedido #${order.orderNumber}'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(order.userEmail ?? 'Sin email'),
                  Text(
                    _getOrderStatusText(order.status),
                    style: TextStyle(color: _getOrderStatusColor(order.status)),
                  ),
                ],
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${(order.totalCents / 100).toStringAsFixed(2)}€',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    _formatDate(order.createdAt),
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
              isThreeLine: true,
              onTap: () {
                Navigator.pushNamed(context, '/admin/orders/${order.id}');
              },
            ),
          );
        },
      ),
    );
  }

  Widget _getOrderStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return const CircleAvatar(
          backgroundColor: Colors.orange,
          child: Icon(Icons.schedule, color: Colors.white, size: 20),
        );
      case 'processing':
        return const CircleAvatar(
          backgroundColor: Colors.blue,
          child: Icon(Icons.loop, color: Colors.white, size: 20),
        );
      case 'shipped':
        return CircleAvatar(
          backgroundColor: AppColors.jdTurquoise,
          child: const Icon(
            Icons.local_shipping,
            color: Colors.white,
            size: 20,
          ),
        );
      case 'delivered':
        return CircleAvatar(
          backgroundColor: AppColors.success,
          child: const Icon(Icons.check_circle, color: Colors.white, size: 20),
        );
      case 'cancelled':
        return CircleAvatar(
          backgroundColor: AppColors.error,
          child: const Icon(Icons.cancel, color: Colors.white, size: 20),
        );
      default:
        return const CircleAvatar(
          backgroundColor: AppColors.mediumGray,
          child: Icon(Icons.help_outline, color: Colors.white, size: 20),
        );
    }
  }

  String _getOrderStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'Pendiente';
      case 'processing':
        return 'Procesando';
      case 'shipped':
        return 'Enviado';
      case 'delivered':
        return 'Entregado';
      case 'cancelled':
        return 'Cancelado';
      default:
        return status;
    }
  }

  Color _getOrderStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'processing':
        return Colors.blue;
      case 'shipped':
        return AppColors.jdTurquoise;
      case 'delivered':
        return AppColors.success;
      case 'cancelled':
        return AppColors.error;
      default:
        return AppColors.mediumGray;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  /// Tab de Reportes de contacto
  /// Replica: admin/reportes.astro de tiendaOnline
  Widget _buildReportsTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: _messages.isEmpty
          ? ListView(
              children: const [
                SizedBox(height: 100),
                Center(
                  child: Column(
                    children: [
                      Icon(Icons.inbox, size: 64, color: AppColors.mediumGray),
                      SizedBox(height: 16),
                      Text(
                        'No hay mensajes',
                        style: TextStyle(fontSize: 16, color: AppColors.mediumGray),
                      ),
                    ],
                  ),
                ),
              ],
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getMessageStatusColor(msg.status),
                      child: Icon(
                        _getMessageStatusIcon(msg.status),
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      msg.subject,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: msg.status == 'new'
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${msg.name} • ${msg.email}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: _getMessageStatusColor(msg.status)
                                    .withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                msg.statusDisplay,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: _getMessageStatusColor(msg.status),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _formatDate(msg.createdAt),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    isThreeLine: true,
                    trailing: PopupMenuButton<String>(
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'view',
                          child: Row(
                            children: [
                              Icon(Icons.visibility),
                              SizedBox(width: 8),
                              Text('Ver detalles'),
                            ],
                          ),
                        ),
                        if (msg.status == 'new')
                          const PopupMenuItem(
                            value: 'read',
                            child: Row(
                              children: [
                                Icon(Icons.mark_email_read),
                                SizedBox(width: 8),
                                Text('Marcar como leído'),
                              ],
                            ),
                          ),
                        if (msg.status != 'resolved')
                          const PopupMenuItem(
                            value: 'resolved',
                            child: Row(
                              children: [
                                Icon(Icons.check_circle, color: AppColors.success),
                                SizedBox(width: 8),
                                Text('Marcar como resuelto'),
                              ],
                            ),
                          ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, color: AppColors.error),
                              SizedBox(width: 8),
                              Text(
                                'Eliminar',
                                style: TextStyle(color: AppColors.error),
                              ),
                            ],
                          ),
                        ),
                      ],
                      onSelected: (value) async {
                        if (value == 'view') {
                          _showMessageDetailDialog(msg);
                        } else if (value == 'read' || value == 'resolved') {
                          final success = await _contactMessageService
                              .updateMessageStatus(msg.id, value!);
                          if (success) _loadData();
                        } else if (value == 'delete') {
                          _confirmDeleteMessage(msg);
                        }
                      },
                    ),
                    onTap: () => _showMessageDetailDialog(msg),
                  ),
                );
              },
            ),
    );
  }

  void _showMessageDetailDialog(ContactMessage msg) {
    // Marcar como leído automáticamente si es nuevo
    if (msg.status == 'new') {
      _contactMessageService.updateMessageStatus(msg.id, 'read');
      _loadData();
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(msg.subject),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Nombre', msg.name),
              const SizedBox(height: 8),
              _buildDetailRow('Email', msg.email),
              const SizedBox(height: 8),
              _buildDetailRow('Estado', msg.statusDisplay),
              const SizedBox(height: 8),
              _buildDetailRow('Fecha', _formatDate(msg.createdAt)),
              const SizedBox(height: 16),
              const Text(
                'Mensaje:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.mediumGray,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(msg.message),
              ),
              if (msg.adminNotes != null && msg.adminNotes!.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'Notas admin:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.mediumGray,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(msg.adminNotes!),
                ),
              ],
            ],
          ),
        ),
        actions: [
          if (msg.status != 'resolved')
            TextButton.icon(
              onPressed: () async {
                await _contactMessageService.updateMessageStatus(
                  msg.id,
                  'resolved',
                );
                Navigator.pop(context);
                _loadData();
              },
              icon: const Icon(Icons.check_circle, color: AppColors.success),
              label: const Text('Resolver'),
            ),
          TextButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              _confirmDeleteMessage(msg);
            },
            icon: const Icon(Icons.delete, color: AppColors.error),
            label: const Text(
              'Eliminar',
              style: TextStyle(color: AppColors.error),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteMessage(ContactMessage msg) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar mensaje'),
        content: Text(
          '¿Estás seguro de que quieres eliminar el mensaje de "${msg.name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      final success = await _contactMessageService.deleteMessage(msg.id);
      if (success) {
        _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Mensaje eliminado'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      }
    }
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 70,
          child: Text(
            '$label:',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.mediumGray,
            ),
          ),
        ),
        Expanded(child: Text(value)),
      ],
    );
  }

  Color _getMessageStatusColor(String status) {
    switch (status) {
      case 'new':
        return Colors.blue;
      case 'read':
        return Colors.orange;
      case 'resolved':
        return AppColors.success;
      case 'spam':
        return AppColors.mediumGray;
      default:
        return AppColors.mediumGray;
    }
  }

  IconData _getMessageStatusIcon(String status) {
    switch (status) {
      case 'new':
        return Icons.mark_email_unread;
      case 'read':
        return Icons.mark_email_read;
      case 'resolved':
        return Icons.check_circle;
      case 'spam':
        return Icons.report;
      default:
        return Icons.email;
    }
  }

  // ══════════════════════════════════════════════════════════════════
  // ═══  TAB DE FACTURAS (Resumen · Facturas · Devoluciones)  ═════
  // ══════════════════════════════════════════════════════════════════

  Widget _buildInvoicesTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Resumen financiero ──
          const Text(
            'Resumen Financiero',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.4,
            children: [
              _buildStatCard(
                'Total Facturado',
                '${((_financialSummary['totalInvoicedCents'] ?? 0) / 100).toStringAsFixed(2)}€',
                Icons.trending_up,
                AppColors.jdTurquoise,
              ),
              _buildStatCard(
                'Neto',
                '${((_financialSummary['netRevenueCents'] ?? 0) / 100).toStringAsFixed(2)}€',
                Icons.account_balance,
                Colors.black87,
              ),
              _buildStatCard(
                'Devoluciones',
                '${_financialSummary['totalRefunds'] ?? 0}',
                Icons.assignment_return,
                Colors.orange,
              ),
              _buildStatCard(
                'Dinero Devuelto',
                '${((_financialSummary['totalRefundedCents'] ?? 0) / 100).toStringAsFixed(2)}€',
                Icons.trending_down,
                AppColors.error,
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ── Lista de Facturas ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Facturas',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Text(
                '${_invoices.length} total',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_invoices.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.description_outlined, size: 48, color: Colors.grey[400]),
                      const SizedBox(height: 12),
                      Text('No hay facturas', style: TextStyle(color: Colors.grey[600])),
                    ],
                  ),
                ),
              ),
            )
          else
            ..._invoices.map((invoice) => _buildInvoiceCard(invoice)),

          const SizedBox(height: 24),

          // ── Lista de Devoluciones ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Devoluciones',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Text(
                '${_refunds.length} total',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_refunds.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.assignment_return_outlined, size: 48, color: Colors.grey[400]),
                      const SizedBox(height: 12),
                      Text('No hay devoluciones', style: TextStyle(color: Colors.grey[600])),
                    ],
                  ),
                ),
              ),
            )
          else
            ..._refunds.map((refund) => _buildRefundCard(refund)),
        ],
      ),
    );
  }

  Widget _buildInvoiceCard(Invoice invoice) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.jdTurquoise,
          child: const Icon(
            Icons.description,
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          invoice.invoiceNumber,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(invoice.customerName.isNotEmpty
                ? '${invoice.customerName} • ${invoice.customerEmail}'
                : invoice.customerEmail),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getInvoiceStatusColor(invoice.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    invoice.statusDisplay,
                    style: TextStyle(
                      fontSize: 11,
                      color: _getInvoiceStatusColor(invoice.status),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _formatDate(invoice.issuedAt),
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
        isThreeLine: true,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${(invoice.totalCents / 100).toStringAsFixed(2)}€',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.download, color: AppColors.jdTurquoise),
              tooltip: 'Descargar PDF',
              onPressed: () => _downloadInvoicePdf(invoice),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRefundCard(Refund refund) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getRefundStatusColor(refund.status),
          child: const Icon(Icons.assignment_return, color: Colors.white, size: 20),
        ),
        title: Text(
          'Devolución - ${refund.orderId.length > 8 ? refund.orderId.substring(0, 8) : refund.orderId}...',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(refund.customerName.isNotEmpty
                ? '${refund.customerName} • ${refund.customerEmail}'
                : refund.customerEmail),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getRefundStatusColor(refund.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    refund.statusText,
                    style: TextStyle(
                      fontSize: 11,
                      color: _getRefundStatusColor(refund.status),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _formatDate(refund.createdAt),
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
        isThreeLine: true,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${(refund.refundAmountCents / 100).toStringAsFixed(2)}€',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.download, color: Colors.orange),
              tooltip: 'Descargar PDF',
              onPressed: () => _downloadRefundPdf(refund),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _downloadInvoicePdf(Invoice invoice) async {
    try {
      await InvoiceService.shareInvoiceFromModel(invoice);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al generar PDF: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _downloadRefundPdf(Refund refund) async {
    try {
      await InvoiceService.shareRefundInvoice(refund);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al generar PDF: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Color _getInvoiceStatusColor(String status) {
    switch (status) {
      case 'paid':
        return AppColors.success;
      case 'issued':
        return Colors.blue;
      case 'cancelled':
        return AppColors.error;
      case 'draft':
        return AppColors.mediumGray;
      default:
        return AppColors.mediumGray;
    }
  }

  Color _getRefundStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'approved':
      case 'processed':
        return AppColors.success;
      case 'rejected':
        return AppColors.error;
      default:
        return AppColors.mediumGray;
    }
  }
}
