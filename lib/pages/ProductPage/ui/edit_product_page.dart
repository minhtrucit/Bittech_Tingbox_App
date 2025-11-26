import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';

import '../../../ting_box.dart';

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

  // Images
  List<ProductImage> existingImages = [];
  List<XFile> pickedImages = [];

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    // Initialize controllers with product data
    nameCtrl = TextEditingController(text: widget.product.name);
    priceCtrl = TextEditingController(text: widget.product.price.toString());
    descCtrl = TextEditingController(text: widget.product.description ?? '');

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
    super.dispose();
  }

  Future<void> pickImagesFromGallery() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile> images = await picker.pickMultiImage(imageQuality: 70);

    if (images.isNotEmpty) {
      setState(() {
        // Limit total images (existing + new) to 5?
        // For now just limit new images added in this batch, or check total count
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
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 70,
    );
    if (image != null) {
      setState(() {
        int currentCount = existingImages.length + pickedImages.length;
        if (currentCount < 5) {
          pickedImages.add(image);
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Đã đạt tối đa 5 ảnh')));
        }
      });
    }
  }

  Future<void> handleUpdateProduct() async {
    // Validate
    if (nameCtrl.text.isEmpty || priceCtrl.text.isEmpty) {
      DialogUtils.showAppDialog(
        context: context,
        title: 'Lỗi điền thông tin',
        content: 'Vui lòng điền tên và giá sản phẩm.',
        onFirstAction: () => Navigator.pop(context),
        firstActionText: 'OK',
      );
      return;
    }

    if (existingImages.isEmpty && pickedImages.isEmpty) {
      DialogUtils.showAppDialog(
        context: context,
        title: 'Thiếu hình ảnh',
        content: 'Vui lòng chọn ít nhất 1 hình ảnh.',
        onFirstAction: () => Navigator.pop(context),
        firstActionText: 'OK',
      );
      return;
    }

    // TODO: Implement update logic
    // Since we don't have UpdateProductEvent yet, we show a message
    DialogUtils.showAppDialog(
      context: context,
      title: 'Thông báo',
      content: 'Chức năng cập nhật sản phẩm đang được phát triển.',
      onFirstAction: () => Navigator.pop(context),
      firstActionText: 'OK',
    );

    /* 
    // Example logic if event existed:
    final List<File> newImagesFiles = pickedImages.map((e) => File(e.path)).toList();
    
    Product updatedProduct = Product(
      id: widget.product.id,
      name: nameCtrl.text.trim(),
      price: double.tryParse(priceCtrl.text.trim()) ?? 0.0,
      description: descCtrl.text.trim(),
      categoryId: widget.product.categoryId, // Need to update based on selectedCategory
      // ... other fields
    );

    context.read<ProductBloc>().add(
      UpdateProductEvent(productData: updatedProduct, newImages: newImagesFiles, deletedImageIds: ...),
    );
    */
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ProductBloc, ProductState>(
      listener: (context, state) {
        // Handle states if we were actually updating
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
    return AppAppBar(title: TitleAppbarText(title: "Sửa sản phẩm"));
  }

  // Reuse sections from CreateProductPage but adapted

  Widget _buildProductNameSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTitle("Tên sản phẩm"),
        _buildInput(hint: "Nhập tên sản phẩm", controller: nameCtrl),
      ],
    );
  }

  Widget _buildPriceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTitle("Giá tiền"),
        _buildInput(
          hint: "0.00đ",
          keyboard: TextInputType.number,
          controller: priceCtrl,
        ),
      ],
    );
  }

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

  Widget _buildPhotoSection() {
    int totalImages = existingImages.length + pickedImages.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildTitle("Hình ảnh sản phẩm"),
            Text(
              "$totalImages/5",
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
                          // Determine if it's an existing image or a new one
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
                              // Icon X để xoá ảnh
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
                      "Thêm hình ảnh",
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
  }) {
    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: _boxDecoration(),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboard,
        decoration: InputDecoration(hintText: hint, border: InputBorder.none),
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
