import 'package:ting_box/models/product.dart';

sealed class ProductState {}

final class ProductInitial extends ProductState {}

final class ProductLoading extends ProductState {}

final class ProductLoadCategoriesSuccess extends ProductState{
  final List<String> categories;
  ProductLoadCategoriesSuccess({required this.categories});
}

final class ProductFailure extends ProductState {
  final String message;
  ProductFailure(this.message);
}

final class ProductCreateSuccess extends ProductState {
  final Product product;
  ProductCreateSuccess({required this.product});
}