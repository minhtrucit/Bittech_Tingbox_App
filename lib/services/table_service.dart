import '../models/order.dart';
import '../models/table_model.dart';
import '../models/zone_model.dart';
import 'api_services.dart';

class TableService {
  final ApiService api;

  TableService({required this.api});

  // Helper to extract data from envelope if present
  dynamic _unwrap(dynamic responseData) {
    if (responseData is Map<String, dynamic> && responseData.containsKey('data')) {
      return responseData['data'];
    }
    return responseData;
  }

  // ----------------------
  // ZONE APIs
  // ----------------------

  Future<List<ZoneModel>> getZones(int configId) async {
    try {
      final response = await api.get('/zones', queryParameters: {'configId': configId});
      if (response.statusCode == 200) {
        final rawData = _unwrap(response.data);
        if (rawData is List) {
          return rawData.map((json) => ZoneModel.fromJson(json)).toList();
        }
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  Future<ZoneModel> createZone(Map<String, dynamic> data) async {
    try {
      final response = await api.post('/zones', data: data);
      if (response.statusCode == 201 || response.statusCode == 200) {
        final rawData = _unwrap(response.data);
        return ZoneModel.fromJson(rawData);
      }
      throw Exception('Failed to create zone');
    } catch (e) {
      rethrow;
    }
  }

  Future<ZoneModel> updateZone(int id, Map<String, dynamic> data) async {
    try {
      final response = await api.patch('/zones/$id', data: data);
      if (response.statusCode == 200) {
        final rawData = _unwrap(response.data);
        return ZoneModel.fromJson(rawData);
      }
      throw Exception('Failed to update zone');
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteZone(int id) async {
    try {
      final response = await api.delete('/zones/$id');
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to delete zone');
      }
    } catch (e) {
      rethrow;
    }
  }

  // ----------------------
  // TABLE APIs
  // ----------------------

  Future<List<TableModel>> getTables(int zoneId) async {
    try {
      final response = await api.get('/tables', queryParameters: {'zoneId': zoneId});
      if (response.statusCode == 200) {
        final rawData = _unwrap(response.data);
        if (rawData is List) {
          return rawData.map((json) => TableModel.fromJson(json)).toList();
        }
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  Future<TableModel> createTable(Map<String, dynamic> data) async {
    try {
      final response = await api.post('/tables', data: data);
      if (response.statusCode == 201 || response.statusCode == 200) {
        final rawData = _unwrap(response.data);
        return TableModel.fromJson(rawData);
      }
      throw Exception('Failed to create table');
    } catch (e) {
      rethrow;
    }
  }

  Future<TableModel> updateTable(int id, Map<String, dynamic> data) async {
    try {
      final response = await api.patch('/tables/$id', data: data);
      if (response.statusCode == 200) {
        final rawData = _unwrap(response.data);
        return TableModel.fromJson(rawData);
      }
      throw Exception('Failed to update table');
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteTable(int id) async {
    try {
      // Soft delete: update isActive to false
      final response = await api.patch('/tables/$id', data: {'isActive': false});
      if (response.statusCode != 200) {
        throw Exception('Failed to delete table');
      }
    } catch (e) {
      rethrow;
    }
  }

  // ----------------------
  // ORDER APIs
  // ----------------------

  Future<Map<String, dynamic>> createTempOrder({
    required int userId,
    required int tableId,
    required List<Map<String, dynamic>> items,
    String? note,
  }) async {
    try {
      final response = await api.post('/orders/temp', data: {
        'userId': userId,
        'tableId': tableId,
        'items': items,
        'note': note,
      });
      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data; 
      }
      throw Exception('Failed to create temp order');
    } catch (e) {
      rethrow;
    }
  }

  // UPDATED: Use /orders/$orderId instead of /orders/tables/$tableId
  Future<Order?> getOrderDetails(int orderId) async {
    try {
      final response = await api.get('/orders/$orderId');
      if (response.statusCode == 200) {
        final rawData = _unwrap(response.data);
        if (rawData != null) {
          return Order.fromJson(rawData);
        }
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  // ----------------------
  // ORDER OPERATIONS
  // ----------------------

  Future<void> moveTable({required int orderId, required int toTableId}) async {
    try {
      final response = await api.post('/orders/move-table', data: {
        'orderId': orderId,
        'toTableId': toTableId,
      });
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Failed to move table');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> mergeTable({required int sourceOrderId, required int destinationOrderId}) async {
    try {
      final response = await api.post('/orders/merge-table', data: {
        'sourceOrderId': sourceOrderId,
        'destinationOrderId': destinationOrderId,
      });
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Failed to merge table');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> voidItem({
    required int orderId,
    required int productId,
    required int quantity,
    required String reason,
  }) async {
    try {
      final response = await api.post('/orders/$orderId/items/$productId/void', data: {
        'quantity': quantity,
        'reason': reason,
      });
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Failed to void item');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<Order> updateOrder(int orderId, Map<String, dynamic> data) async {
    try {
      final response = await api.put('/orders/$orderId', data: data);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return Order.fromJson(response.data['data']);
      }
      throw Exception('Failed to update order');
    } catch (e) {
      rethrow;
    }
  }
}
