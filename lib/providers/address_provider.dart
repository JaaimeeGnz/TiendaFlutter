import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/address.dart';
import '../services/supabase_service.dart';

/// AddressProvider - Gestión de direcciones de envío del usuario
/// Maneja CRUD de direcciones y sincronización con Supabase
class AddressProvider with ChangeNotifier {
  static const String _addressesKey = 'savedAddresses';

  final SupabaseService _supabaseService = SupabaseService.instance;

  List<Address> _addresses = [];
  bool _isLoading = false;
  String? _selectedAddressId;
  String? _errorMessage;

  List<Address> get addresses => _addresses;
  bool get isLoading => _isLoading;
  String? get selectedAddressId => _selectedAddressId;
  Address? get selectedAddress {
    if (_selectedAddressId == null) return null;
    try {
      return _addresses.firstWhere((a) => a.id == _selectedAddressId);
    } catch (e) {
      return _addresses.isNotEmpty ? _addresses.first : null;
    }
  }

  String? get errorMessage => _errorMessage;
  bool get isEmpty => _addresses.isEmpty;
  bool get isNotEmpty => _addresses.isNotEmpty;

  /// Cargar direcciones del usuario
  Future<void> loadAddresses(String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Intentar cargar de Supabase
      final response = await _supabaseService.client
          .from('addresses')
          .select()
          .eq('user_id', userId)
          .order('is_default', ascending: false);

      if (response.isNotEmpty) {
        _addresses = response.map((json) => Address.fromJson(json)).toList();

        // Guardar localmente como backup
        await _saveAddressesLocally();

        // Seleccionar la dirección por defecto si existe
        if (_addresses.isNotEmpty) {
          final defaultAddress = _addresses.firstWhere(
            (a) => a.isDefault,
            orElse: () => _addresses.first,
          );
          _selectedAddressId = defaultAddress.id;
        }
      }
    } catch (e) {
      _errorMessage = 'Error al cargar direcciones: $e';
      // Intentar cargar desde caché local
      await _loadAddressesLocally();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Agregar nueva dirección
  Future<bool> addAddress({
    required String userId,
    required String name,
    required String phone,
    required String street,
    required String number,
    String? apartment,
    required String city,
    required String state,
    required String postalCode,
    required String country,
    bool isDefault = false,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Si es la primera dirección o se marca como default, actualizar otros
      if (isDefault || _addresses.isEmpty) {
        await _updateDefaultAddress(userId, null);
      }

      // Crear nueva dirección
      final newAddress = Address(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: userId,
        name: name,
        phone: phone,
        street: street,
        number: number,
        apartment: apartment,
        city: city,
        state: state,
        postalCode: postalCode,
        country: country,
        isDefault: isDefault || _addresses.isEmpty,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Intentar guardar en Supabase
      try {
        await _supabaseService.client
            .from('addresses')
            .insert(newAddress.toJson());
      } catch (e) {
        // Si falla Supabase, guardar solo localmente
        print('Error al guardar en Supabase: $e');
      }

      _addresses.add(newAddress);
      _selectedAddressId = newAddress.id;
      await _saveAddressesLocally();

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Error al agregar dirección: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Actualizar dirección existente
  Future<bool> updateAddress({
    required String addressId,
    required String name,
    required String phone,
    required String street,
    required String number,
    String? apartment,
    required String city,
    required String state,
    required String postalCode,
    required String country,
    bool isDefault = false,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final addressIndex = _addresses.indexWhere((a) => a.id == addressId);
      if (addressIndex == -1) {
        throw Exception('Dirección no encontrada');
      }

      final currentAddress = _addresses[addressIndex];

      // Si se marca como default, actualizar otros
      if (isDefault && !currentAddress.isDefault) {
        await _updateDefaultAddress(currentAddress.userId, addressId);
      }

      final updatedAddress = Address(
        id: currentAddress.id,
        userId: currentAddress.userId,
        name: name,
        phone: phone,
        street: street,
        number: number,
        apartment: apartment,
        city: city,
        state: state,
        postalCode: postalCode,
        country: country,
        isDefault: isDefault,
        createdAt: currentAddress.createdAt,
        updatedAt: DateTime.now(),
      );

      // Intentar actualizar en Supabase
      try {
        await _supabaseService.client
            .from('addresses')
            .update(updatedAddress.toJson())
            .eq('id', addressId);
      } catch (e) {
        print('Error al actualizar en Supabase: $e');
      }

      _addresses[addressIndex] = updatedAddress;

      // Si esta era la dirección seleccionada y se marca como default, mantenerla seleccionada
      if (isDefault && _selectedAddressId == addressId) {
        _selectedAddressId = addressId;
      }

      await _saveAddressesLocally();

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Error al actualizar dirección: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Eliminar dirección
  Future<bool> deleteAddress(String addressId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Intentar eliminar de Supabase
      try {
        await _supabaseService.client
            .from('addresses')
            .delete()
            .eq('id', addressId);
      } catch (e) {
        print('Error al eliminar en Supabase: $e');
      }

      _addresses.removeWhere((a) => a.id == addressId);

      // Si era la seleccionada, seleccionar otra
      if (_selectedAddressId == addressId) {
        if (_addresses.isNotEmpty) {
          _selectedAddressId = _addresses.first.id;
        } else {
          _selectedAddressId = null;
        }
      }

      await _saveAddressesLocally();

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Error al eliminar dirección: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Seleccionar dirección para uso en checkout
  void selectAddress(String addressId) {
    if (_addresses.any((a) => a.id == addressId)) {
      _selectedAddressId = addressId;
      notifyListeners();
    }
  }

  /// Actualizar la dirección default
  Future<void> _updateDefaultAddress(
    String userId,
    String? newDefaultId,
  ) async {
    try {
      // Desmarcar todas como default
      for (int i = 0; i < _addresses.length; i++) {
        final address = _addresses[i];
        if (address.id != newDefaultId) {
          final updated = Address(
            id: address.id,
            userId: address.userId,
            name: address.name,
            phone: address.phone,
            street: address.street,
            number: address.number,
            apartment: address.apartment,
            city: address.city,
            state: address.state,
            postalCode: address.postalCode,
            country: address.country,
            isDefault: false,
            createdAt: address.createdAt,
            updatedAt: DateTime.now(),
          );

          try {
            await _supabaseService.client
                .from('addresses')
                .update(updated.toJson())
                .eq('id', address.id);
          } catch (e) {
            print('Error al actualizar default: $e');
          }

          _addresses[i] = updated;
        }
      }

      // Marcar el nuevo como default
      if (newDefaultId != null) {
        final index = _addresses.indexWhere((a) => a.id == newDefaultId);
        if (index != -1) {
          final address = _addresses[index];
          final updated = Address(
            id: address.id,
            userId: address.userId,
            name: address.name,
            phone: address.phone,
            street: address.street,
            number: address.number,
            apartment: address.apartment,
            city: address.city,
            state: address.state,
            postalCode: address.postalCode,
            country: address.country,
            isDefault: true,
            createdAt: address.createdAt,
            updatedAt: DateTime.now(),
          );

          try {
            await _supabaseService.client
                .from('addresses')
                .update(updated.toJson())
                .eq('id', newDefaultId);
          } catch (e) {
            print('Error al marcar default: $e');
          }

          _addresses[index] = updated;
        }
      }
    } catch (e) {
      print('Error al actualizar default address: $e');
    }
  }

  /// Guardar direcciones localmente
  Future<void> _saveAddressesLocally() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = jsonEncode(_addresses.map((a) => a.toJson()).toList());
      await prefs.setString(_addressesKey, json);
    } catch (e) {
      print('Error al guardar direcciones localmente: $e');
    }
  }

  /// Cargar direcciones del almacenamiento local
  Future<void> _loadAddressesLocally() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_addressesKey);
      if (json != null && json.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(json);
        _addresses = decoded.map((j) => Address.fromJson(j)).toList();

        // Seleccionar la primera como default si existe
        if (_addresses.isNotEmpty && _selectedAddressId == null) {
          _selectedAddressId = _addresses.first.id;
        }
      }
    } catch (e) {
      print('Error al cargar direcciones localmente: $e');
      _addresses = [];
    }
  }

  /// Limpiar datos (logout)
  void clear() {
    _addresses = [];
    _selectedAddressId = null;
    _errorMessage = null;
    notifyListeners();
  }
}
