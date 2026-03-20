import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import '../../../services/table_service.dart';
import '../../../services/websocket_manager.dart';
import 'table_event.dart';
import 'table_state.dart';

class TableBloc extends Bloc<TableEvent, TableState> {
  final TableService tableService;
  final WebSocketManager socketManager = WebSocketManager();
  int? _currentConfigId;

  TableBloc({required this.tableService}) : super(TableInitial()) {
    on<FetchZones>(_onFetchZones);
    on<FetchTables>(_onFetchTables);
    on<CreateZone>(_onCreateZone);
    on<UpdateZone>(_onUpdateZone);
    on<DeleteZone>(_onDeleteZone);
    on<CreateTable>(_onCreateTable);
    on<UpdateTable>(_onUpdateTable);
    on<DeleteTable>(_onDeleteTable);
    on<CreateTempOrder>(_onCreateTempOrder);
    on<FetchTableOrder>(_onFetchTableOrder);
    on<MoveTableOrder>(_onMoveTableOrder);
    on<MergeTableOrder>(_onMergeTableOrder);
    on<VoidOrderItem>(_onVoidOrderItem);
    on<SubscribeToTableUpdates>(_onSubscribe);
    on<UnsubscribeFromTableUpdates>(_onUnsubscribe);
    on<UpdateTableOrder>(_onUpdateTableOrder);
  }

  Future<void> _onUpdateTableOrder(UpdateTableOrder event, Emitter<TableState> emit) async {
    emit(TableLoading());
    try {
      final order = await tableService.updateOrder(event.orderId, event.data);
      emit(TableOrderLoaded(order));
      emit(const TableActionSuccess('Đã cập nhật đơn hàng thành công'));
    } catch (e) {
      emit(const TableActionFailure('Cập nhật đơn hàng thất bại'));
    }
  }

  Future<void> _onSubscribe(SubscribeToTableUpdates event, Emitter<TableState> emit) async {
    _currentConfigId = event.configId;
    debugPrint("TableBloc: Subscribe configId=$_currentConfigId");

    // Join room
    socketManager.emit('joinConfigRoom', {'configId': event.configId});

    // Listen for changes
    socketManager.on('TABLE_STATUS_CHANGED', (data) {
      debugPrint("TableBloc: WS TABLE_STATUS_CHANGED: $data");
      if (_currentConfigId != null) {
        add(FetchZones(_currentConfigId!));
      }
    });

    socketManager.on('TEMP_ORDER_UPDATED', (data) {
      debugPrint("TableBloc: WS TEMP_ORDER_UPDATED: $data");
      if (_currentConfigId != null) {
        add(FetchZones(_currentConfigId!));
      }
    });
  }

  Future<void> _onUnsubscribe(UnsubscribeFromTableUpdates event, Emitter<TableState> emit) async {
    debugPrint("TableBloc: Unsubscribe");
    socketManager.off('TABLE_STATUS_CHANGED');
    socketManager.off('TEMP_ORDER_UPDATED');
    _currentConfigId = null;
  }

  Future<void> _onFetchZones(FetchZones event, Emitter<TableState> emit) async {
    emit(TableLoading());
    try {
      final zones = await tableService.getZones(event.configId);
      emit(ZonesLoaded(zones));
    } catch (e) {
      emit(const TableActionFailure('Không thể tải danh sách khu vực. Vui lòng thử lại sau.'));
    }
  }

  Future<void> _onFetchTables(FetchTables event, Emitter<TableState> emit) async {
    emit(TableLoading());
    try {
      final tables = await tableService.getTables(event.zoneId);
      emit(TablesLoaded(tables));
    } catch (e) {
      emit(const TableActionFailure('Không thể tải danh sách bàn. Vui lòng thử lại sau.'));
    }
  }

  Future<void> _onCreateZone(CreateZone event, Emitter<TableState> emit) async {
    emit(TableLoading());
    try {
      await tableService.createZone(event.data);
      emit(const TableActionSuccess('Đã tạo khu vực mới thành công.'));
    } catch (e) {
      emit(const TableActionFailure('Tạo khu vực thất bại. Vui lòng kiểm tra lại thông tin.'));
    }
  }

