import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:ting_box/pages/SalesPage/Components/confirm_order_dialog.dart';
import 'package:ting_box/pages/SalesPage/bloc/order_event.dart';
import 'package:ting_box/pages/SalesPage/bloc/order_state.dart';
import 'package:ting_box/services/order_service.dart';

import '../../../models/payment_info.dart';

class OrderBloc extends Bloc<OrderEvent, OrderState> {
  final OrderService orderService;
  OrderBloc({required this.orderService})
    : super(OrderInitial()) {
    on<OrderCreateOrderEvent>(_onCreateOrder);
    on<OrderPaymentSuccessEvent>(_onPaymentSuccess);
    on<OrderGetStatisticsEvent>(_onGetStatisticOverview);
    
  }
  Future<void> _onCreateOrder(
    OrderCreateOrderEvent event,
    Emitter<OrderState> emit,
  ) async {
    emit(OrderLoading()); // Bắt đầu loading
    try {
      // Log dữ liệu order

      final body = {
        "userId": event.order.userId,
        "distributorId": event.order.distributorId,
        "customerName": event.order.customerName,
        "customerPhone": event.order.customerPhone,
        "customerEmail": event.order.customerEmail,
        "shippingAddress": event.order.shippingAddress,
        "discount": event.order.discount,
        "paymentMethod": event.order.paymentMethod,
        "note": event.order.note,
        "items": event.order.items,
      };

      debugPrint("📤 Sending order data: ${event.order.toJson()}");

      // Gọi service
      final response = await orderService.createOrder(body: body);

      debugPrint("📩 API Responseqưe: $response");

      // final order = response['data'
      final paymentData = response['data']['paymentInfo'];
      final paymentMethod = switch (response['data']['paymentMethod']
          ?.toString()) {
        'BANK_TRANSFER' => PaymentMethod.BANK_TRANSFER,
        'CASH' => PaymentMethod.CASH,
        _ => PaymentMethod.BANK_TRANSFER, // default
      }; // Nếu thành công trả về 201 (trong service đã check), emit success
      emit(
        OrderCreateSuccess(
          success: true,
          paymentInfo:
              paymentData != null ? PaymentInfo.fromJson(paymentData) : null,
          paymentMethod: paymentMethod,
        ),
      );
    } catch (e, st) {
      // Log lỗi đầy đủ với stacktrace
      debugPrint("❌ Failed to create order: $e");
      debugPrint("🛠 Stacktrace: $st");

      // Có thể emit một state lỗi nếu muốn, ví dụ OrderError
      emit(OrderFailure(message: e.toString()));
    }
  }

  Future<void> _onPaymentSuccess(
    OrderPaymentSuccessEvent event,
    Emitter<OrderState> emit,
  ) async {
    final data = event.data;

    if (data["event"] == "payment.success") {
      emit(
        OrderPaymentSuccess(
          orderId: data["data"]["id"],
          message: "Khách đã thanh toán thành công!",
        ),
      );
    } else {
      emit(OrderFailure(message: "Thanh toán thất bại!"));
    }
  }

  Future<void> _onGetStatisticOverview(
    OrderGetStatisticsEvent event,
    Emitter<OrderState> emit,
  ) async {
    emit(OrderLoading());

    try {
      debugPrint("🚀 [OrderBloc] Bắt đầu gọi API thống kê...");

      // Gọi API từ service
      final result = await orderService.getStatisticsOverview();

      debugPrint("📌 [OrderBloc] API trả về Statistic:");
      debugPrint("recentOrders: ${result.recentOrders.length}");
      debugPrint("revenue: ${result.revenue.toJson()}");
      // Nếu có thêm field khác thì log thêm ở đây

      emit(OrderGetStatisticSuccess(statistic: result));

      debugPrint("✅ [OrderBloc] Emit state thành công.");
    } catch (e, stacktrace) {
      debugPrint("❌ [OrderBloc] Lỗi lấy thống kê:");
      debugPrint("Error: $e");
      debugPrint("Stacktrace: $stacktrace");

      emit(OrderFailure(message: e.toString()));
    }
  }
}
