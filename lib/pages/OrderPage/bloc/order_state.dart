import 'package:ting_box/models/payment_info.dart';
import 'package:ting_box/ting_box.dart';

sealed class OrderState {}

final class OrderInitial extends OrderState {}

final class OrderLoading extends OrderState {}

final class OrderCreateSuccess extends OrderState {
  final bool success;
  final PaymentMethod? paymentMethod;
  final PaymentInfo? paymentInfo;
  final String orderCode;
  OrderCreateSuccess({
    required this.success,
    this.paymentInfo,
    this.paymentMethod,
    required this.orderCode,
  });
}

final class OrderFailure extends OrderState {
  final String message;
  OrderFailure({required this.message});
}

class OrderPaymentSuccess extends OrderState {
  final int? orderId;
  final String message;

  OrderPaymentSuccess({this.orderId, required this.message});
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

final class OrderSePayWebHookSuccess extends OrderState {
  final String message;
  OrderSePayWebHookSuccess({required this.message});
}


final class OrderGenerateQRCodeSuccess extends OrderState {
  final String message;
  final PaymentInfo? paymentInfo;
  OrderGenerateQRCodeSuccess({required this.message, this.paymentInfo});
}
