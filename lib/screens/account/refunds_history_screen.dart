import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/refund.dart';
import '../../services/order_service.dart';

/// RefundsHistoryScreen - Historial de devoluciones del usuario
class RefundsHistoryScreen extends StatefulWidget {
  const RefundsHistoryScreen({super.key});

  @override
  State<RefundsHistoryScreen> createState() => _RefundsHistoryScreenState();
}

class _RefundsHistoryScreenState extends State<RefundsHistoryScreen> {
  final OrderService _orderService = OrderService();
  List<Refund> _refunds = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRefunds();
  }

  Future<void> _loadRefunds() async {
    setState(() => _isLoading = true);
    try {
      _refunds = await _orderService.getUserRefunds();
    } catch (e) {
      debugPrint('Error loading refunds: $e');
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: AppBar(title: const Text('MIS DEVOLUCIONES')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _refunds.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadRefunds,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _refunds.length,
                    itemBuilder: (_, i) => _buildRefundCard(_refunds[i]),
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assignment_return_outlined,
            size: 72,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          const Text(
            'No tienes devoluciones',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          const Text(
            'Cuando solicites una devolución\naparecerá aquí',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.mediumGray),
          ),
        ],
      ),
    );
  }

  Widget _buildRefundCard(Refund refund) {
    final color = _statusColor(refund.status);
    final icon = _statusIcon(refund.status);
    final amountEur = (refund.refundAmountCents / 100).toStringAsFixed(2);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showRefundDetail(refund),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cabecera: estado + fecha
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon, size: 14, color: color),
                        const SizedBox(width: 4),
                        Text(
                          refund.statusText,
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _formatDate(refund.createdAt),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.mediumGray,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Motivo
              Row(
                children: [
                  const Icon(Icons.info_outline,
                      size: 16, color: AppColors.mediumGray),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      refund.reason,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              // Productos devueltos (resumen)
              if (refund.returnedItems.isNotEmpty) ...[
                const Divider(height: 16),
                ...refund.returnedItems.take(2).map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Row(
                          children: [
                            const Icon(Icons.circle,
                                size: 5, color: Colors.grey),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${item['quantity']}x ${item['product_name']}'
                                '${item['size'] != null ? ' (T. ${item['size']})' : ''}',
                                style: const TextStyle(fontSize: 12),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                if (refund.returnedItems.length > 2)
                  Padding(
                    padding: const EdgeInsets.only(left: 13, top: 2),
                    child: Text(
                      '+${refund.returnedItems.length - 2} producto(s) más',
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.mediumGray),
                    ),
                  ),
              ],
              const SizedBox(height: 10),
              // Importe
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Reembolso: $amountEur€',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: color == AppColors.error ? AppColors.error : null,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRefundDetail(Refund refund) {
    final color = _statusColor(refund.status);
    final icon = _statusIcon(refund.status);
    final amountEur = (refund.refundAmountCents / 100).toStringAsFixed(2);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: ListView(
            controller: controller,
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Título
              const Text(
                'Detalle de devolución',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                _formatDate(refund.createdAt),
                style: const TextStyle(
                    color: AppColors.mediumGray, fontSize: 12),
              ),
              const Divider(height: 24),
              // Estado
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon, size: 16, color: color),
                        const SizedBox(width: 6),
                        Text(
                          refund.statusText,
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (refund.status == 'pending') ...[
                const SizedBox(height: 8),
                const Text(
                  'Tu solicitud está siendo revisada. Recibirás el reembolso en 5-7 días hábiles una vez aprobada.',
                  style: TextStyle(fontSize: 12, color: AppColors.mediumGray),
                ),
              ],
              const SizedBox(height: 16),
              // Motivo
              _detailRow(
                Icons.help_outline,
                'Motivo',
                refund.reason,
              ),
              const SizedBox(height: 10),
              _detailRow(
                Icons.payment,
                'Método de reembolso',
                refund.refundMethod == 'original_payment'
                    ? 'Método de pago original'
                    : refund.refundMethod,
              ),
              const Divider(height: 24),
              // Productos
              const Text(
                'Productos a devolver',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 8),
              ...refund.returnedItems.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.shopping_bag_outlined,
                          size: 16, color: AppColors.mediumGray),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${item['quantity']}x ${item['product_name']}'
                          '${item['size'] != null ? ' (Talla: ${item['size']})' : ''}',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      Text(
                        '${(((item['price_cents'] as num? ?? 0) * (item['quantity'] as num? ?? 1)) / 100).toStringAsFixed(2)}€',
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(height: 24),
              // Total
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total a reembolsar',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  Text(
                    '$amountEur€',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: AppColors.jdTurquoise),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.mediumGray),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.mediumGray)),
            Text(value,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w500)),
          ],
        ),
      ],
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'approved':
      case 'processed':
        return AppColors.success;
      case 'rejected':
        return AppColors.error;
      default:
        return Colors.orange;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'approved':
      case 'processed':
        return Icons.check_circle_outline;
      case 'rejected':
        return Icons.cancel_outlined;
      default:
        return Icons.schedule;
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre',
    ];
    return '${date.day} de ${months[date.month - 1]} de ${date.year}';
  }
}
