import 'package:flutter/material.dart';
import 'package:ting_box/utils/parsing_utils.dart';
import 'order.dart';

enum TableStatus {
  empty,
  occupied,
  reserved,
  warning;

  Color get color {
    switch (this) {
      case TableStatus.empty:
        return const Color(0xFF43A047); // Modern Green
      case TableStatus.occupied:
        return const Color(0xFFE53935); // Modern Red
      case TableStatus.reserved:
        return const Color(0xFF1E88E5); // Modern Blue
      case TableStatus.warning:
        return const Color(0xFFFFB300); // Modern Amber
    }
  }

  String get label {
    switch (this) {
      case TableStatus.empty:
        return 'Trống';
      case TableStatus.occupied:
        return 'Đang dùng';
      case TableStatus.reserved:
        return 'Đã đặt';
      case TableStatus.warning:
        return 'Cần dọn';
    }
  }
}

class TableModel {
  final int id;
  final int? zoneId;
  final String name;
  final TableStatus status;
  final int? currentOrderId;
  final int capacity;
  final String? zone;
  final bool isActive;
  final Order? currentOrder;

  TableModel({
    required this.id,
    this.zoneId,
    required this.name,
    required this.status,
    this.currentOrderId,
    required this.capacity,
    this.zone,
    this.isActive = true,
    this.currentOrder,
  });

  factory TableModel.fromJson(Map<String, dynamic> json) {
    final currentOrderId = parseInt(json['currentOrderId'] ?? json['current_order_id']);
    final currentOrderJson = json['currentOrder'] ?? json['current_order'];
    final currentOrder = currentOrderJson != null ? _safeParseOrder(currentOrderJson) : null;
    final statusStr = parseString(json['status']);

    return TableModel(
      id: parseInt(json['id'], 'id'),
      zoneId: parseInt(json['zoneId'] ?? json['zone_id'], 'zoneId'),
      name: parseString(json['name']),
      status: TableStatus.values.firstWhere(
        (e) => e.name.toLowerCase() == statusStr.toLowerCase(),
        orElse: () {
          if (currentOrder != null || currentOrderId != 0) {
            return TableStatus.occupied;
          }
          return TableStatus.empty;
        },
      ),
      currentOrderId: currentOrderId,
      capacity: parseInt(json['capacity'], 'capacity'),
      zone: json['zone'] is Map ? parseString(json['zone']['name']) : parseString(json['zone']),
      isActive: json['isActive'] ?? true,
      currentOrder: currentOrder,
    );
  }

  static Order? _safeParseOrder(dynamic json) {
    try {
      return Order.fromJson(json);
    } catch (e) {
      debugPrint('Error parsing order in table: $e');
      return null;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'zoneId': zoneId,
      'name': name,
      'status': status.name,
      'currentOrderId': currentOrderId,
      'capacity': capacity,
      'zone': zone,
      'isActive': isActive,
      'currentOrder': currentOrder?.toJson(),
    };
  }

  TableModel copyWith({
    int? id,
    int? zoneId,
    String? name,
    TableStatus? status,
    int? currentOrderId,
    int? capacity,
    String? zone,
    bool? isActive,
    Order? currentOrder,
  }) {
    return TableModel(
      id: id ?? this.id,
      zoneId: zoneId ?? this.zoneId,
      name: name ?? this.name,
      status: status ?? this.status,
      currentOrderId: currentOrderId ?? this.currentOrderId,
      capacity: capacity ?? this.capacity,
      zone: zone ?? this.zone,
      isActive: isActive ?? this.isActive,
      currentOrder: currentOrder ?? this.currentOrder,
    );
  }
}
