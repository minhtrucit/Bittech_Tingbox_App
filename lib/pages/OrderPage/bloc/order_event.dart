import '../../../models/payment_info.dart';
import '../../../models/order.dart';

sealed class OrderEvent {}

final class OrderCreateOrderEvent extends OrderEvent {
  final Order order;
  OrderCreateOrderEvent({required this.order});
}

class OrderPaymentSuccessEvent extends OrderEvent {
  final Map<String, dynamic> data;
  OrderPaymentSuccessEvent(this.data);
}

class OrderGetStatisticsEvent extends OrderEvent {}

class OrderGetAllOrdersbyUserIdEvent extends OrderEvent {
  final int? page;
  final int limit;
  final int? paymentStatus;
  final int userId;

  OrderGetAllOrdersbyUserIdEvent({
    this.page,
    this.limit = 10,
    this.paymentStatus,
    required this.userId,
  });
}

class OrderSePayWebHookEvent extends OrderEvent {
  final int orderId;
  final String orderCode;
  final int transferAmount;
  final String transactionDate;
  final PaymentInfo paymentInfo;
  OrderSePayWebHookEvent({
    required this.orderId,
    required this.orderCode,
    required this.transferAmount,
    required this.transactionDate,
    required this.paymentInfo,
  });
}

class OrderGenerateQRCodeEvent extends OrderEvent {
  final String orderId;
  OrderGenerateQRCodeEvent({required this.orderId});
}

class OrderUpdateStatusEvent extends OrderEvent {
  final int orderId;
  final String status;
  OrderUpdateStatusEvent({required this.orderId, required this.status});
}
