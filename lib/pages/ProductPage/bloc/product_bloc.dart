import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:ting_box/services/product_api_services.dart';
import 'package:ting_box/ting_box.dart';

class ProductBloc extends Bloc<ProductEvent, ProductState> {
  final ProductApiService productApiService;

  ProductBloc({required this.productApiService}) : super(ProductInitial()) {
    on<LoadCategoriesEvent>(_onLoadCategories);
    on<CreateProductEvent>(_onCreateProduct);
  }

  Future<void> _onLoadCategories(
    LoadCategoriesEvent event,
    Emitter<ProductState> emit,
  ) async {
    debugPrint('[ProductBloc] _onLoadCategories: received LoadCategoriesEvent');

    emit(ProductLoading());
    debugPrint('[ProductBloc] _onLoadCategories: ProductLoading emitted');

    try {
      debugPrint(
        '[ProductBloc] _onLoadCategories: calling productApiService.getAllCategories...',
      );
      final response = await productApiService.getAllCategories();

      debugPrint(
        '[ProductBloc] _onLoadCategories: response=${response?.length}',
      );

      // response['data'] là List<dynamic>
      final List<dynamic> data = response ?? [];

      // Chỉ lấy tên các category
      final List<String> categoryNames =
          data.map((e) => e['name'] as String).toList();

      emit(ProductLoadCategoriesSuccess(categories: categoryNames));
      debugPrint(
        '[ProductBloc] _onLoadCategories: ProductLoadCategoriesSuccess emitted',
      );
    } catch (e, st) {
      debugPrint(
        '[ProductBloc] _onLoadCategories: exception caught -> $e\n$st',
      );
      emit(ProductFailure('Failed to load categories'));
      debugPrint('[ProductBloc] _onLoadCategories: ProductFailure emitted');
    }
  }

  Future<void> _onCreateProduct(
    CreateProductEvent event,
    Emitter<ProductState> emit,
  ) async {
    emit(ProductLoading());

    try {
      final body = {
        "name": event.productData.name,
        "price": event.productData.price,
        "categoryId": event.productData.categoryId,
        "description": event.productData.description,
        "images": event.productData.images,
        "distributorId": 1,
      };
      final response = await productApiService.createProduct(body: body, images: event.images);
      final product = Product.fromJson(response['data']);
      emit(ProductCreateSuccess(product: product));
    } catch (e) {
      emit(ProductFailure('Failed to create product'));
    }
  }
}
