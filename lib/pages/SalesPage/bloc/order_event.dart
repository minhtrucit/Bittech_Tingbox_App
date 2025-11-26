import '../../../models/order.dart';

sealed class OrderEvent{}

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
