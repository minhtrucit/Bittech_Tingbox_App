import 'dart:io';

import 'package:ting_box/models/menu.dart';
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

final class MenuUploadEvent extends ProductEvent {
  final String imagePath;
  MenuUploadEvent({required this.imagePath});
}

final class MenuOcrStatusUpdatedEvent extends ProductEvent {
  final Menu menu;
  MenuOcrStatusUpdatedEvent({required this.menu});
}

final class CreateBatchProductsEvent extends ProductEvent {
  final List<Product> products;
  CreateBatchProductsEvent({required this.products});
}
