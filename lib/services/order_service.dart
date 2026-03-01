import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/address.dart';
import '../models/cart_item.dart';
import '../models/order.dart';
import '../models/refund.dart';
import 'stock_service.dart';
import 'supabase_service.dart';

class OrderService {
  final SupabaseClient _client = SupabaseService.instance.client;

  // Obtener pedidos del usuario actual
  Future<List<Order>> getUserOrders() async {
    final userId = SupabaseService.instance.currentUserId;
    if (userId == null) return [];

    try {
      // Consultar pedidos sin join de order_items para evitar error de FK
      // Excluir pedidos cancelados para que no aparezcan en la lista
      final response = await _client
          .from('orders')
          .select('*, addresses(*)')
          .eq('user_id', userId)
          .neq('status', 'cancelled')
          .order('created_at', ascending: false);

      final orders = <Order>[];
      for (final json in (response as List)) {
        // Cargar items con imagen del producto
        final orderId = json['id'] as String;
        List<Map<String, dynamic>> itemsData = [];
        try {
          final itemsResponse = await _client
              .from('order_items')
              .select('*, products!fk_order_items_products(images)')
              .eq('order_id', orderId);
          itemsData = (itemsResponse as List).map((item) {
            final m = Map<String, dynamic>.from(item);
            // Extraer primera imagen del producto
            final productData = m['products'] as Map<String, dynamic>?;
            if (productData != null) {
              final images = productData['images'] as List<dynamic>?;
              if (images != null && images.isNotEmpty) {
                m['product_image'] = images[0];
              }
            }
            m.remove('products');
            return m;
          }).toList();
        } catch (e) {
          print('Error loading items for order $orderId: $e');
        }
        json['order_items'] = itemsData;
        orders.add(Order.fromJson(json));
      }
      return orders;
    } catch (e) {
      print('Error fetching user orders: $e');
      return [];
    }
  }

  // Obtener pedido por ID
  Future<Order?> getOrderById(String id) async {
    try {
      final response = await _client
          .from('orders')
          .select('*, addresses(*)')
          .eq('id', id)
          .single();

      // Cargar items con imagen del producto
      List<Map<String, dynamic>> itemsData = [];
      try {
        final itemsResponse = await _client
            .from('order_items')
            .select('*, products!fk_order_items_products(images)')
            .eq('order_id', id);
        itemsData = (itemsResponse as List).map((item) {
          final m = Map<String, dynamic>.from(item);
          final productData = m['products'] as Map<String, dynamic>?;
          if (productData != null) {
            final images = productData['images'] as List<dynamic>?;
            if (images != null && images.isNotEmpty) {
              m['product_image'] = images[0];
            }
          }
          m.remove('products');
          return m;
        }).toList();
      } catch (e) {
        print('Error loading items for order $id: $e');
      }
      response['order_items'] = itemsData;

      return Order.fromJson(response);
    } catch (e) {
      print('Error fetching order by id: $e');
      return null;
    }
  }

  // Crear pedido completo con items
  Future<Order?> createOrderWithItems({
    required List<CartItem> items,
    required int totalCents,
    required String email,
    String? addressId,
    String? discountCode,
    int? discountCents,
    String? paymentMethod,
    String? paymentIntentId,
  }) async {
    final userId = SupabaseService.instance.currentUserId;
    if (userId == null) {
      print('Error: User not authenticated');
      return null;
    }

    try {
      // Generar número de pedido único
      final orderNumber =
          'JGM-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';

      final orderData = {
        'user_id': userId,
        'address_id': addressId,
        'order_number': orderNumber,
        'total_cents': totalCents,
        'status': paymentIntentId != null ? 'paid' : 'pending',
        'payment_method': paymentMethod ?? 'stripe',
        'customer_email': email,
      };

      // 1. Crear el pedido
      final orderResponse = await _client
          .from('orders')
          .insert(orderData)
          .select()
          .single();

      final orderId = orderResponse['id'] as String;

      // 2. Crear items del pedido
      final orderItems = items.map((item) => {
        'order_id': orderId,
        'product_id': item.id,
        'product_name': item.name,
        'quantity': item.quantity,
        'price_cents': item.priceCents,
        'total_cents': item.priceCents * item.quantity,
        'size': item.size,
      }).toList();

      await _client.from('order_items').insert(orderItems);

      // 3. Retornar el pedido con items
      orderResponse['order_items'] = orderItems;
      return Order.fromJson(orderResponse);
    } catch (e) {
      print('Error creating order: $e');
      return null;
    }
  }

