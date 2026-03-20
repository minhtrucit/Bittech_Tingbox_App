import 'package:flutter/material.dart';
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
    return TableModel(
      id: json['id'],
      zoneId: json['zoneId'],
      name: json['name'],
      status: TableStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => TableStatus.empty,
      ),
      currentOrderId: json['currentOrderId'],
      capacity: json['capacity'] ?? 4,
      zone: json['zone'] is Map ? json['zone']['name'] : json['zone'],
      isActive: json['isActive'] ?? true,
      currentOrder: (json['currentOrder'] ?? json['current_order']) != null 
          ? _safeParseOrder(json['currentOrder'] ?? json['current_order']) 
          : null,
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
