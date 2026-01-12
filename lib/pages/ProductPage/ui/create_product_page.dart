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

class CreateProductPage extends StatefulWidget {
  const CreateProductPage({super.key});

  @override
  State<CreateProductPage> createState() => _CreateProductPageState();
}

class _CreateProductPageState extends State<CreateProductPage> {
  String? selectedCategory;
  List<String> categories = [];
  final barcodeCtrl = TextEditingController();
  final nameCtrl = TextEditingController();
  final priceCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  List<XFile> pickedImages = [];
  bool isLoading = false;
  bool isScanning = false;
  MobileScannerController? scannerController;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    barcodeCtrl.dispose();
    nameCtrl.dispose();
    priceCtrl.dispose();
    descCtrl.dispose();
    scannerController?.dispose();
    super.dispose();
  }

  Future<void> pickImagesFromGallery() async {
    final ImagePicker picker = ImagePicker();

    final List<XFile> images = await picker.pickMultiImage(imageQuality: 70);

    if (images.isNotEmpty) {
      setState(() {
        pickedImages = images.take(5).toList();
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
          if (pickedImages.length < 5) {
            pickedImages.add(image);
          }
        });
      }
    } catch (e) {
      debugPrint('Error picking image from camera: $e');
    }
  }

  Future<void> handleCreateProduct() async {
    // Validate đơn giản
    if (nameCtrl.text.isEmpty ||
        priceCtrl.text.isEmpty ||
        pickedImages.isEmpty) {
      DialogUtils.showAppDialog(
        context: context,
        title: 'Lỗi điền thông tin',
        content:
            'Vui lòng điền đầy đủ thông tin sản phẩm và chọn ít nhất 1 hình ảnh.',
        onFirstAction: () {
          Navigator.pop(context);
        },
        firstActionText: 'OK',
      );
      return;
    }
    // Chuẩn bị list File cho upload
    final List<File> images = pickedImages.map((e) => File(e.path)).toList();

    // Tạo payload
    // Parse price from formatted text (remove commas)
    final price =
        CurrencyInputFormatter.parseValue(priceCtrl.text.trim()) ?? 0.0;

    Product productData = Product(
      id: 1,
      name: nameCtrl.text.trim(),
      price: price,
      description: descCtrl.text.trim(),
      categoryId: 2,
      url: images[0].path,
      barcode: barcodeCtrl.text.trim(),
    );

    // Gọi bloc
    setState(() {
      isLoading = true;
    });
    context.read<ProductBloc>().add(
      CreateProductEvent(productData: productData, images: images),
    );
  }

  void clearForm() {
    setState(() {
      barcodeCtrl.clear();
      nameCtrl.clear();
      descCtrl.clear();
      priceCtrl.clear();
      pickedImages.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ProductBloc, ProductState>(
      listener: (context, state) {
        debugPrint('Create product $state');

        if (state is ProductCreateSuccess) {
          setState(() {
            isLoading = false;
          });
          DialogUtils.showAppDialog(
            context: context,
            title: 'Tạo sản phẩm thành công',
            content:
                'Đã tạo mới thành công sản phẩm: ${state.product.name}',
            onFirstAction: () {
              Navigator.pop(context, true);

              clearForm();
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
            title: 'Lỗi',
            content: state.message,
            onFirstAction: () {
              Navigator.pop(context);
            },
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
                    // _buildCategorySection(context),
                    // const SizedBox(height: 20),
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

  // ---------------------------------------------------------------------------
  // ✔ AppBar
  // ---------------------------------------------------------------------------
  PreferredSizeWidget _buildAppBar() {
    return AppAppBar(title: TitleAppbarText(title: "Thêm mới sản phẩm"));
  }

  // ---------------------------------------------------------------------------
  // ✔ Section: Category
  // ---------------------------------------------------------------------------
  Widget _buildCategorySection(BuildContext parentContext) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTitle("Danh mục sản phẩm"),
        const SizedBox(height: 6),
        _buildCategoryDropdown(),
        const SizedBox(height: 8),

        AppTextButton(
          onPressed: () {
            showModalBottomSheet(
              context: parentContext,
              builder: (context) {
                return buildCreateCategoryBottomSheet(context);
              },
            );
          },
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(vertical: 10.h),
            backgroundColor: const Color(0xFFDCE9F6),
            foregroundColor: Colors.blue.shade300,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: AppColors.primaryBlue),
            ),
          ),
          label: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 2.w,
            children: [
              Icon(Icons.add, color: AppColors.primaryBlue),
              Text(
                "Thêm danh mục mới",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryBlue,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryDropdown() {
    return BlocBuilder<ProductBloc, ProductState>(
      builder: (context, state) {
        if (state is ProductLoadCategoriesSuccess) {
          categories = state.categories;
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: _boxDecoration(),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              dropdownColor: Colors.white,
              hint: const Text("Chọn 1 danh mục"),
              value: selectedCategory,
              items:
                  categories
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
              onChanged: (value) {
                setState(() => selectedCategory = value);
              },
            ),
          ),
        );
      },
    );
  }

  Widget buildCreateCategoryBottomSheet(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: SizedBox(
          height: 250.h,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              children: [
                SizedBox(height: 10.h),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Thêm danh mục mới",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20.sp,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, size: 20, color: Colors.grey),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16.h),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTitle("Tên danh mục"),
                    _buildInput(hint: "Nhập tên danh mục"),
                  ],
                ),
                Spacer(),
                Row(
                  children: [
                    Expanded(
                      child: AppTextButton(
                        style: ButtonStyle(
                          padding: WidgetStatePropertyAll(
                            EdgeInsets.symmetric(vertical: 10.h),
                          ),
                          shape: WidgetStatePropertyAll(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                width: 1.w,
                                color: Colors.grey.shade300,
                              ),
                            ),
                          ),
                          backgroundColor: WidgetStatePropertyAll(
                            AppColors.white,
                          ),
                          textStyle: WidgetStatePropertyAll(
                            Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        onPressed: () => Navigator.pop(context),
                        label: Text(
                          "Hủy",
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(fontWeight: FontWeight.w500),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: AppTextButton(
                        style: ButtonStyle(
                          padding: WidgetStatePropertyAll(
                            EdgeInsets.symmetric(vertical: 10.h),
                          ),
                          shape: WidgetStatePropertyAll(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          backgroundColor: WidgetStatePropertyAll(
                            AppColors.primaryBlue,
                          ),
                          textStyle: WidgetStatePropertyAll(
                            Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        onPressed: () {},
                        label: Text(
                          "Lưu",
                          style: Theme.of(
                            context,
                          ).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // ✔ Section: Barcode
  // ---------------------------------------------------------------------------
  Widget _buildBarcodeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTitle("Mã sản phẩm"),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: _buildInput(
                hint: "Nhập hoặc quét mã sản phẩm",
                controller: barcodeCtrl,
                showClearButton: true,
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

  // ---------------------------------------------------------------------------
  // ✔ Section: Product Name
  // ---------------------------------------------------------------------------
  Widget _buildProductNameSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTitle("Tên sản phẩm"),
        _buildInput(hint: "Nhập tên sản phẩm", controller: nameCtrl),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // ✔ Section: Price
  // ---------------------------------------------------------------------------
  Widget _buildPriceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTitle("Giá tiền"),
        _buildInput(
          hint: "0đ",

          keyboard: TextInputType.number,
          controller: priceCtrl,
          isCurrency: true,
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // ✔ Section: Description
  // ---------------------------------------------------------------------------
  Widget _buildDescriptionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTitle("Mô tả"),
        _buildInput(
          hint: "Mô tả ngắn về sản phẩm",
          maxLines: 4,
          controller: descCtrl,
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // ✔ Section: Photos — Add Up To 5
  // ---------------------------------------------------------------------------
  Widget _buildPhotoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildTitle("Hình ảnh sản phẩm"),
            Text(
              "${pickedImages.length}/5",
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          "Chọn tối đa 5 ảnh",
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () {
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
                  if (pickedImages.isNotEmpty)
                    SizedBox(
                      height: 100,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: pickedImages.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          return Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  File(pickedImages[index].path),
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              // Icon X để xoá ảnh
                              Positioned(
                                top: 2,
                                right: 2,
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      pickedImages.removeAt(index);
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
                      "Thêm hình ảnh",
                      style: TextStyle(color: Colors.blue, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "Chọn hình ảnh cho sản phẩm của bạn",
                      style: TextStyle(color: Colors.grey, fontSize: 12),
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

  // ---------------------------------------------------------------------------
  // ✔ Section: Save Button
  // ---------------------------------------------------------------------------
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
        onPressed: handleCreateProduct,
        child: const Text(
          "Lưu sản phẩm",
          style: TextStyle(fontSize: 16, color: Colors.white),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // ✔ Shared UI Components
  // ---------------------------------------------------------------------------
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
