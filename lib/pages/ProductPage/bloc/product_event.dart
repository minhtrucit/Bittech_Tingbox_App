import 'package:ting_box/models/product.dart';

sealed class ProductEvent {}

final class LoadCategoriesEvent extends ProductEvent {
  LoadCategoriesEvent();
}

final class CreateProductEvent extends ProductEvent {
  final Product productData;
  CreateProductEvent({required this.productData});
}