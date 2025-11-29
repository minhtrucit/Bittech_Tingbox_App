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

class OrderGetAllOrdersEvent extends OrderEvent {}

class OrderSePayWebHookEvent extends OrderEvent {
  final String orderCode;
  OrderSePayWebHookEvent({required this.orderCode});
}

class OrderGenerateQRCodeEvent extends OrderEvent {
  final String orderId;
  OrderGenerateQRCodeEvent({required this.orderId});
}