  Future<void> _onUpdateZone(UpdateZone event, Emitter<TableState> emit) async {
    emit(TableLoading());
    try {
      await tableService.updateZone(event.id, event.data);
      emit(const TableActionSuccess('Cập nhật khu vực thành công.'));
    } catch (e) {
      emit(const TableActionFailure('Cập nhật khu vực không thành công.'));
    }
  }

  Future<void> _onDeleteZone(DeleteZone event, Emitter<TableState> emit) async {
    emit(TableLoading());
    try {
      await tableService.deleteZone(event.id);
      emit(const TableActionSuccess('Đã xóa khu vực.'));
    } catch (e) {
      emit(const TableActionFailure('Không thể xóa khu vực. Vui lòng thử lại.'));
    }
  }

  Future<void> _onCreateTable(CreateTable event, Emitter<TableState> emit) async {
    emit(TableLoading());
    try {
      await tableService.createTable(event.data);
      emit(const TableActionSuccess('Đã thêm bàn mới thành công.'));
    } catch (e) {
      emit(const TableActionFailure('Lỗi khi thêm bàn mới.'));
    }
  }

  Future<void> _onUpdateTable(UpdateTable event, Emitter<TableState> emit) async {
    emit(TableLoading());
    try {
      await tableService.updateTable(event.id, event.data);
      emit(const TableActionSuccess('Cập nhật thông tin bàn thành công.'));
    } catch (e) {
      emit(const TableActionFailure('Cập nhật thông tin bàn thất bại.'));
    }
  }

  Future<void> _onDeleteTable(DeleteTable event, Emitter<TableState> emit) async {
    emit(TableLoading());
    try {
      await tableService.deleteTable(event.id);
      emit(const TableActionSuccess('Đã xóa bàn.'));
    } catch (e) {
      emit(const TableActionFailure('Không thể xóa bàn vào lúc này.'));
    }
  }

  Future<void> _onCreateTempOrder(CreateTempOrder event, Emitter<TableState> emit) async {
    emit(TableLoading());
    try {
      await tableService.createTempOrder(
        userId: event.userId,
        tableId: event.tableId,
        items: event.items,
        note: event.note,
      );
      emit(const TableActionSuccess('Đã gửi yêu cầu gọi món thành công.'));
    } catch (e) {
      emit(const TableActionFailure('Gửi yêu cầu gọi món thất bại. Vui lòng thử lại.'));
    }
  }

  Future<void> _onFetchTableOrder(FetchTableOrder event, Emitter<TableState> emit) async {
    emit(TableLoading());
    try {
      final order = await tableService.getOrderDetails(event.orderId);
      if (order != null) {
        emit(TableOrderLoaded(order));
      } else {
        emit(TableActionFailure('Không tìm thấy thông tin đơn hàng'));
      }
    } catch (e) {
      emit(TableActionFailure('Lỗi khi lấy thông tin đơn hàng'));
    }
  }

  Future<void> _onMoveTableOrder(MoveTableOrder event, Emitter<TableState> emit) async {
    emit(TableLoading());
    try {
      await tableService.moveTable(orderId: event.orderId, toTableId: event.toTableId);
      emit(const TableActionSuccess('Chuyển bàn thành công'));
    } catch (e) {
      emit(const TableActionFailure('Không thể chuyển bàn. Vui lòng thử lại sau.'));
    }
  }

  Future<void> _onMergeTableOrder(MergeTableOrder event, Emitter<TableState> emit) async {
    emit(TableLoading());
    try {
      await tableService.mergeTable(sourceOrderId: event.sourceOrderId, destinationOrderId: event.destinationOrderId);
      emit(const TableActionSuccess('Gộp bàn thành công'));
    } catch (e) {
      emit(const TableActionFailure('Không thể gộp bàn. Vui lòng thử lại sau.'));
    }
  }

  Future<void> _onVoidOrderItem(VoidOrderItem event, Emitter<TableState> emit) async {
    emit(TableLoading());
    try {
      await tableService.voidItem(
        orderId: event.orderId,
        productId: event.productId,
        quantity: event.quantity,
        reason: event.reason,
      );
      emit(const TableActionSuccess('Hủy món thành công'));
    } catch (e) {
      emit(const TableActionFailure('Không thể hủy món. Vui lòng thử lại sau.'));
    }
  }
}
