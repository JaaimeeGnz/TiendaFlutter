import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/favorites_provider.dart';
import '../../services/order_service.dart';
import '../../models/order.dart';
import '../../widgets/app_drawer.dart';

/// AccountScreen - Pantalla de cuenta de usuario
/// Replica la funcionalidad de AccountNav.tsx de Astro
/// Incluye acceso a pedidos, direcciones, favoritos y panel admin
class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final OrderService _orderService = OrderService();
  List<Order> _recentOrders = [];
  bool _isLoadingOrders = true;

  @override
  void initState() {
    super.initState();
    _loadRecentOrders();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadRecentOrders() async {
    final authProvider = context.read<AuthProvider>();
    if (!authProvider.isAuthenticated) return;

    setState(() => _isLoadingOrders = true);
    try {
      final orders = await _orderService.getUserOrders();
      setState(() {
        _recentOrders = orders.take(3).toList(); // Solo los 3 más recientes
        _isLoadingOrders = false;
      });
    } catch (e) {
      setState(() => _isLoadingOrders = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final favoritesProvider = context.watch<FavoritesProvider>();

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        elevation: 2,
        automaticallyImplyLeading: true,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'MI CUENTA',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: !authProvider.isAuthenticated
          ? _buildNotAuthenticatedView(context)
          : RefreshIndicator(
              onRefresh: _loadRecentOrders,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Perfil
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: AppColors.jdTurquoise,
                            child: Text(
                              authProvider.user!.displayName.isNotEmpty
                                  ? authProvider.user!.displayName[0]
                                        .toUpperCase()
                                  : authProvider.user!.email[0].toUpperCase(),
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            authProvider.user!.displayName.isNotEmpty
                                ? authProvider.user!.displayName
                                : 'Usuario',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            authProvider.user!.email,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.mediumGray,
                            ),
                          ),
                          if (authProvider.isAdmin) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.jdRed.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Administrador',
                                style: TextStyle(
                                  color: AppColors.jdRed,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Pedidos recientes
                  Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(
                          leading: const Icon(Icons.shopping_bag_outlined),
                          title: const Text(
                            'Mis Pedidos',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            Navigator.pushNamed(context, '/orders');
                          },
                        ),
                        if (_isLoadingOrders)
                          const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else if (_recentOrders.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(16),
                            child: Text(
                              'No tienes pedidos aún',
                              style: TextStyle(color: AppColors.mediumGray),
                            ),
                          )
                        else
                          ..._recentOrders.map(
                            (order) => ListTile(
                              dense: true,
                              leading: _getOrderStatusIcon(order.status),
                              title: Text('Pedido #${order.orderNumber}'),
                              subtitle: Text(_getOrderStatusText(order.status)),
                              trailing: Text(
                                '${(order.totalCents / 100).toStringAsFixed(2)}€',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              onTap: () {
                                Navigator.pushNamed(
                                  context,
                                  '/orders/${order.id}',
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Opciones
                  Card(
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(
                            Icons.assignment_return_outlined,
                            color: AppColors.jdTurquoise,
                          ),
                          title: const Text('Mis Devoluciones'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            Navigator.pushNamed(context, '/refunds');
                          },
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.person_outline),
                          title: const Text('Editar Perfil'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            Navigator.pushNamed(context, '/profile-settings');
                          },
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.location_on_outlined),
                          title: const Text('Direcciones'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            Navigator.pushNamed(context, '/addresses');
                          },
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(
                            Icons.favorite_outline,
                            color: Colors.red,
                          ),
                          title: const Text('Favoritos'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (favoritesProvider.favoritesCount > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '${favoritesProvider.favoritesCount}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              const SizedBox(width: 8),
                              const Icon(Icons.chevron_right),
                            ],
                          ),
                          onTap: () {
                            Navigator.pushNamed(context, '/favorites');
                          },
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.settings_outlined),
                          title: const Text('Configuración'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            Navigator.pushNamed(context, '/settings');
                          },
                        ),
                      ],
                    ),
                  ),
                  // Panel de Admin (si es admin)
                  if (authProvider.isAdmin) ...[
                    const SizedBox(height: 16),
                    Card(
                      color: AppColors.jdBlack,
                      child: ListTile(
                        leading: const Icon(
                          Icons.admin_panel_settings,
                          color: Colors.white,
                        ),
                        title: const Text(
                          'Panel de Administración',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: const Text(
                          'Gestionar productos, pedidos y usuarios',
                          style: TextStyle(color: Colors.white70),
                        ),
                        trailing: const Icon(
                          Icons.chevron_right,
                          color: Colors.white,
                        ),
                        onTap: () {
                          Navigator.pushNamed(context, '/admin');
                        },
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  // Cerrar sesión
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.logout, color: AppColors.error),
                      title: const Text(
                        'Cerrar Sesión',
                        style: TextStyle(color: AppColors.error),
                      ),
                      onTap: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Cerrar sesión'),
                            content: const Text(
                              '¿Estás seguro de que quieres cerrar sesión?',
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
                                child: const Text('Cerrar sesión'),
                              ),
                            ],
                          ),
                        );
                        if (confirmed == true && context.mounted) {
                          await authProvider.signOut();
                          if (context.mounted) {
                            Navigator.pushNamedAndRemoveUntil(
                              context,
                              '/login',
                              (route) => false,
                            );
                          }
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _getOrderStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return const Icon(Icons.schedule, color: Colors.orange);
      case 'paid':
        return const Icon(Icons.euro, color: AppColors.success);
      case 'processing':
        return const Icon(Icons.loop, color: Colors.blue);
      case 'shipped':
        return const Icon(Icons.local_shipping, color: AppColors.jdTurquoise);
      case 'delivered':
        return const Icon(Icons.check_circle, color: AppColors.success);
      case 'cancelled':
        return const Icon(Icons.cancel, color: AppColors.error);
      default:
        return const Icon(Icons.help_outline, color: AppColors.mediumGray);
    }
  }

  String _getOrderStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'Pendiente';
      case 'paid':
        return 'Pagado';
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

  Widget _buildNotAuthenticatedView(BuildContext context) {
    // Redirigir al login después de que se construya el frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Navigator.pushNamed(context, '/login');
      }
    });
    return const Center(child: CircularProgressIndicator());
  }
}
