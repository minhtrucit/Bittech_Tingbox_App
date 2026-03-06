import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:ting_box/models/menu.dart';
import 'package:ting_box/services/ocr_service.dart';
import 'package:ting_box/services/product_api_services.dart';
import 'package:ting_box/services/sse_services.dart';
import 'package:ting_box/ting_box.dart';
import 'dart:async';

class ProductBloc extends Bloc<ProductEvent, ProductState> {
  final ProductApiService productApiService;
  final OcrService ocrService;

  ProductBloc({required this.productApiService, required this.ocrService})
    : super(ProductInitial()) {
    on<LoadCategoriesEvent>(_onLoadCategories);
    on<CreateProductEvent>(_onCreateProduct);
    on<GetProductsEvent>(_onGetProducts);
    on<UpdateProductEvent>(_onUpdateProduct);
    on<UpdateProductEmbeddingEvent>(_onUpdateProductEmbedding);
    on<DeleteProductEvent>(_onDeleteProduct);
    on<MenuUploadEvent>(_onMenuOcrDetect);
    on<MenuOcrStatusUpdatedEvent>(_onMenuOcrStatusUpdated);
  }

  StreamSubscription<SseEvent>? _sseSubscription;

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
        "barcode": event.productData.barcode,
      };

      debugPrint('=== CREATE PRODUCT PAYLOAD ===');
      debugPrint(body.toString());
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
        "barcode": event.productData.barcode,
      };

      debugPrint('=== UPDATE PRODUCT PAYLOAD ===');
      debugPrint(body.toString());

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

  Future<void> _onMenuOcrDetect(
    MenuUploadEvent event,
    Emitter<ProductState> emit,
  ) async {
    emit(MenuScanProcessing());
    try {
      final response = await ocrService.detectOCR(event.imagePath);

      debugPrint('status data upload ocr ${response['data']}');

      // Lắng nghe sse, parser dữ liệu xử lý ra
      _sseSubscription?.cancel();
      _sseSubscription = SSEService.instance.eventStream.listen((sseEvent) {
        final data = sseEvent.data;
        if (data is Map<String, dynamic>) {
          final status = (data['status'] as String?)?.toLowerCase();
          debugPrint('[ProductBloc] Received status: $status');

          if (status == 'ready' || status == 'success') {
            debugPrint('[ProductBloc] OCR status: READY. Parsing data...');
            try {
              // Dữ liệu có thể nằm trong field 'result' hoặc 'data' tùy version API
              final menuData = data['result'] ?? data['data'];
              if (menuData != null) {
                final menu = Menu.fromJson(menuData);
                add(MenuOcrStatusUpdatedEvent(menu: menu));
              } else {
                debugPrint(
                  '[ProductBloc] Error: No result or data field found in SSE response',
                );
              }
            } catch (e) {
              debugPrint('[ProductBloc] Error parsing menu data: $e');
            }
          }
        }
      });
    } catch (e, st) {
      debugPrint('=== MENU OCR DETECT ERROR ===');
      debugPrint('Error: $e');
      debugPrint('StackTrace: $st');
      emit(MenuScanFailure('Failed to detect menu OCR'));
    }
  }

  Future<void> _onMenuOcrStatusUpdated(
    MenuOcrStatusUpdatedEvent event,
    Emitter<ProductState> emit,
  ) async {
    _sseSubscription?.cancel();
    _sseSubscription = null;
    emit(ProductMenuScanResultState(menu: event.menu));
  }

  @override
  Future<void> close() {
    _sseSubscription?.cancel();
    return super.close();
  }
}
