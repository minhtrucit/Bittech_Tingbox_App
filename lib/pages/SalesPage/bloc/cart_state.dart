import 'package:equatable/equatable.dart';
import '../../../ting_box.dart';

class CartState extends Equatable {
  final List<Product> items;

  const CartState({this.items = const []});

  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);
  double get totalPrice =>
      items.fold(0.0, (sum, item) => sum + (item.price * item.quantity));

  @override
  List<Object?> get props => [items];

  CartState copyWith({List<Product>? items}) {
    return CartState(items: items ?? this.items);
  }
}
