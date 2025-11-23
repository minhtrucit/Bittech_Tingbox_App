import '../../../models/order.dart';

sealed class OrderEvent{}

final class OrderCreateOrderEvent extends OrderEvent {
  final Order order;
  OrderCreateOrderEvent({required this.order});
}


class OrderRealtimeEvent extends OrderEvent {
  final Map<String, dynamic> data;
  OrderRealtimeEvent(this.data);
}