import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/address_provider.dart';
import '../../models/address.dart';
import 'address_form_dialog.dart';

/// AddressesScreen - Pantalla de gestión de direcciones de envío
/// Permite listar, agregar, editar y eliminar direcciones
class AddressesScreen extends StatefulWidget {
  const AddressesScreen({super.key});

  @override
  State<AddressesScreen> createState() => _AddressesScreenState();
}

class _AddressesScreenState extends State<AddressesScreen> {
  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  void _loadAddresses() {
    final authProvider = context.read<AuthProvider>();
    final addressProvider = context.read<AddressProvider>();

    if (authProvider.isAuthenticated && authProvider.user != null) {
      addressProvider.loadAddresses(authProvider.user!.id);
    }
  }

  void _showAddressForm({Address? address}) {
    showDialog(
      context: context,
      builder: (context) => AddressFormDialog(address: address),
    ).then((_) => _loadAddresses());
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final addressProvider = context.watch<AddressProvider>();

    // Si no está autenticado
    if (!authProvider.isAuthenticated) {
      return Scaffold(
        appBar: AppBar(title: const Text('MIS DIRECCIONES')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 100,
                color: AppColors.mediumGray,
              ),
              const SizedBox(height: 24),
              const Text(
                'Inicia sesión para ver tus direcciones',
                style: TextStyle(fontSize: 18, color: AppColors.mediumGray),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/login');
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  backgroundColor: AppColors.jdTurquoise,
                ),
                child: const Text(
                  'INICIAR SESIÓN',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(

      appBar: AppBar(title: const Text('MIS DIRECCIONES'), elevation: 0),
      body: addressProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : addressProvider.isEmpty
          ? _buildEmptyState(context)
          : _buildAddressesList(context, addressProvider),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddressForm(),
        backgroundColor: AppColors.jdTurquoise,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.location_on_outlined,
            size: 80,
            color: AppColors.mediumGray,
          ),
          const SizedBox(height: 16),
          const Text(
            'No tienes direcciones guardadas',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.jdBlack,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Añade una dirección para empezar',
            style: TextStyle(fontSize: 14, color: AppColors.mediumGray),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => _showAddressForm(),
            icon: const Icon(Icons.add),
            label: const Text('AGREGAR DIRECCIÓN'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              backgroundColor: AppColors.jdTurquoise,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressesList(
    BuildContext context,
    AddressProvider addressProvider,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: addressProvider.addresses.length + 1,
      itemBuilder: (context, index) {
        if (index == addressProvider.addresses.length) {
          return const SizedBox(height: 80);
        }

        final address = addressProvider.addresses[index];
        final isSelected = addressProvider.selectedAddressId == address.id;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () => addressProvider.selectAddress(address.id),
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
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header con nombre y acciones
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      address.name,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  if (address.isDefault)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.jdTurquoise,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Text(
                                        'Principal',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                address.phone,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppColors.mediumGray,
                                ),
                              ),
                            ],
                          ),
                        ),
                        PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'edit') {
                              _showAddressForm(address: address);
                            } else if (value == 'delete') {
                              _showDeleteConfirmation(context, address);
                            }
                          },
                          itemBuilder: (BuildContext context) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.edit_outlined,
                                    size: 18,
                                    color: AppColors.jdBlack,
                                  ),
                                  SizedBox(width: 8),
                                  Text('Editar'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.delete_outline,
                                    size: 18,
                                    color: AppColors.error,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Eliminar',
                                    style: TextStyle(color: AppColors.error),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 12),

                    // Información de dirección
                    _buildAddressInfo('Dirección', address.fullAddress),
                    const SizedBox(height: 8),
                    _buildAddressInfo(
                      'Ciudad',
                      '${address.city}, ${address.state}',
                    ),
                    const SizedBox(height: 8),
                    _buildAddressInfo('Código Postal', address.postalCode),
                    const SizedBox(height: 8),
                    _buildAddressInfo('País', address.country),

                    // Botón para seleccionar
                    if (!isSelected) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () =>
                              addressProvider.selectAddress(address.id),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                              color: AppColors.jdTurquoise,
                            ),
                          ),
                          child: const Text(
                            'SELECCIONAR',
                            style: TextStyle(
                              color: AppColors.jdTurquoise,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ] else ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.jdTurquoise.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.check_circle_outline,
                                color: AppColors.jdTurquoise,
                                size: 18,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'SELECCIONADA',
                                style: TextStyle(
                                  color: AppColors.jdTurquoise,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAddressInfo(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.mediumGray,
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 14, color: AppColors.jdBlack),
          ),
        ),
      ],
    );
  }

  void _showDeleteConfirmation(BuildContext context, Address address) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar dirección'),
        content: Text(
          '¿Estás seguro de que quieres eliminar la dirección de ${address.name}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final addressProvider = context.read<AddressProvider>();
              final success = await addressProvider.deleteAddress(address.id);

              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Dirección eliminada correctamente'),
                    backgroundColor: AppColors.success,
                  ),
                );
              } else if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      addressProvider.errorMessage ??
                          'Error al eliminar dirección',
                    ),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}