  // Cancelar pedido (pending o paid) — marca como cancelled y restaura stock
  Future<bool> cancelOrder(String orderId) async {
    try {
      final userId = SupabaseService.instance.currentUserId;
      if (userId == null) return false;

      // 1. Obtener items del pedido para restaurar stock
      try {
        final items = await _client
            .from('order_items')
            .select('product_id, quantity, size')
            .eq('order_id', orderId);

        final stockService = StockService();
        for (final item in (items as List)) {
          final productId = item['product_id'] as String?;
          final quantity = item['quantity'] as int? ?? 0;
          final size = item['size'] as String?;

          if (productId != null && quantity > 0) {
            await stockService.releaseStock(
              productId: productId,
              quantity: quantity,
              size: size,
            );
          }
        }
      } catch (e) {
        print('⚠️ No se pudo restaurar stock al cancelar: $e');
        // Continuar con la cancelación aunque falle la restauración de stock
      }

      // 2. Marcar pedido como cancelado (RLS requiere que sea del usuario)
      await _client
          .from('orders')
          .update({'status': 'cancelled'})
          .eq('id', orderId)
          .eq('user_id', userId);

      // 3. Intentar eliminar factura asociada
      try {
        await _client.from('invoices').delete().eq('order_id', orderId);
      } catch (_) {}

      return true;
    } catch (e) {
      print('Error cancelling order: $e');
      return false;
    }
  }

  // Solicitar devolución (delivered)
  // Acepta solo los items seleccionados por el usuario
  // Restaura stock de los productos devueltos
  Future<bool> requestRefund({
    required String orderId,
    required String reason,
    required String customerEmail,
    required List<OrderItem> items,
  }) async {
    try {
      final refundAmountCents = items.fold<int>(
        0,
        (sum, item) => sum + (item.priceCents * item.quantity),
      );

      // Construir items como lo hace Astro
      final returnedItems = items
          .map((i) => {
                'order_item_id': i.id,
                'product_id': i.productId,
                'product_name': i.productName,
                'quantity': i.quantity,
                'price_cents': i.priceCents,
                'total_cents': i.priceCents * i.quantity,
                'size': i.size,
              })
          .toList();

      // Restaurar stock de los productos devueltos
      try {
        final stockService = StockService();
        for (final item in items) {
          if (item.productId.isNotEmpty && item.quantity > 0) {
            await stockService.releaseStock(
              productId: item.productId,
              quantity: item.quantity,
              size: item.size,
            );
          }
        }
      } catch (e) {
        print('⚠️ No se pudo restaurar stock en devolución: $e');
        // Continuar con la devolución aunque falle la restauración de stock
      }

      // Obtener nombre del usuario desde auth o email
      String customerName = customerEmail.split('@').first;

      final now = DateTime.now().toUtc().toIso8601String();

      await _client.from('refunds').insert({
        'order_id': orderId,
        'customer_email': customerEmail,
        'customer_name': customerName,
        'reason': reason,
        'returned_items': returnedItems,
        'refund_amount_cents': refundAmountCents,
        'refund_method': 'original_payment',
        'status': 'processed',
        'processed_at': now,
        'refund_date': now,
      });
      return true;
    } catch (e) {
      print('Error requesting refund: $e');
      return false;
    }
  }

  // Obtener devoluciones del usuario actual
  Future<List<Refund>> getUserRefunds() async {
    final userId = SupabaseService.instance.currentUserId;
    if (userId == null) return [];

    try {
      // Buscar devoluciones a través del customer_email del usuario
      final orders = await _client
          .from('orders')
          .select('id')
          .eq('user_id', userId);

      if (orders.isEmpty) return [];

      final orderIds = (orders as List).map((o) => o['id'] as String).toList();

      final data = await _client
          .from('refunds')
          .select()
          .inFilter('order_id', orderIds)
          .order('created_at', ascending: false);

      return (data as List).map((e) => Refund.fromJson(e)).toList();
    } catch (e) {
      print('Error loading refunds: $e');
      return [];
    }
  }

