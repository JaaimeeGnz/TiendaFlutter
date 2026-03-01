import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/invoice.dart';
import '../models/refund.dart';
import 'supabase_service.dart';

/// InvoiceAdminService - Servicio admin para facturas y devoluciones
/// Replica la funcionalidad de invoiceAndRefunds.ts de tiendaOnline
class InvoiceAdminService {
  final SupabaseClient _client = SupabaseService.instance.client;

  /// Obtener solo facturas de compra (type='invoice'), sin credit_notes
  /// Replica: Astro muestra facturas de compra separadas de devoluciones
  Future<List<Invoice>> getAllInvoices() async {
    try {
      final data = await _client
          .from('invoices')
          .select()
          .eq('type', 'invoice')
          .order('issued_at', ascending: false);
      return (data as List).map((e) => Invoice.fromJson(e)).toList();
    } catch (e) {
      print('Error loading invoices: $e');
      return [];
    }
  }

  /// Obtener todas las devoluciones (admin)
  Future<List<Refund>> getAllRefunds() async {
    try {
      final data = await _client
          .from('refunds')
          .select()
          .order('created_at', ascending: false);
      return (data as List).map((e) => Refund.fromJson(e)).toList();
    } catch (e) {
      print('Error loading refunds: $e');
      return [];
    }
  }

  /// Actualizar estado de una devolución (admin)
  Future<bool> updateRefundStatus(String refundId, String newStatus) async {
    try {
      await _client
          .from('refunds')
          .update({'status': newStatus})
          .eq('id', refundId);
      return true;
    } catch (e) {
      print('Error updating refund status: $e');
      return false;
    }
  }

  /// Resumen financiero — replica getFinancialSummary de Astro
  /// Usa el total de pedidos (no cancelados) como "Total Facturado"
  Future<Map<String, dynamic>> getFinancialSummary() async {
    try {
      final invoices = await getAllInvoices();
      final refunds = await getAllRefunds();

      // Total facturado desde pedidos no cancelados (como hace Astro)
      int totalAllOrdersCents = 0;
      int orderCount = 0;
      try {
        final ordersData = await _client
            .from('orders')
            .select('total_cents')
            .neq('status', 'cancelled');
        for (final o in (ordersData as List)) {
          totalAllOrdersCents += ((o['total_cents'] as num?)?.toInt() ?? 0);
          orderCount++;
        }
      } catch (_) {}

      final totalRefundedCents =
          refunds.fold<int>(0, (sum, r) => sum + r.refundAmountCents);

      return {
        'totalInvoices': invoices.length,
        'totalRefunds': refunds.length,
        'totalInvoicedCents': totalAllOrdersCents,
        'totalRefundedCents': totalRefundedCents,
        'orderCount': orderCount,
        'netRevenueCents': totalAllOrdersCents - totalRefundedCents,
      };
    } catch (e) {
      print('Error loading financial summary: $e');
      return {
        'totalInvoices': 0,
        'totalRefunds': 0,
        'totalInvoicedCents': 0,
        'totalRefundedCents': 0,
        'orderCount': 0,
        'netRevenueCents': 0,
      };
    }
  }
}
