import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:ting_box/pages/SalesPage/Components/confirm_order_dialog.dart';
import 'package:ting_box/pages/OrderPage/bloc/order_event.dart';
import 'package:ting_box/pages/OrderPage/bloc/order_state.dart';
import 'package:ting_box/services/order_service.dart';

import '../../../models/payment_info.dart';

class OrderBloc extends Bloc<OrderEvent, OrderState> {
  final OrderService orderService;
  OrderBloc({required this.orderService}) : super(OrderInitial()) {
    on<OrderCreateOrderEvent>(_onCreateOrder);
    on<OrderPaymentSuccessEvent>(_onPaymentSuccess);
    on<OrderGetStatisticsEvent>(_onGetStatisticOverview);
    on<OrderGetAllOrdersEvent>(_onGetAllOrders);
    on<OrderSePayWebHookEvent>(_onSePayWebHook);
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
          orderCode: response['data']['code'],
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

  Future<void> _onGetAllOrders(
    OrderGetAllOrdersEvent event,
    Emitter<OrderState> emit,
  ) async {
    emit(OrderLoading());

    try {
      debugPrint("🚀 [OrderBloc] Bắt đầu gọi API thống kê...");

      // Gọi API từ service
      final result = await orderService.getAllOrders();

      debugPrint("📌 [OrderBloc] API trả về Statistic:");
      debugPrint("orders: ${result.length}");
      // Nếu có thêm field khác thì log thêm ở đây

      emit(OrderGetAllOrdersSuccess(orders: result));

      debugPrint("✅ [OrderBloc] Emit state thành công.");
    } catch (e, stacktrace) {
      debugPrint("❌ [OrderBloc] Lỗi lấy thống kê:");
      debugPrint("Error: $e");
      debugPrint("Stacktrace: $stacktrace");

      emit(OrderFailure(message: e.toString()));
    }
  }

  Future<void> _onSePayWebHook(
    OrderSePayWebHookEvent event,
    Emitter<OrderState> emit,
  ) async {
    emit(OrderLoading());

    try {
      debugPrint("🚀 [OrderBloc] Bắt đầu gọi API thống kê...");

      final body = {
        "id": 45454545, // ID giao dịch trên SePay
        "gateway": "Vietcombank", // Brand name của ngân hàng
        "transactionDate":
            "2023-03-25 14:02:37", // Thời gian xảy ra giao dịch phía ngân hàng
        "accountNumber": "0123499999", // Số tài khoản ngân hàng
        "code":
            event
                .orderCode, // Mã code thanh toán (sepay tự nhận diện dựa vào cấu hình tại Công ty -> Cấu hình chung)
        "content": "${event
                .orderCode}_251121-0001", // Nội dung chuyển khoản
        "transferType": "in", // Loại giao dịch. in là tiền vào, out là tiền ra
        "transferAmount": 896000, // Số tiền giao dịch
        "accumulated": 19077000, // Số dư tài khoản (lũy kế)
        "subAccount": null, // Tài khoản ngân hàng phụ (tài khoản định danh),
        "referenceCode":
            "MBVCB.hxtgw3a3fhxrh${event.orderCode}", // Mã tham chiếu của tin nhắn sms
        "description": "", // Toàn bộ nội dung tin nhắn sms
      };

      // Gọi API từ service
      final result = await orderService.handleSePayWebHook(body: body);

      debugPrint("📌 [OrderBloc] API trả về Sepay Webhook");
      debugPrint("orders: ${result.length}");
      // Nếu có thêm field khác thì log thêm ở đây

      emit(OrderSePayWebHookSuccess(message: "Sepay Webhook thành công"));
      emit(OrderPaymentSuccess(message: "Khách đã thanh toán thành công!"));
      debugPrint("✅ [OrderBloc] Emit state thành công.");
    } catch (e, stacktrace) {
      debugPrint("❌ [OrderBloc] Lỗi Sepay Webhook:");
      debugPrint("Error: $e");
      debugPrint("Stacktrace: $stacktrace");

      emit(OrderFailure(message: e.toString()));
    }
  }
}
