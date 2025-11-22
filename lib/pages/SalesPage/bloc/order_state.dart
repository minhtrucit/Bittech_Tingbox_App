import 'package:ting_box/models/payment_info.dart';

import '../../../models/order.dart';

sealed class OrderState{}

final class OrderInitial extends OrderState {}

final class OrderLoading extends OrderState {}

final class OrderCreateSuccess extends OrderState {
  final bool success;
  final PaymentInfo? paymentInfo;
  OrderCreateSuccess({required this.success, this.paymentInfo});
}

final class OrderFailure extends OrderState{
  final String message;
  OrderFailure({required this.message});
}