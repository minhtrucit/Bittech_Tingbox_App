

import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:ting_box/pages/SalesPage/bloc/order_event.dart';
import 'package:ting_box/pages/SalesPage/bloc/order_state.dart';
import 'package:ting_box/services/order_service.dart';

class OrderBloc extends Bloc<OrderEvent, OrderState> {
  final OrderService orderService;
  OrderBloc({required this.orderService}) : super(OrderInitial()) {
    on<OrderCreateOrderEvent>(_onCreateOrder);
  }


  Future<void> _onCreateOrder(
      OrderCreateOrderEvent event,
      Emitter<OrderState> emit,
      ) async {
    emit(OrderLoading()); // Bắt đầu loading
    try {
      // Log dữ liệu order

      final body = {
        "userId": 1,
        "distributorId": 2,
        "customerName": "Trần Lâm Huy",
        "customerPhone": "0909000111",
        "customerEmail": "nguyenvana@example.com",
        "shippingAddress": "123 Lê Lợi, Phường Bến Thành, Quận 1, TP. Hồ Chí Minh",
        "discount": 0,
        "paymentMethod": event.order.paymentMethod,
        "note": event.order.note,
        "items": event.order.items,
      };


      debugPrint("📤 Sending order data: ${body}");

      // Gọi service
      final response = await orderService.createOrder(
        body: body,
      );

      debugPrint("📩 API Response: $response");

      // Nếu thành công trả về 201 (trong service đã check), emit success
      emit(OrderCreateSuccess(success: true));
    } catch (e, st) {
      // Log lỗi đầy đủ với stacktrace
      debugPrint("❌ Failed to create order: $e");
      debugPrint("🛠 Stacktrace: $st");

      // Có thể emit một state lỗi nếu muốn, ví dụ OrderError
      // emit(OrderError(message: e.toString()));
    }
  }


}