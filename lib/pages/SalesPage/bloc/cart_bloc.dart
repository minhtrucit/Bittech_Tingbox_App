import 'package:flutter_bloc/flutter_bloc.dart';
import 'cart_event.dart';
import 'cart_state.dart';
import '../../../ting_box.dart';

class CartBloc extends Bloc<CartEvent, CartState> {
  CartBloc() : super(const CartState()) {
    on<AddToCartEvent>(_onAddToCart);
    on<RemoveFromCartEvent>(_onRemoveFromCart);
    on<UpdateQuantityEvent>(_onUpdateQuantity);
    on<ClearCartEvent>(_onClearCart);
  }

  void _onAddToCart(AddToCartEvent event, Emitter<CartState> emit) {
    final updatedItems = List<Product>.from(state.items);
    final index = updatedItems.indexWhere(
      (item) => item.id == event.product.id,
    );

    if (index != -1) {
      final existingItem = updatedItems[index];
      // Create a copy with updated quantity
      updatedItems[index] = Product(
        id: existingItem.id,
        name: existingItem.name,
        price: existingItem.price,
        url: existingItem.url,
        quantity: existingItem.quantity + 1,
        images: existingItem.images,
        description: existingItem.description,
        category: existingItem.category,
        isActive: existingItem.isActive,
      );
    } else {
      updatedItems.add(event.product);
    }

    emit(state.copyWith(items: updatedItems));
  }

  void _onRemoveFromCart(RemoveFromCartEvent event, Emitter<CartState> emit) {
    final updatedItems = List<Product>.from(state.items)
      ..removeWhere((item) => item.id == event.product.id);
    emit(state.copyWith(items: updatedItems));
  }

  void _onUpdateQuantity(UpdateQuantityEvent event, Emitter<CartState> emit) {
    final updatedItems = List<Product>.from(state.items);
    final index = updatedItems.indexWhere(
      (item) => item.id == event.product.id,
    );

    if (index != -1) {
      if (event.quantity <= 0) {
        updatedItems.removeAt(index);
      } else {
        final existingItem = updatedItems[index];
        updatedItems[index] = Product(
          id: existingItem.id,
          name: existingItem.name,
          price: existingItem.price,
          url: existingItem.url,
          quantity: event.quantity,
          images: existingItem.images,
          description: existingItem.description,
          category: existingItem.category,
          isActive: existingItem.isActive,
        );
      }
    }

    emit(state.copyWith(items: updatedItems));
  }

  void _onClearCart(ClearCartEvent event, Emitter<CartState> emit) {
    emit(const CartState());
  }
}
