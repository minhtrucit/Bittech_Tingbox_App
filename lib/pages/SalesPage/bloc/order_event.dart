import '../../../models/order.dart';

sealed class OrderEvent{}

final class OrderCreateOrderEvent extends OrderEvent {
  final Order order;
  OrderCreateOrderEvent({required this.order});
}