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

final class GetProductsEvent extends ProductEvent {
  GetProductsEvent();
}

final class UpdateProductEvent extends ProductEvent {
  final Product productData;
  final List<File>? newImages;
  UpdateProductEvent({required this.productData, this.newImages});
}

final class UpdateProductEmbeddingEvent extends ProductEvent {
  final int productId;
  final List<String> imageUrls;
  UpdateProductEmbeddingEvent({
    required this.productId,
    required this.imageUrls,
  });
}

final class DeleteProductEvent extends ProductEvent {
  final int productId;
  DeleteProductEvent({required this.productId});
}
