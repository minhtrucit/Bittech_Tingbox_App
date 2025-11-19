import 'dart:async';

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../services/product_api_services.dart';
import '../../ting_box.dart';

class Product {
  final String name;
  final double price;
  // final String imageUrl;
  final int quantity;

  Product({
    required this.name,
    required this.price,
    this.quantity = 1,
    // required this.imageUrl,
  });
}

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
  @override
  void initState() {
    super.initState();
    _initCamera();
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

  final apiService = ProductApiService(baseUrl: 'http://192.168.100.49:5000');
  List<Product> scannedProducts = [];
  Future<void> _takePictureAndSend() async {
    final XFile file = await _camera!.takePicture();
    print('Ảnh path: ${file.path}');

    final product = await apiService.sendImage(file.path);
    if (product != null) {
      print('Product match: ${product['name']} - ${product['price']}đ');

      setState(() {
        final name = product['name'];

        final index = scannedProducts.indexWhere((p) => p.name == name);

        if (index != -1) {
          final existing = scannedProducts[index];

          scannedProducts.removeAt(index);

          scannedProducts.insert(
            0,
            Product(
              name: existing.name,
              price: existing.price,
              quantity: existing.quantity + 1,
            ),
          );
        } else {
          scannedProducts.insert(
            0,
            Product(
              name: product['name'],
              price: product['price'].toDouble(),
              quantity: 1,
            ),
          );
        }
      });
    }
  }

  double _calculateTotalPrice() {
    return scannedProducts.fold(0.0, (sum, product) => sum + product.price);
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
        backgroundColor: AppColors.white,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primaryBlue),
        ),
      );
    }

    return AppScaffold(
      hasSafeArea: false,
      appBar: AppAppBar(
        backgroundColor: Colors.transparent,
        leading: buildBackButton(context),
        actions: [
          if (_lenDirection == CameraLensDirection.back) buildFlashButton(),
          SizedBox(width: 8.w),
          buildChangeLenButton(),
        ],
      ),
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
                      name: product.name,
                      imageUrl: '',
                      price: product.price,
                      quantity: product.quantity,
                      onIncrease: () {},
                      onDecrease: () {},
                      onDelete: () {
                        setState(() {
                          scannedProducts.remove(product);
                        });
                      },
                    );
                  }).toList(),
              onButtonTap: () {},
              totalPrice: _calculateTotalPrice,
            ),
          ),

          _buildTakePhotoButton(onTap: _takePictureAndSend),
        ],
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
          Navigator.pop(context);
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
}

Widget _buildTakePhotoButton({required VoidCallback? onTap}) {
  return Positioned(
    bottom: 360.h,
    left: 0,
    right: 0,
    child: Center(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 65,
          height: 65,
          decoration: BoxDecoration(
            color: Colors.red,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 4),
          ),
        ),
      ),
    ),
  );
}

Widget _buildProductBottomSheet({
  required BuildContext context,
  required List<Widget> productItems,
  required VoidCallback onButtonTap,
  required double Function() totalPrice,
}) {
  return Container(
    height: 350.h,
    decoration: const BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        const SizedBox(height: 10),
        Container(
          width: 45,
          height: 5,
          decoration: BoxDecoration(
            color: Colors.grey[400],
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
        const SizedBox(height: 10),
        ListTile(
          title: Text(
            "Sản phẩm đã quét (${productItems.length})",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: productItems.length,
            itemBuilder: (context, index) => productItems[index],
          ),
        ),
        Padding(
          padding: EdgeInsets.only(right: 8.w),
          child: Align(
            alignment: Alignment.bottomRight,
            child: Text(
              'Tổng tiền: ${formatMoney(totalPrice())}đ',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
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
              onPressed: onButtonTap,
              label: Text(
                "Xác nhận",
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

Widget buildProductCartItem({
  required String name,
  required String imageUrl,
  required double price,
  required int quantity,
  required VoidCallback onIncrease,
  required VoidCallback onDecrease,
  required VoidCallback onDelete,
}) {
  return Padding(
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
            child: Image.network(
              'https://picsum.photos/200/300',
              width: 50,
              height: 50,
              fit: BoxFit.cover,
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
                  style: const TextStyle(fontSize: 13, color: Colors.black54),
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
  );
}
