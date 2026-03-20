import 'package:equatable/equatable.dart';
import '../../../models/table_model.dart';
import '../../../models/zone_model.dart';
import '../../../models/order.dart';

abstract class TableState extends Equatable {
  const TableState();

  @override
  List<Object?> get props => [];
}

class TableInitial extends TableState {}

class TableLoading extends TableState {}

class ZonesLoaded extends TableState {
  final List<ZoneModel> zones;
  const ZonesLoaded(this.zones);

  @override
  List<Object?> get props => [zones];
}

class TablesLoaded extends TableState {
  final List<TableModel> tables;
  const TablesLoaded(this.tables);

  @override
  List<Object?> get props => [tables];
}

class TableActionSuccess extends TableState {
  final String message;
  const TableActionSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class TableActionFailure extends TableState {
  final String message;
  const TableActionFailure(this.message);

  @override
  List<Object?> get props => [message];
}

class TableOrderLoaded extends TableState {
  final Order order;
  const TableOrderLoaded(this.order);

  @override
  List<Object?> get props => [order];
}
