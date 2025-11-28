import 'package:ting_box/models/payment_info.dart';
import 'package:ting_box/ting_box.dart';

sealed class OrderState {}

final class OrderInitial extends OrderState {}

final class OrderLoading extends OrderState {}

final class OrderCreateSuccess extends OrderState {
  final bool success;
  final PaymentMethod? paymentMethod;
  final PaymentInfo? paymentInfo;
  OrderCreateSuccess({
    required this.success,
    this.paymentInfo,
    this.paymentMethod,
  });
}

final class OrderFailure extends OrderState {
  final String message;
  OrderFailure({required this.message});
}

class OrderPaymentSuccess extends OrderState {
  final int orderId;
  final String message;

  OrderPaymentSuccess({required this.orderId, required this.message});
}

class OrderPaymentFailed extends OrderState {
  final int orderId;
  final String message;
  OrderPaymentFailed({required this.orderId, required this.message});
}

final class OrderGetStatisticSuccess extends OrderState {
  final StatisticOrder statistic;
  OrderGetStatisticSuccess({required this.statistic});
}

final class OrderGetAllOrdersSuccess extends OrderState {
  final List<Order> orders;
  OrderGetAllOrdersSuccess({required this.orders});
}

