import 'package:ting_box/models/payment_info.dart';
import 'package:ting_box/ting_box.dart';

sealed class OrderState {}

final class OrderInitial extends OrderState {}

final class OrderLoading extends OrderState {}

final class OrderCreateSuccess extends OrderState {
  final bool success;
  final int orderId;
  final int userId;
  final PaymentMethod? paymentMethod;
  final PaymentInfo? paymentInfo;
  final String orderCode;
  final String? createdAt;
  OrderCreateSuccess({
    required this.success,
    required this.orderId,
    required this.userId,
    this.paymentInfo,
    this.paymentMethod,
    required this.orderCode,
    this.createdAt,
  });
}

final class OrderFailure extends OrderState {
  final String message;
  OrderFailure({required this.message});
}

class OrderPaymentSuccess extends OrderState {
  final int? orderId;
  final String message;
  final Order? order;

  OrderPaymentSuccess({this.orderId, required this.message, this.order});
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
  final bool canLoadMore;
  final int? page;

  OrderGetAllOrdersSuccess({
    required this.orders,
    this.canLoadMore = false,
    this.page,
  });
}

final class OrderGetOrdersbyOrderIdSuccess extends OrderState {
  final Order order;
  OrderGetOrdersbyOrderIdSuccess({required this.order});
}

final class OrderSePayWebHookLoading extends OrderState {}

final class OrderSePayWebHookSuccess extends OrderState {
  final String message;
  OrderSePayWebHookSuccess({required this.message});
}

final class OrderSePayWebHookFailed extends OrderState {
  final String message;
  OrderSePayWebHookFailed({required this.message});
}

final class OrderGenerateQRCodeSuccess extends OrderState {
  final String message;
  final PaymentInfo? paymentInfo;
  OrderGenerateQRCodeSuccess({required this.message, this.paymentInfo});
}

final class OrderUpdateStatusLoading extends OrderState {}

final class OrderUpdateStatusSuccess extends OrderState {
  final Order order;
  final String message;
  OrderUpdateStatusSuccess({required this.order, required this.message});
}

final class OrderUpdateStatusFailure extends OrderState {
  final String message;
  OrderUpdateStatusFailure({required this.message});
}
