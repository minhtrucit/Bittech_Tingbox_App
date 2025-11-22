sealed class OrderState{}

final class OrderInitial extends OrderState {}

final class OrderLoading extends OrderState {}

final class OrderCreateSuccess extends OrderState {
  final bool success;
  OrderCreateSuccess({required this.success});
}