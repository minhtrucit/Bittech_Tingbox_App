import 'dart:io';

import 'package:ting_box/models/product.dart';

sealed class ProductEvent {}

final class LoadCategoriesEvent extends ProductEvent {
  LoadCategoriesEvent();
}

final class CreateProductEvent extends ProductEvent {
  final Product productData;
  final List<File> images;
  CreateProductEvent({required this.productData, required this.images});
}