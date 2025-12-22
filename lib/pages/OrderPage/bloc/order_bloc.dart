import 'dart:math';
import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:ting_box/pages/SalesPage/Components/confirm_order_dialog.dart';
import 'package:ting_box/pages/OrderPage/bloc/order_event.dart';
import 'package:ting_box/pages/OrderPage/bloc/order_state.dart';
import 'package:ting_box/services/order_service.dart';

import '../../../models/payment_info.dart';
import '../../../models/order.dart';

class OrderBloc extends Bloc<OrderEvent, OrderState> {
  final OrderService orderService;
  OrderBloc({required this.orderService}) : super(OrderInitial()) {
    on<OrderCreateOrderEvent>(_onCreateOrder);
    on<OrderPaymentSuccessEvent>(_onPaymentSuccess);
    on<OrderGetStatisticsEvent>(_onGetStatisticOverview);
    on<OrderGetAllOrdersbyUserIdEvent>(_onGetAllOrdersbyUserId);
    on<OrderSePayWebHookEvent>(_onSePayWebHook);
    on<OrderGenerateQRCodeEvent>(_onGenerateQRCode);
    on<OrderUpdateStatusEvent>(_onUpdateOrderStatus);
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
          ?.toString()
          .toLowerCase()) {
        'bank_transfer' => PaymentMethod.BANK_TRANSFER,
        'cash' => PaymentMethod.CASH,
        _ => PaymentMethod.BANK_TRANSFER, // default
      }; // Nếu thành công trả về 201 (trong service đã check), emit success

