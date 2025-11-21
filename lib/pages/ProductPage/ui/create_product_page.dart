import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';

import '../../../ting_box.dart';

class CreateProductPage extends StatefulWidget {
  const CreateProductPage({super.key});

  @override
  State<CreateProductPage> createState() => _CreateProductPageState();
}

class _CreateProductPageState extends State<CreateProductPage> {
  String? selectedCategory;
  List<String> categories = [];
  final nameCtrl = TextEditingController();
  final priceCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  List<XFile> pickedImages = [];

  @override
  void initState() {
    super.initState();
  }

  Future<void> pickImages() async {
    final ImagePicker picker = ImagePicker();

    final List<XFile> images = await picker.pickMultiImage(imageQuality: 70);

    if (images.isNotEmpty) {
      setState(() {
        pickedImages = images.take(5).toList();
      });
    }
  }

  Future<void> handleCreateProduct() async {
    // Validate đơn giản

    // Chuẩn bị list File cho upload
    final List<File> images = pickedImages.map((e) => File(e.path)).toList();

    // Tạo payload
    Product productData = Product(
      id: '1',
      name: nameCtrl.text.trim(),
      price: double.tryParse(priceCtrl.text.trim()) ?? 0.0,
      description: descCtrl.text.trim(),
      categoryId: '1',
    );

    // Gọi bloc
    context.read<ProductBloc>().add(
      CreateProductEvent(productData: productData, images: images),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ProductBloc, ProductState>(
      listener: (context, state) {
        if (state is ProductCreateSuccess) {
          DialogUtils.showAppDialog(
            context: context,
            title: 'Tạo sản phẩm thành công',
            content: '',
            onFirstAction: () {
              Navigator.pop(context, true);
            },
            firstActionText: 'OK',
          );
          Navigator.pop(context, true);
        }
      },
      child: AppScaffold(
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
                _buildCategorySection(context),
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
        _buildInput(hint: "0.00đ", keyboard: TextInputType.number, controller: priceCtrl,),
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
        _buildInput(hint: "Mô tả ngắn về sản phẩm", maxLines: 4, controller: descCtrl),
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
        // Title row
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

        // Add Photo Box
        GestureDetector(
          onTap: () {
            pickImages();
          },
          child: Container(
            height: 130,
            decoration: _boxDecoration(),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (pickedImages.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.only(left: 8.w),
                      child: SizedBox(
                        height: 100,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: pickedImages.length,
                          separatorBuilder: (_, __) => SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                File(pickedImages[index].path),
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                              ),
                            );
                          },
                        ),
                      ),
                    )
                  else ...[
                    Icon(
                      Icons.add_photo_alternate_outlined,
                      size: 40,
                      color: Colors.blue,
                    ),
                    SizedBox(height: 8),
                    Text(
                      "Thêm hình ảnh",
                      style: TextStyle(
                        color: Colors.blue,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "Chọn hình ảnh cho sản phẩm của bạn",
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
