import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../common/app_colors.dart';
import '../../common/components/app_text_button.dart';
import '../../services/product_api_services.dart';

class Product{
  final String name;
  final double price;
  // final String imageUrl;

  Product({
    required this.name,
    required this.price,
    // required this.imageUrl,
  });
}


class ScanProductPage extends StatefulWidget {
  const ScanProductPage({super.key});

  @override
  State<ScanProductPage> createState() => _ScanProductPageState();
}

class _ScanProductPageState extends State<ScanProductPage> {
  CameraController? _controller;
  bool _isCameraReady = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();

      _controller = CameraController(
        cameras.first,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _controller!.initialize();
      setState(() => _isCameraReady = true);
    } catch (e) {
      debugPrint("Camera error: $e");
    }
  }

  final apiService = ProductApiService(baseUrl: 'http://192.168.100.49:5000');
  List<Product> scannedProducts = [];
  Future<void> _takePictureAndSend() async {
    final XFile file = await _controller!.takePicture();
    print('Ảnh path: ${file.path}');

    final product = await apiService.sendImage(file.path);
    if (product != null) {
      print('Product match: ${product['name']} - ${product['price']}đ');
      setState(() {
        scannedProducts.add(Product(
          name: product['name'],
          price: product['price'].toDouble(),
          // imageUrl: product['image_path'],
        ));
      });
    }
  }

  @override
  void dispose() {
    debugPrint('Disposing camera controller');
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCameraReady) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: Stack(
        children: [
          SizedBox.expand(child: CameraPreview(_controller!)),

          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildProductBottomSheet(
              context: context,
              productItems: scannedProducts.map((product) {
                return buildProductCartItem(
                  name: product.name,
                  imageUrl: '',
                  price: product.price,
                  quantity: 1,
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
            ),
          ),

          _buildTakePhotoButton(onTap: _takePictureAndSend),
        ],
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
          width: 72,
          height: 72,
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
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        const SizedBox(height: 12),
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
              'Tổng tiền: 12,0000đ',
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
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                  "${price.toStringAsFixed(0)}đ",
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
          const SizedBox(width: 6),

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

          // Delete
          IconButton(
            iconSize: 22,
            padding: EdgeInsets.zero,
            onPressed: onDelete,
            icon: const Icon(Icons.delete, color: Colors.red),
          ),
        ],
      ),
    ),
  );
}
