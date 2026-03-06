import 'package:ting_box/models/menu.dart';
import 'package:ting_box/models/product.dart';

sealed class ProductState {}

final class ProductInitial extends ProductState {}

final class ProductLoading extends ProductState {}

final class ProductLoadCategoriesSuccess extends ProductState {
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

final class ProductLoadProductsSuccess extends ProductState {
  final List<Product> products;
  ProductLoadProductsSuccess({required this.products});
}

final class ProductUpdateSuccess extends ProductState {
  final Product product;
  ProductUpdateSuccess({required this.product});
}

final class ProductUpdateEmbeddingSuccess extends ProductState {
  ProductUpdateEmbeddingSuccess();
}

final class ProductDeleteSuccess extends ProductState {
  ProductDeleteSuccess();
}

final class MenuScanSuccess extends ProductState {
  final Menu menu;
  MenuScanSuccess({required this.menu});
}

final class MenuScanFailure extends ProductState {
  final String message;
  MenuScanFailure(this.message);
}

final class MenuUploadSucess extends ProductState {
  final Menu menu;
  MenuUploadSucess({required this.menu});
}

final class MenuUploadFailure extends ProductState {
  final String message;
  MenuUploadFailure(this.message);
}

final class MenuScanProcessing extends ProductState {
  MenuScanProcessing();
}

final class ProductMenuScanResultState extends ProductState {
  final Menu menu;
  ProductMenuScanResultState({required this.menu});
}

final class ProductBatchCreateSuccess extends ProductState {
  final int count;
  ProductBatchCreateSuccess({required this.count});
}