  // Actualizar estado del pedido
  Future<bool> updateOrderStatus(String orderId, String status) async {
    try {
      await _client.from('orders').update({'status': status}).eq('id', orderId);
      return true;
    } catch (e) {
      print('Error updating order status: $e');
      return false;
    }
  }

  // ADMIN: Obtener todos los pedidos
  Future<List<Order>> getAllOrders() async {
    try {
      final response = await _client
          .from('orders')
          .select('*, addresses(*)')
          .order('created_at', ascending: false);

      final orders = <Order>[];
      for (final json in (response as List)) {
        final orderId = json['id'] as String;
        List<Map<String, dynamic>> itemsData = [];
        try {
          final itemsResponse = await _client
              .from('order_items')
              .select('*, products!fk_order_items_products(images)')
              .eq('order_id', orderId);
          itemsData = (itemsResponse as List).map((item) {
            final m = Map<String, dynamic>.from(item);
            final productData = m['products'] as Map<String, dynamic>?;
            if (productData != null) {
              final images = productData['images'] as List<dynamic>?;
              if (images != null && images.isNotEmpty) {
                m['product_image'] = images[0];
              }
            }
            m.remove('products');
            return m;
          }).toList();
        } catch (e) {
          print('Error loading items for order $orderId: $e');
        }
        json['order_items'] = itemsData;
        orders.add(Order.fromJson(json));
      }
      return orders;
    } catch (e) {
      print('Error fetching all orders: $e');
      return [];
    }
  }
}

class AddressService {
  final SupabaseClient _client = SupabaseService.instance.client;

  // Obtener direcciones del usuario actual
  Future<List<Address>> getUserAddresses() async {
    final userId = SupabaseService.instance.currentUserId;
    if (userId == null) return [];

    try {
      final response = await _client
          .from('addresses')
          .select()
          .eq('user_id', userId)
          .order('is_default', ascending: false);

      return (response as List).map((json) => Address.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching user addresses: $e');
      return [];
    }
  }

  // Obtener dirección por defecto
  Future<Address?> getDefaultAddress() async {
    final userId = SupabaseService.instance.currentUserId;
    if (userId == null) return null;

    try {
      final response = await _client
          .from('addresses')
          .select()
          .eq('user_id', userId)
          .eq('is_default', true)
          .maybeSingle();

      return response != null ? Address.fromJson(response) : null;
    } catch (e) {
      print('Error fetching default address: $e');
      return null;
    }
  }

  // Crear dirección
  Future<Address?> createAddress(Address address) async {
    try {
      // Si es dirección por defecto, desmarcar las demás
      if (address.isDefault) {
        await _client
            .from('addresses')
            .update({'is_default': false})
            .eq('user_id', address.userId);
      }

      final response = await _client
          .from('addresses')
          .insert(address.toJson())
          .select()
          .single();

      return Address.fromJson(response);
    } catch (e) {
      print('Error creating address: $e');
      return null;
    }
  }

  // Actualizar dirección
  Future<Address?> updateAddress(
    String id,
    Map<String, dynamic> updates,
  ) async {
    try {
      // Si se marca como por defecto, desmarcar las demás
      if (updates['is_default'] == true) {
        final userId = SupabaseService.instance.currentUserId;
        if (userId != null) {
          await _client
              .from('addresses')
              .update({'is_default': false})
              .eq('user_id', userId);
        }
      }

      final response = await _client
          .from('addresses')
          .update(updates)
          .eq('id', id)
          .select()
          .single();

      return Address.fromJson(response);
    } catch (e) {
      print('Error updating address: $e');
      return null;
    }
  }

  // Eliminar dirección
  Future<bool> deleteAddress(String id) async {
    try {
      await _client.from('addresses').delete().eq('id', id);

      return true;
    } catch (e) {
      print('Error deleting address: $e');
      return false;
    }
  }

  // Establecer dirección por defecto
  Future<bool> setDefaultAddress(String id) async {
    final userId = SupabaseService.instance.currentUserId;
    if (userId == null) return false;

    try {
      // Desmarcar todas las direcciones del usuario
      await _client
          .from('addresses')
          .update({'is_default': false})
          .eq('user_id', userId);

      // Marcar la dirección seleccionada como por defecto
      await _client.from('addresses').update({'is_default': true}).eq('id', id);

      return true;
    } catch (e) {
      print('Error setting default address: $e');
      return false;
    }
  }
}
