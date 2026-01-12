import 'dart:io';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../utils/audio_manager.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';

import '../../../ting_box.dart';
import '../../../utils/currency_input_formatter.dart';
import '../../Camera/take_picture_page.dart';

class EditProductPage extends StatefulWidget {
  final Product product;
  const EditProductPage({super.key, required this.product});

  @override
  State<EditProductPage> createState() => _EditProductPageState();
}

class _EditProductPageState extends State<EditProductPage> {
  String? selectedCategory;
  List<String> categories = [];
  late TextEditingController nameCtrl;
  late TextEditingController priceCtrl;
  late TextEditingController descCtrl;
  late TextEditingController barcodeCtrl;

  // Scanner
  bool isScanning = false;
  MobileScannerController? scannerController;

  // Images
  List<ProductImage> existingImages = [];
  List<XFile> pickedImages = [];

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    // Initialize controllers with product data
    nameCtrl = TextEditingController(text: widget.product.name);
    // Format initial price with commas
    priceCtrl = TextEditingController(
      text: CurrencyInputFormatter.formatValue(widget.product.price),
    );
    descCtrl = TextEditingController(text: widget.product.description ?? '');
    barcodeCtrl = TextEditingController(text: widget.product.barcode ?? '');

    // Initialize category
    if (widget.product.category != null) {
      selectedCategory = widget.product.category!.name;
    }

    // Initialize images
    existingImages = List.from(widget.product.images ?? []);

