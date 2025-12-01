import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:ting_box/services/product_api_services.dart';
import 'package:ting_box/ting_box.dart';

class ProductBloc extends Bloc<ProductEvent, ProductState> {
  final ProductApiService productApiService;

  ProductBloc({required this.productApiService}) : super(ProductInitial()) {
    on<LoadCategoriesEvent>(_onLoadCategories);
    on<CreateProductEvent>(_onCreateProduct);
    on<GetProductsEvent>(_onGetProducts);
    on<UpdateProductEvent>(_onUpdateProduct);
    on<UpdateProductEmbeddingEvent>(_onUpdateProductEmbedding);
    on<DeleteProductEvent>(_onDeleteProduct);
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

    try {
      final body = {
        "name": event.productData.name,
        "price": event.productData.price,
        "categoryId": event.productData.categoryId,
        "description": event.productData.description,
        "images": event.productData.images,
        "distributorId": 1,
      };
      final response = await productApiService.createProduct(
        body: body,
        images: event.images,
      );

      debugPrint('=== RESPONSE DATA ===');
      debugPrint(response['data'].toString());
      Product product;
      try {
        product = Product.fromJson(response['data']);
        debugPrint('=== PRODUCT PARSED ===');
        debugPrint(product.toJson().toString());
      } catch (jsonError, stackTrace) {
        debugPrint('=== JSON PARSE ERROR ===');
        debugPrint('Error: $jsonError');
        debugPrint('StackTrace: $stackTrace');
        rethrow; // ném tiếp để biết app crash ở đâu
      }

      emit(ProductCreateSuccess(product: product));
    } catch (e, st) {
      // 3️⃣ In toàn bộ exception và stack trace
      debugPrint('=== CREATE PRODUCT ERROR ===');
      debugPrint('Error: $e');
      debugPrint('StackTrace: $st');
      emit(ProductFailure('Failed to create product'));
    }
  }

  Future<void> _onGetProducts(
    GetProductsEvent event,
    Emitter<ProductState> emit,
  ) async {
    emit(ProductLoading());

    try {
      final response = await productApiService.getAllProducts();

      debugPrint('=== RESPONSE DATA ===');
      final List<dynamic> data = response['data'];

      final List<Product> products;
      try {
        products = data.map((e) => Product.fromJson(e)).toList();
        debugPrint('=== PRODUCT PARSED ===');
        debugPrint('products[0]: ${products[0].toJson()}');
      } catch (jsonError, stackTrace) {
        debugPrint('=== JSON PARSE ERROR ===');
        debugPrint('Error: $jsonError');
        debugPrint('StackTrace: $stackTrace');
        rethrow; // ném tiếp để biết app crash ở đâu
      }

      emit(
        ProductLoadProductsSuccess(
          products: products.where((e) => e.isActive == true).toList(),
        ),
      );
    } catch (e, st) {
      // 3️⃣ In toàn bộ exception và stack trace
      debugPrint('=== GET PRODUCTS ERROR ===');
      debugPrint('Error: $e');
      debugPrint('StackTrace: $st');
      emit(ProductFailure('Failed to get products'));
    }
  }

  Future<void> _onUpdateProduct(
    UpdateProductEvent event,
    Emitter<ProductState> emit,
  ) async {
    emit(ProductLoading());

    try {
      final body = {
        "name": event.productData.name,
        "price": event.productData.price,
        "categoryId": event.productData.categoryId,
        "description": event.productData.description,
        "distributorId": event.productData.distributorId ?? 1,
      };

      final response = await productApiService.updateProduct(
        productId: event.productData.id,
        body: body,
        newImages: event.newImages,
      );

      debugPrint('=== UPDATE RESPONSE DATA ===');
      debugPrint(response['data'].toString());

      Product product;
      try {
        product = Product.fromJson(response['data']);
        debugPrint('=== UPDATED PRODUCT PARSED ===');
        debugPrint(product.toJson().toString());
      } catch (jsonError, stackTrace) {
        debugPrint('=== JSON PARSE ERROR ===');
        debugPrint('Error: $jsonError');
        debugPrint('StackTrace: $stackTrace');
        rethrow;
      }

      emit(ProductUpdateSuccess(product: product));
    } catch (e, st) {
      debugPrint('=== UPDATE PRODUCT ERROR ===');
      debugPrint('Error: $e');
      debugPrint('StackTrace: $st');
      emit(ProductFailure('Failed to update product'));
    }
  }

  Future<void> _onUpdateProductEmbedding(
    UpdateProductEmbeddingEvent event,
    Emitter<ProductState> emit,
  ) async {
    try {
      debugPrint(
        '[ProductBloc] _onUpdateProductEmbedding: calling productApiService.updateEmbedding...',
      );
      await productApiService.updateEmbedding(
        productId: event.productId,
        imageUrls: event.imageUrls,
      );

      debugPrint('[ProductBloc] _onUpdateProductEmbedding: success');
    } catch (e, st) {
      debugPrint('[ProductBloc] _onUpdateProductEmbedding: error -> $e');
      debugPrint('Stack trace: $st');
    }
  }

  Future<void> _onDeleteProduct(
    DeleteProductEvent event,
    Emitter<ProductState> emit,
  ) async {
    try {
      debugPrint('=== DELETE PRODUCT ===');
      debugPrint('Product ID: ${event.productId}');
      await productApiService.deleteProduct(event.productId);
      emit(ProductDeleteSuccess());
    } catch (e, st) {
      debugPrint('=== DELETE PRODUCT ERROR ===');
      debugPrint('Error: $e');
      debugPrint('StackTrace: $st');
      emit(ProductFailure('Failed to delete product'));
    }
  }
}
