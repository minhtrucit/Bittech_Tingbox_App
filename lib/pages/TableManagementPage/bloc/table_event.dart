import 'package:equatable/equatable.dart';

abstract class TableEvent extends Equatable {
  const TableEvent();

  @override
  List<Object?> get props => [];
}

class FetchZones extends TableEvent {
  final int configId;
  const FetchZones(this.configId);

  @override
  List<Object?> get props => [configId];
}

class FetchTables extends TableEvent {
  final int zoneId;
  const FetchTables(this.zoneId);

  @override
  List<Object?> get props => [zoneId];
}

class CreateZone extends TableEvent {
  final Map<String, dynamic> data;
  const CreateZone(this.data);

  @override
  List<Object?> get props => [data];
}

class UpdateZone extends TableEvent {
  final int id;
  final Map<String, dynamic> data;
  const UpdateZone(this.id, this.data);

  @override
  List<Object?> get props => [id, data];
}

class DeleteZone extends TableEvent {
  final int id;
  const DeleteZone(this.id);

  @override
  List<Object?> get props => [id];
}

class CreateTable extends TableEvent {
  final Map<String, dynamic> data;
  const CreateTable(this.data);

  @override
  List<Object?> get props => [data];
}

class UpdateTable extends TableEvent {
  final int id;
  final Map<String, dynamic> data;
  const UpdateTable(this.id, this.data);

  @override
  List<Object?> get props => [id, data];
}

class DeleteTable extends TableEvent {
  final int id;
  const DeleteTable(this.id);

  @override
  List<Object?> get props => [id];
}

class CreateTempOrder extends TableEvent {
  final int userId;
  final int tableId;
  final List<Map<String, dynamic>> items;
  final String? note;

  const CreateTempOrder({
    required this.userId,
    required this.tableId,
    required this.items,
    this.note,
  });

  @override
  List<Object?> get props => [userId, tableId, items, note];
}

class FetchTableOrder extends TableEvent {
  final int orderId;
  const FetchTableOrder(this.orderId);

  @override
  List<Object?> get props => [orderId];
}

class MoveTableOrder extends TableEvent {
  final int orderId;
  final int toTableId;
  const MoveTableOrder({required this.orderId, required this.toTableId});

  @override
  List<Object?> get props => [orderId, toTableId];
}

class MergeTableOrder extends TableEvent {
  final int sourceOrderId;
  final int destinationOrderId;
  const MergeTableOrder({required this.sourceOrderId, required this.destinationOrderId});

  @override
  List<Object?> get props => [sourceOrderId, destinationOrderId];
}

class VoidOrderItem extends TableEvent {
  final int orderId;
  final int productId;
  final int quantity;
  final String reason;

  const VoidOrderItem({
    required this.orderId,
    required this.productId,
    required this.quantity,
    required this.reason,
  });

  @override
  List<Object?> get props => [orderId, productId, quantity, reason];
}

class SubscribeToTableUpdates extends TableEvent {
  final int configId;
  const SubscribeToTableUpdates(this.configId);

  @override
  List<Object?> get props => [configId];
}

class UpdateTableOrder extends TableEvent {
  final int orderId;
  final Map<String, dynamic> data;
  const UpdateTableOrder({required this.orderId, required this.data});

  @override
  List<Object?> get props => [orderId, data];
}

class UnsubscribeFromTableUpdates extends TableEvent {}
