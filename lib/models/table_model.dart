import 'package:flutter/material.dart';

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
        return const Color(0xFF1E88E5); // Modern Blue (similar to primary)
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
  final String name;
  final TableStatus status;
  final int? currentOrderId;
  final int capacity;
  final String? zone;

  TableModel({
    required this.id,
    required this.name,
    required this.status,
    this.currentOrderId,
    required this.capacity,
    this.zone,
  });

  factory TableModel.fromJson(Map<String, dynamic> json) {
    return TableModel(
      id: json['id'],
      name: json['name'],
      status: TableStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => TableStatus.empty,
      ),
      currentOrderId: json['currentOrderId'],
      capacity: json['capacity'] ?? 4,
      zone: json['zone'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'status': status.name,
      'currentOrderId': currentOrderId,
      'capacity': capacity,
      'zone': zone,
    };
  }

  TableModel copyWith({
    int? id,
    String? name,
    TableStatus? status,
    int? currentOrderId,
    int? capacity,
    String? zone,
  }) {
    return TableModel(
      id: id ?? this.id,
      name: name ?? this.name,
      status: status ?? this.status,
      currentOrderId: currentOrderId ?? this.currentOrderId,
      capacity: capacity ?? this.capacity,
      zone: zone ?? this.zone,
    );
  }
}