      debugPrint("📝 Payment method from bloc: $paymentMethod");
      emit(
        OrderCreateSuccess(
          orderId: response['data']['id'],
          userId: event.order.userId,
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
      // Lấy orderId từ data
      final orderId = data["data"]["id"] as int?;
      Order? order;

      // Fetch order details để có thể in hóa đơn
      if (orderId != null) {
        try {
          order = await orderService.getOrdersbyOrderId(orderId: orderId);
        } catch (e) {
          debugPrint("⚠️ [OrderBloc] Failed to fetch order for printing: $e");
        }
      }

      emit(
        OrderPaymentSuccess(
          orderId: orderId,
          message: "Khách đã thanh toán thành công!",
          order: order, // Truyền order để có thể in
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
      debugPrint("revenue: ${result.ordersByPaymentMethod.items.length}");
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

  Future<void> _onGetAllOrdersbyUserId(
    OrderGetAllOrdersbyUserIdEvent event,
    Emitter<OrderState> emit,
  ) async {
    // Chỉ emit loading khi load trang đầu tiên
    if (event.page == 1) {
      emit(OrderLoading());
    }

    try {
      debugPrint(
        "🚀 [OrderBloc] Bắt đầu gọi API lấy danh sách đơn hàng page ${event.page}, paymentStatus: ${event.paymentStatus}...",
      );

      // Gọi API từ service
      final response = await orderService.getAllOrdersbyUserId(
        userId: event.userId,
        page: event.page,
        limit: event.limit,
        paymentStatus: event.paymentStatus,
      );
      final newOrders = response.orders;
      final pagination = response.pagination;

      List<Order> allOrders = [];

      // Nếu là load more (page > 1) và state hiện tại là success, merge với list cũ
      if (event.page != null &&
          event.page! > 1 &&
          state is OrderGetAllOrdersSuccess) {
        allOrders = List.from((state as OrderGetAllOrdersSuccess).orders)
          ..addAll(newOrders);
      } else {
        allOrders = newOrders;
      }

      // Tính toán canLoadMore dựa trên pagination info
      final canLoadMore =
          pagination != null
              ? (pagination.page < pagination.totalPages)
              : false;

      debugPrint(
        "📌 [OrderBloc] API trả về: ${newOrders.length} orders. Total: ${allOrders.length}",
      );

      emit(
        OrderGetAllOrdersSuccess(
          orders: allOrders,
          canLoadMore: canLoadMore,
          page: event.page,
        ),
      );

      debugPrint("✅ [OrderBloc] Emit state thành công.");
    } catch (e, stacktrace) {
      debugPrint("❌ [OrderBloc] Lỗi lấy danh sách đơn hàng:");
      debugPrint("Error: $e");
      debugPrint("Stacktrace: $stacktrace");

      emit(OrderFailure(message: e.toString()));
    }
  }

  Future<void> _onSePayWebHook(
    OrderSePayWebHookEvent event,
    Emitter<OrderState> emit,
  ) async {
    try {
      final randomId = Random().nextInt(100000000);
      final body = {
        "id": randomId, // ID giao dịch trên SePay
        "gateway": "Vietcombank", // Brand name của ngân hàng
        "transactionDate":
            DateTime.now()
                .toIso8601String(), // Thời gian xảy ra giao dịch phía ngân hàng
        "accountNumber":
            event.paymentInfo.accountNumber, // Số tài khoản ngân hàng
        "code":
            event
                .orderCode, // Mã code thanh toán (sepay tự nhận diện dựa vào cấu hình tại Công ty -> Cấu hình chung)
        "content": "${event.orderCode}_251121-0001", // Nội dung chuyển khoản
        "transferType": "in", // Loại giao dịch. in là tiền vào, out là tiền ra
        "transferAmount": event.transferAmount, // Số tiền giao dịch
        "accumulated": 19077000, // Số dư tài khoản (lũy kế)
        "subAccount": null, // Tài khoản ngân hàng phụ (tài khoản định danh),
        "referenceCode":
            "MBVCB.hxtgwss31a3fhxrh${event.orderCode}.$randomId", // Mã tham chiếu của tin nhắn sms
        "description": "", // Toàn bộ nội dung tin nhắn sms
      };

      // Gọi API từ service
      final result = await orderService.handleSePayWebHook(body: body);

      if (result['message'] == "Xử lý webhook SePay thành công") {
        // Fetch orders to find the paid order
        Order? paidOrder;
        try {
          final response = await orderService.getOrdersbyOrderId(
            orderId: event.orderId,
          );
          paidOrder = response;
        } catch (e) {
          debugPrint("⚠️ [OrderBloc] Failed to fetch order for printing: $e");
        }

        emit(OrderSePayWebHookSuccess(message: result['message']));
        emit(
          OrderPaymentSuccess(
            message: "Khách đã thanh toán thành công!",
            order: paidOrder,
          ),
        );

        if (paidOrder != null) {
          add(
            OrderGetAllOrdersbyUserIdEvent(userId: paidOrder.userId, page: 1),
          );
        }
      } else {
        emit(OrderSePayWebHookFailed(message: result['message']));
      }
    } catch (e, stacktrace) {
      debugPrint("❌ [OrderBloc] Lỗi Sepay Webhook:");
      debugPrint("Error: $e");
      debugPrint("Stacktrace: $stacktrace");

      emit(OrderFailure(message: e.toString()));
    }
  }

  Future<void> _onGenerateQRCode(
    OrderGenerateQRCodeEvent event,
    Emitter<OrderState> emit,
  ) async {
    // Don't emit OrderLoading to avoid affecting OrdersListPage UI
    try {
      debugPrint("🚀 [OrderBloc] Bắt đầu gọi API generate QR code...");

      // Gọi API từ service
      final result = await orderService.generateOrderQRCode(
        orderId: event.orderId,
      );

      emit(
        OrderGenerateQRCodeSuccess(
          message: "Generate QR code thành công",
          paymentInfo: PaymentInfo.fromJson(result['paymentInfo']),
        ),
      );
      debugPrint("✅ [OrderBloc] Emit state thành công.");
    } catch (e, stacktrace) {
      debugPrint("❌ [OrderBloc] Lỗi generate QR code:");
      debugPrint("Error: $e");
      debugPrint("Stacktrace: $stacktrace");

      emit(OrderFailure(message: e.toString()));
    }
  }

  Future<void> _onUpdateOrderStatus(
    OrderUpdateStatusEvent event,
    Emitter<OrderState> emit,
  ) async {
    emit(OrderUpdateStatusLoading());
    try {
      final updatedOrder = await orderService.updateStatusOrdersbyOrderId(
        orderId: event.orderId,
        paymentStatus: event.status,
      );
      emit(
        OrderUpdateStatusSuccess(
          order: updatedOrder,
          message: "Cập nhật trạng thái đơn hàng thành công",
        ),
      );
    } catch (e) {
      emit(OrderUpdateStatusFailure(message: e.toString()));
    }
  }
}
