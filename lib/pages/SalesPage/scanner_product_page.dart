import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../services/api_services.dart';
import '../../services/order_service.dart';
import '../../services/product_api_services.dart';
import '../../ting_box.dart';

class ScanProductPage extends StatefulWidget {
  const ScanProductPage({super.key});

  @override
  State<ScanProductPage> createState() => _ScanProductPageState();
}

class _ScanProductPageState extends State<ScanProductPage> {
  CameraController? _camera;
  bool _isCameraReady = false;

  CameraLensDirection _lenDirection = CameraLensDirection.back;
  bool _isFlashOn = false;
  bool isLoadingProducts = false;

  final ValueNotifier<bool> _isLoading = ValueNotifier(false);
  List<Product> products = [];
  late OrderService orderService;
  int _currentTab = 0; // 0: Scanned, 1: All Products
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    _initCamera();
    Future.delayed(Duration(milliseconds: 300), () {
      if (mounted) {
        context.read<ProductBloc>().add(GetProductsEvent());
      }
    });
    super.initState();
  }

  Future<void> _initCamera() async {
    final description = await CameraUtils.getCamera(_lenDirection);
    _camera = CameraController(
      description,
      ResolutionPreset.high,
      enableAudio: false,
    );

    await _camera!.initialize().catchError((Object e) {
      if (e is CameraException) {
        debugPrint('Camera exception: ${e.description}');
      }
    });
    await CameraUtils.lockCaptureOrientation(_camera!);
    unawaited(_camera?.setFlashMode(FlashMode.off));
    setState(() => _isCameraReady = true);
  }

  void _toggleFlash() {
    if (_isFlashOn) {
      _camera?.setFlashMode(FlashMode.off);
    } else {
      _camera?.setFlashMode(FlashMode.torch);
    }
    setState(() {
      _isFlashOn = !_isFlashOn;
    });
  }

  void _changeLenDirection() {
    if (_lenDirection == CameraLensDirection.back) {
      _lenDirection = CameraLensDirection.front;
      _camera?.setFlashMode(FlashMode.off);
      setState(() {
        _isFlashOn = false;
      });
    } else {
      _lenDirection = CameraLensDirection.back;
    }
    _initCamera();
  }

  final apiService = ProductApiService(
    baseUrl: dotenv.get('API_DETECT_URL'),
    api: ApiService.getInstance(baseUrl: dotenv.get('API_BASE_URL')),
  );

  List<Product> scannedProducts = [];
  Future<void> _takePictureAndSend() async {
    _isLoading.value = true;
    debugPrint('isLoading $_isLoading');
    try {
      final XFile file = await _camera!.takePicture();
      debugPrint('Ảnh path: ${file.path}');
      final product = await apiService.sendImage(file.path);
      debugPrint('API response: $product');

      if (product != null) {
        debugPrint('Product match: ${product['name']} - ${product['price']}đ');
        setState(() {
          final name = product['name'];

          final index = scannedProducts.indexWhere((p) => p.name == name);

          if (index != -1) {
            final existing = scannedProducts[index];

            scannedProducts.removeAt(index);

            scannedProducts.insert(
              0,
              Product(
                id: existing.id,
                name: existing.name,
                price: existing.price,
                quantity: existing.quantity + 1,
                url: existing.url,
                isEmbedded: existing.isEmbedded,
                embeddingUrl: file.path,
                images: existing.images,
              ),
            );
          } else {
            scannedProducts.insert(
              0,
              Product(
                id: product['id'],
                name: product['name'],
                price: product['price'].toDouble(),
                quantity: 1,
                url: product['url'],
                isEmbedded: product['is_embedded'],
                embeddingUrl: file.path,
              ),
            );
          }
        });
      }
    } catch (e) {
      debugPrint('Error taking picture or sending to API: $e');
      if (mounted) {
        DialogUtils.showAppDialog(
          context: context,
          title: 'Lỗi',
          content:
              'Không thể kết nối đến server hoặc quá thời gian chờ. Vui lòng thử lại.',
          onFirstAction: () => Navigator.pop(context),
          firstActionText: 'Đóng',
        );
      }
    } finally {
      _isLoading.value = false;
    }
  }

  double _calculateTotalPrice() {
    return scannedProducts.fold(
      0.0,
      (sum, product) => sum + product.price * product.quantity,
    );
  }

  Widget _buildDialogConfirmWidget() {
    return AlertDialog(
      backgroundColor: AppColors.white,
      title: const Text("Xác nhận thoát"),
      content: const Text(
        "Bạn có sản phẩm trong danh sách.\nBạn có chắc chắn muốn thoát không?",
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(
            "Hủy",
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.primaryBlue),
          ),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            Navigator.pop(context);
          },
          child: Text(
            "Thoát",
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.red),
          ),
        ),
      ],
    );
  }

  void handleUpdateQuantity({required int index, required bool isIncrease}) {
    setState(() {
      final product = scannedProducts[index];
      scannedProducts[index] = Product(
        id: product.id,
        name: product.name,
        price: product.price,
        quantity:
            isIncrease
                ? product.quantity + 1
                : (product.quantity > 1 ? product.quantity - 1 : 1),
        url: product.url,
      );
    });
  }

  void replaceProductAtIndex(int oldIndex, Product newProduct) async {
    final oldProduct = scannedProducts[oldIndex];

    if (oldProduct.id == newProduct.id) return;

    final existingIndex = scannedProducts.indexWhere(
      (p) => p.id == newProduct.id,
    );

    if (existingIndex != -1) {
      setState(() {
        scannedProducts[existingIndex].quantity += oldProduct.quantity;
        scannedProducts.removeAt(oldIndex);
      });

      return;
    }

    setState(() {
      scannedProducts[oldIndex] = Product(
        id: newProduct.id,
        name: newProduct.name,
        price: newProduct.price,
        quantity: oldProduct.quantity,
        url: newProduct.url,
        images: newProduct.images,
      );
    });
  }

  // show re select product bottom sheet
  void showProductBottomSheet(BuildContext context, int oldIndex) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return ProductBottomSheet(
          products: products,
          onSelected: (newProduct) {
            replaceProductAtIndex(oldIndex, newProduct);
          },
        );
      },
    );
  }

  // show confirm order dialog
  void showConfirmOrderDialog() {
    if (scannedProducts.isEmpty) return;
    showDialog(
      context: context,
      builder:
          (_) => ConfirmOrderDialog(
            items: List.from(scannedProducts),
            parentContext: context,
          ),
    );
  }

  @override
  void dispose() {
    debugPrint('Disposing camera controller');
    _camera?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCameraReady) {
      return const AppScaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: AppColors.white,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primaryBlue),
        ),
      );
    }
    debugPrint(
      'Building ScanProductPage with ${scannedProducts.length} products',
    );
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, e) async {
        if (didPop) return;

        if (scannedProducts.isNotEmpty) {
          final shouldExit = await showDialog<bool>(
            context: context,
            builder: (context) {
              return _buildDialogConfirmWidget();
            },
          );

          if (shouldExit == true && context.mounted) {
            Navigator.pop(context);
          }
        } else {
          Navigator.pop(context);
        }
      },
      child: MultiBlocListener(
        listeners: [
          BlocListener<OrderBloc, OrderState>(
            listener: (context, state) {
              if (state is OrderCreateSuccess) {
                setState(() {
                  scannedProducts.clear();
                });
              }
            },
          ),
          BlocListener<ProductBloc, ProductState>(
            listener: (context, state) {
              debugPrint('Product state: $state');
              if (state is ProductLoading) {
                setState(() {
                  isLoadingProducts = true;
                });
              }
              if (state is ProductLoadProductsSuccess) {
                debugPrint(
                  'ProductLoadProductsSuccess: ${state.products.length} products',
                );
                setState(() {
                  isLoadingProducts = false;
                  products.addAll(state.products);
                });
              }
            },
          ),
        ],
        child: AppScaffold(
          hasSafeArea: false,
          resizeToAvoidBottomInset: false,
          backgroundColor: Colors.black,
          appBar:
              _currentTab == 0
                  ? AppAppBar(
                    backgroundColor: Colors.transparent,
                    leading: buildBackButton(context),
                    actions: [
                      if (_lenDirection == CameraLensDirection.back)
                        buildFlashButton(),
                      SizedBox(width: 8.w),
                      buildChangeLenButton(),
                    ],
                  )
                  : null,
          body: Stack(
            children: [
              SizedBox.expand(child: CameraPreview(_camera!)),

              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _buildProductBottomSheet(
                  context: context,
                  productItems:
                      scannedProducts.map((product) {
                        return buildProductCartItem(
                          onTap: () {
                            showProductBottomSheet(
                              context,
                              scannedProducts.indexOf(product),
                            );
                          },
                          name: product.name,
                          imageUrl:
                              product.url ??
                              (product.images != null &&
                                      product.images!.isNotEmpty
                                  ? product.images!.first.url
                                  : ''),
                          price: product.price,
                          quantity: product.quantity,
                          onIncrease: () {
                            handleUpdateQuantity(
                              index: scannedProducts.indexOf(product),
                              isIncrease: true,
                            );
                          },
                          onDecrease: () {
                            handleUpdateQuantity(
                              index: scannedProducts.indexOf(product),
                              isIncrease: false,
                            );
                          },
                          onDelete: () {
                            setState(() {
                              scannedProducts.remove(product);
                            });
                          },
                        );
                      }).toList(),
                  onConfirmButtonTap: showConfirmOrderDialog,
                  totalPrice: _calculateTotalPrice,
                ),
              ),
              if (_currentTab == 0)
                _buildTakePhotoButton(
                  onTap: _takePictureAndSend,
                  isLoading: _isLoading,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Padding buildChangeLenButton() {
    return Padding(
      padding: EdgeInsets.only(right: 16.w),
      child: GestureDetector(
        onTap: _changeLenDirection,
        child: SizedBox(
          width: 42.w,
          height: 42.w,
          child: DecoratedBox(
            decoration: const BoxDecoration(
              color: AppColors.white10,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.change_circle_outlined, color: Colors.white),
          ),
        ),
      ),
    );
  }

  GestureDetector buildFlashButton() {
    return GestureDetector(
      onTap: _toggleFlash,
      child: Container(
        width: 40.w,
        height: 40.w,
        decoration: const BoxDecoration(
          color: AppColors.white10,
          shape: BoxShape.circle,
        ),
        padding: const EdgeInsets.all(8),
        child:
            _isFlashOn
                ? Icon(Icons.flash_on_outlined, color: Colors.white)
                : Icon(Icons.flash_off_outlined, color: Colors.white),
      ),
    );
  }

  Padding buildBackButton(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 18.w),
      child: GestureDetector(
        onTap: () {
          if (scannedProducts.isNotEmpty) {
            showDialog<bool>(
              context: context,
              builder: (context) {
                return _buildDialogConfirmWidget();
              },
            );
          } else {
            Navigator.pop(context);
          }
        },
        child: DecoratedBox(
          decoration: const BoxDecoration(
            color: AppColors.white10,
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.arrow_back_ios_new, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildTakePhotoButton({
    required VoidCallback? onTap,
    ValueNotifier<bool>? isLoading,
  }) {
    return Positioned(
      bottom: 360.h,
      left: 0,
      right: 0,
      child: Center(
        child: GestureDetector(
          onTap: onTap,
          child: ValueListenableBuilder<bool>(
            valueListenable: isLoading ?? ValueNotifier(false),
            builder: (context, isLoadingState, child) {
              return Container(
                width: 65,
                height: 65,
                decoration: BoxDecoration(
                  color: isLoadingState ? Colors.transparent : Colors.red,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                ),
                child:
                    isLoadingState
                        ? const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primaryBlue,
                          ),
                        )
                        : null,
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildProductBottomSheet({
    required BuildContext context,
    required List<Widget> productItems,
    required VoidCallback onConfirmButtonTap,
    required double Function() totalPrice,
  }) {
    final screenHeight = MediaQuery.of(context).size.height;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: _currentTab == 0 ? 350.h : screenHeight,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          if (_currentTab == 0)
            Container(
              width: 45,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
          SizedBox(height: _currentTab == 0 ? 10 : 50.h),
          // Tab Selector
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12.r),
              ),
              padding: EdgeInsets.all(4.w),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _currentTab = 0),
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 8.h),
                        decoration: BoxDecoration(
                          color:
                              _currentTab == 0
                                  ? Colors.white
                                  : Colors.transparent,
                          borderRadius: BorderRadius.circular(8.r),
                          boxShadow:
                              _currentTab == 0
                                  ? [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.05,
                                      ),
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ]
                                  : null,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          "Đã quét (${scannedProducts.length})",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color:
                                _currentTab == 0
                                    ? Colors.black
                                    : Colors.grey[600],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _currentTab = 1),
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 8.h),
                        decoration: BoxDecoration(
                          color:
                              _currentTab == 1
                                  ? Colors.white
                                  : Colors.transparent,
                          borderRadius: BorderRadius.circular(8.r),
                          boxShadow:
                              _currentTab == 1
                                  ? [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.05,
                                      ),
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ]
                                  : null,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          "Tất cả sản phẩm",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color:
                                _currentTab == 1
                                    ? Colors.black
                                    : Colors.grey[600],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Content
          Expanded(
            child:
                _currentTab == 0
                    ? _buildScannedList(
                      productItems,
                      onConfirmButtonTap,
                      totalPrice,
                    )
                    : _buildAllProductsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildScannedList(
    List<Widget> productItems,
    VoidCallback onConfirmButtonTap,
    double Function() totalPrice,
  ) {
    return Column(
      children: [
        Expanded(
          child:
              productItems.isEmpty
                  ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.shopping_cart_outlined,
                          size: 48,
                          color: Colors.grey[300],
                        ),
                        SizedBox(height: 16),
                        Text(
                          "Chưa có sản phẩm nào",
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  )
                  : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: productItems.length,
                    itemBuilder: (context, index) => productItems[index],
                  ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(width: 0.4.w, color: Colors.grey.shade300),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.only(right: 16.w, left: 16.w, top: 16.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tổng cộng: ',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  '${formatMoney(totalPrice())}đ',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            width: double.infinity,
            child: AppTextButton(
              style: ButtonStyle(
                shape: WidgetStatePropertyAll(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                backgroundColor: WidgetStatePropertyAll(AppColors.primaryBlue),
                textStyle: WidgetStatePropertyAll(
                  Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              onPressed: onConfirmButtonTap,
              label: Text(
                "Hoàn tất",
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAllProductsList() {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Tìm kiếm sản phẩm...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.grey[100],
              contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 12),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
        ),
        SizedBox(height: 8.h),
        Expanded(
          child: BlocBuilder<ProductBloc, ProductState>(
            builder: (context, state) {
              if (state is ProductLoading) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primaryBlue,
                  ),
                );
              }

              if (state is ProductFailure) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Lỗi tải sản phẩm",
                        style: TextStyle(color: Colors.red),
                      ),
                      TextButton(
                        onPressed:
                            () => context.read<ProductBloc>().add(
                              GetProductsEvent(),
                            ),
                        child: Text("Thử lại"),
                      ),
                    ],
                  ),
                );
              }

              List<Product> currentProducts = [];
              if (state is ProductLoadProductsSuccess) {
                currentProducts = state.products;
              } else {
                currentProducts = products;
              }

              final filteredProducts =
                  currentProducts
                      .where(
                        (p) => p.name.toLowerCase().contains(
                          _searchQuery.toLowerCase(),
                        ),
                      )
                      .toList();

              if (filteredProducts.isEmpty) {
                return Center(
                  child: Text(
                    "Không tìm thấy sản phẩm",
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                );
              }

              return ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                itemCount: filteredProducts.length,
                itemBuilder: (context, index) {
                  final product = filteredProducts[index];
                  return _buildProductListItem(product);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProductListItem(Product product) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(8.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8.r),
            child: Image.network(
              product.url ??
                  (product.images?.isNotEmpty == true
                      ? product.images!.first.url
                      : ''),
              width: 50.w,
              height: 50.w,
              fit: BoxFit.cover,
              errorBuilder:
                  (_, __, ___) => Container(
                    width: 50.w,
                    height: 50.w,
                    color: Colors.grey[200],
                    child: Icon(Icons.image, color: Colors.grey),
                  ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14.sp,
                  ),
                ),
                Text(
                  '${formatMoney(product.price)}đ',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13.sp),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              _addProductToScannedList(product);
            },
            icon: Icon(Icons.add_circle, color: AppColors.primaryBlue),
          ),
        ],
      ),
    );
  }

  void _addProductToScannedList(Product product) {
    setState(() {
      final index = scannedProducts.indexWhere((p) => p.id == product.id);
      if (index != -1) {
        final existing = scannedProducts[index];
        scannedProducts[index] = Product(
          id: existing.id,
          name: existing.name,
          price: existing.price,
          quantity: existing.quantity + 1,
          url: existing.url,
          images: existing.images,
        );
      } else {
        scannedProducts.insert(
          0,
          Product(
            id: product.id,
            name: product.name,
            price: product.price,
            quantity: 1,
            url: product.url,
            images: product.images,
          ),
        );
      }
      // Optional: Switch back to scanned list or show toast
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã thêm ${product.name}'),
          duration: Duration(seconds: 1),
        ),
      );
    });
  }

  Widget buildProductCartItem({
    required String name,
    required String imageUrl,
    required double price,
    required int quantity,
    required VoidCallback onIncrease,
    required VoidCallback onDecrease,
    required VoidCallback onDelete,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Image
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child:
                    imageUrl.isNotEmpty
                        ? Image.network(
                          imageUrl,
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 50,
                              height: 50,
                              color: Colors.grey[300],
                              child: Icon(
                                Icons.image_not_supported,
                                color: Colors.grey[600],
                              ),
                            );
                          },
                        )
                        : Container(
                          width: 50,
                          height: 50,
                          color: Colors.grey[300],
                          child: Icon(Icons.image, color: Colors.grey[600]),
                        ),
              ),
              const SizedBox(width: 12),

              // Name & Price
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${formatMoney(price)}đ",
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),

              // Decrease
              IconButton(
                iconSize: 22,
                padding: EdgeInsets.zero,
                onPressed: onDecrease,
                icon: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(6),
                  child: const Icon(Icons.remove, size: 16),
                ),
              ),

              // Quantity text
              Text(quantity.toString(), style: const TextStyle(fontSize: 16)),

              // Increase
              IconButton(
                iconSize: 22,
                padding: EdgeInsets.zero,
                onPressed: onIncrease,
                icon: Container(
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(6),
                  child: const Icon(Icons.add, size: 16, color: Colors.white),
                ),
              ),

              SizedBox(width: 8.w),
              // Delete
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  iconSize: 22,
                  padding: EdgeInsets.zero,
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete, color: Colors.red),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