    // Load categories
    context.read<ProductBloc>().add(LoadCategoriesEvent());
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    priceCtrl.dispose();
    descCtrl.dispose();
    barcodeCtrl.dispose();
    scannerController?.dispose();
    super.dispose();
  }

  Future<void> pickImagesFromGallery() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile> images = await picker.pickMultiImage(imageQuality: 70);

    if (images.isNotEmpty) {
      setState(() {
        int currentCount = existingImages.length + pickedImages.length;
        int availableSlots = 5 - currentCount;

        if (availableSlots > 0) {
          pickedImages.addAll(images.take(availableSlots));
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Đã đạt tối đa 5 ảnh')));
        }
      });
    }
  }

  Future<void> pickImageFromCamera() async {
    try {
      final XFile? image = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const TakePicturePage()),
      );
      if (image != null && mounted) {
        setState(() {
          int currentCount = existingImages.length + pickedImages.length;
          if (currentCount < 5) {
            pickedImages.add(image);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Đã đạt tối đa 5 ảnh')),
            );
          }
        });
      }
    } catch (e) {
      debugPrint('Error picking image from camera: $e');
    }
  }

  Future<void> handleUpdateProduct() async {
    // Validate
    if (nameCtrl.text.isEmpty || priceCtrl.text.isEmpty) {
      DialogUtils.showAppDialog(
        context: context,
        title: 'Lỗi điền thông tin',
        content: 'Vui lòng điền tên và giá sản phẩm.',
        onFirstAction: () => Navigator.pop(context),
        firstActionText: 'OK',
      );
      return;
    }

    // Parse price from formatted text (remove commas)
    final price =
        CurrencyInputFormatter.parseValue(priceCtrl.text.trim()) ?? 0.0;

    // Check if anything has changed
    final hasNameChanged = nameCtrl.text.trim() != widget.product.name;
    final hasPriceChanged = price != widget.product.price;
    final hasDescriptionChanged =
        descCtrl.text.trim() != (widget.product.description ?? '');
    final hasBarcodeChanged =
        barcodeCtrl.text.trim() != (widget.product.barcode ?? '');
    final hasNewImages = pickedImages.isNotEmpty;

    // If nothing changed, show message and return
    if (!hasNameChanged &&
        !hasPriceChanged &&
        !hasDescriptionChanged &&
        !hasBarcodeChanged &&
        !hasNewImages) {
      DialogUtils.showAppDialog(
        context: context,
        title: 'Không có thay đổi',
        content:
            'Bạn chưa thay đổi thông tin nào. Vui lòng chỉnh sửa trước khi lưu.',
        onFirstAction: () => Navigator.pop(context),
        firstActionText: 'OK',
      );
      return;
    }

    // Prepare new images
    final List<File>? newImagesFiles =
        pickedImages.isNotEmpty
            ? pickedImages.map((e) => File(e.path)).toList()
            : null;

    // Create updated product
    Product updatedProduct = Product(
      id: widget.product.id,
      name: nameCtrl.text.trim(),
      price: price,
      description: descCtrl.text.trim(),
      categoryId: widget.product.categoryId,
      distributorId: widget.product.distributorId,
      barcode: barcodeCtrl.text.trim(),
    );

    // Dispatch update event
    setState(() {
      isLoading = true;
    });

    context.read<ProductBloc>().add(
      UpdateProductEvent(
        productData: updatedProduct,
        newImages: newImagesFiles,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ProductBloc, ProductState>(
      listener: (context, state) {
        if (state is ProductUpdateSuccess) {
          setState(() {
            isLoading = false;
          });
          DialogUtils.showAppDialog(
            context: context,
            title: 'Cập nhật thành công',
            content: 'Đã cập nhật sản phẩm: ${state.product.name}',
            onFirstAction: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context, state.product); // Return updated product
              context.read<ProductBloc>().add(GetProductsEvent());
            },
            firstActionText: 'OK',
          );
          if (!state.product.isEmbedded && pickedImages.isNotEmpty) {
            context.read<ProductBloc>().add(
              UpdateProductEmbeddingEvent(
                productId: state.product.id,
                imageUrls: pickedImages.map((e) => e.path).toList(),
              ),
            );
          }
        }

        if (state is ProductDeleteSuccess) {
          setState(() {
            isLoading = false;
          });
          DialogUtils.showAppDialog(
            context: context,
            title: 'Xóa thành công',
            content: 'Đã xóa sản phẩm thành công',
            onFirstAction: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Pop EditProductPage
              context.read<ProductBloc>().add(GetProductsEvent());
            },
            firstActionText: 'OK',
          );
        }

        if (state is ProductFailure) {
          setState(() {
            isLoading = false;
          });
          DialogUtils.showAppDialog(
            context: context,
            title: 'Lỗi',
            content: state.message,
            onFirstAction: () => Navigator.pop(context),
            firstActionText: 'OK',
          );
        }
      },
      child: Stack(
        children: [
          AppScaffold(
            appBar: _buildAppBar(),
            backgroundColor: Colors.white,
            body: SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  right: 16.w,
                  left: 16.w,
                  top: 12.h,
                  bottom: 64.h,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildBarcodeSection(),
                    if (isScanning) _buildScannerView(),
                    const SizedBox(height: 20),
                    _buildProductNameSection(),
                    const SizedBox(height: 20),
                    _buildPriceSection(),
                    const SizedBox(height: 20),
                    _buildDescriptionSection(),
                    const SizedBox(height: 20),
                    _buildPhotoSection(),
                    const SizedBox(height: 40),
                    _buildSaveButton(),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),
          if (isLoading) LoadingOverlay(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppAppBar(
      title: TitleAppbarText(title: "Sửa sản phẩm"),
      actions: [
        IconButton(
          onPressed: _confirmDelete,
          icon: const Icon(Icons.delete_outline, color: Colors.red),
        ),
      ],
    );
  }

  void _confirmDelete() {
    DialogUtils.showAppDialog(
      context: context,
      title: 'Xác nhận xóa',
      content: 'Bạn có chắc chắn muốn xóa sản phẩm này không?',
      onFirstAction: () {
        Navigator.pop(context); // Close dialog
        setState(() {
          isLoading = true;
        });
        context.read<ProductBloc>().add(
          DeleteProductEvent(productId: widget.product.id),
        );
      },
      firstActionText: 'Xóa',
      onSecondAction: () => Navigator.pop(context),
      secondActionText: 'Hủy',
    );
  }

  Widget _buildBarcodeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTitle("Mã sản phẩm"),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: _buildInput(
                hint: "Nhập hoặc quét mã sản phẩm",
                controller: barcodeCtrl,
                showClearButton: true, // Show clear button only for barcode
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                setState(() {
                  isScanning = !isScanning;
                  if (isScanning) {
                    scannerController = MobileScannerController();
                  } else {
                    scannerController?.dispose();
                    scannerController = null;
                  }
                });
              },
              child: Container(
                margin: const EdgeInsets.only(top: 6),
                height: 48,
                width: 48,
                decoration: _boxDecoration().copyWith(
                  color: isScanning ? Colors.red : AppColors.primaryBlue,
                ),
                child: Icon(
                  isScanning ? Icons.close : Icons.qr_code_scanner,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildScannerView() {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      height: 200.h,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: MobileScanner(
          controller: scannerController!,
          onDetect: (capture) async {
            final Barcode barcode = capture.barcodes.first;
            if (barcode.rawValue != null) {
              debugPrint('Barcode found! ${barcode.rawValue}');
              await AudioManager().playScanSound();
              setState(() {
                barcodeCtrl.text = barcode.rawValue!;
                isScanning = false;
                scannerController?.dispose();
                scannerController = null;
              });
            }
          },
        ),
      ),
    );
  }

  Widget _buildProductNameSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTitle("Tên sản phẩm"),
        _buildInput(hint: "Nhập tên sản phẩm", controller: nameCtrl),
      ],
    );
  }

  Widget _buildPriceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTitle("Giá tiền"),
        _buildInput(
          hint: "0đ",
          keyboard: TextInputType.number,
          controller: priceCtrl,
          isCurrency: true,
        ),
      ],
    );
  }

  Widget _buildDescriptionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTitle("Mô tả"),
        _buildInput(
          hint: "Mô tả ngắn về sản phẩm",
          maxLines: 4,
          controller: descCtrl,
        ),
      ],
    );
  }

  Widget _buildPhotoSection() {
    int totalImages = existingImages.length + pickedImages.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildTitle("Hình ảnh sản phẩm"),
            Text(
              "$totalImages/5",
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          "Chọn tối đa 5 ảnh",
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () {
            if (totalImages >= 5) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã đạt tối đa 5 ảnh')),
              );
              return;
            }
            showModalBottomSheet(
              backgroundColor: Colors.white,
              context: context,
              builder:
                  (context) => SizedBox(
                    height: 120,
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.photo_library),
                          title: const Text("Chọn từ thư viện"),
                          onTap: () {
                            Navigator.pop(context);
                            pickImagesFromGallery();
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.camera_alt),
                          title: const Text("Chụp ảnh"),
                          onTap: () {
                            Navigator.pop(context);
                            pickImageFromCamera();
                          },
                        ),
                      ],
                    ),
                  ),
            );
          },
          child: Container(
            height: 130,
            padding: EdgeInsets.symmetric(horizontal: 8.w),
            decoration: _boxDecoration(),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (totalImages > 0)
                    SizedBox(
                      height: 100,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: totalImages,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          bool isExisting = index < existingImages.length;

                          return Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child:
                                    isExisting
                                        ? Image.network(
                                          existingImages[index].url,
                                          width: 100,
                                          height: 100,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (_, __, ___) => Container(
                                                width: 100,
                                                height: 100,
                                                color: Colors.grey,
                                                child: Icon(Icons.error),
                                              ),
                                        )
                                        : Image.file(
                                          File(
                                            pickedImages[index -
                                                    existingImages.length]
                                                .path,
                                          ),
                                          width: 100,
                                          height: 100,
                                          fit: BoxFit.cover,
                                        ),
                              ),
                              Positioned(
                                top: 2,
                                right: 2,
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      if (isExisting) {
                                        existingImages.removeAt(index);
                                      } else {
                                        pickedImages.removeAt(
                                          index - existingImages.length,
                                        );
                                      }
                                    });
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      size: 20,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    )
                  else ...[
                    const Icon(
                      Icons.add_photo_alternate_outlined,
                      size: 40,
                      color: Colors.blue,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Thêm hình ảnh",
                      style: TextStyle(color: Colors.blue, fontSize: 14),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: handleUpdateProduct,
        child: const Text(
          "Lưu thay đổi",
          style: TextStyle(fontSize: 16, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildTitle(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildInput({
    required String hint,
    TextInputType keyboard = TextInputType.text,
    TextEditingController? controller,
    int maxLines = 1,
    bool isCurrency = false,
    bool showClearButton = false, // Default to false
  }) {
    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: _boxDecoration(),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              maxLines: maxLines,
              keyboardType: keyboard,
              inputFormatters: isCurrency ? [CurrencyInputFormatter()] : null,
              decoration: InputDecoration(
                hintText: hint,
                border: InputBorder.none,
              ),
            ),
          ),
          if (controller != null && showClearButton)
            GestureDetector(
              onTap: () {
                controller.clear();
              },
              child: const Icon(Icons.cancel_outlined, color: Colors.grey),
            ),
        ],
      ),
    );
  }

  BoxDecoration _boxDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: Colors.grey.shade300),
    );
  }
}
