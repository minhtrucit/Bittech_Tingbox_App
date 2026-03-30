import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ting_box/models/menu.dart';
import '../bloc/ocr_correction_bloc.dart';
import '../bloc/ocr_correction_event.dart';
import '../bloc/ocr_correction_state.dart';
import '../../../ting_box.dart';

class MenuScanResultPage extends StatefulWidget {
  final Menu menu;

  const MenuScanResultPage({super.key, required this.menu});

  @override
  State<MenuScanResultPage> createState() => _MenuScanResultPageState();
}

class _MenuScanResultPageState extends State<MenuScanResultPage> {
  late List<MenuItem> _editableProducts;
  bool _isSaving = false;
  final Map<int, String?> _localImages = {};
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    _editableProducts = List<MenuItem>.from(widget.menu.menuItems);
    super.initState();
  }

  void _removeProduct(int index) {
    setState(() {
      _editableProducts.removeAt(index);
      // Shift images in map
      for (int i = index; i < _editableProducts.length + 1; i++) {
        _localImages[i] = _localImages[i + 1];
      }
      _localImages.remove(_editableProducts.length + 1);
    });
  }

  Future<void> _pickImage(int index, ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source);
    if (image != null) {
      setState(() {
        _localImages[index] = image.path;
      });
    }
  }

  void _showImagePickerOptions(int index) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded),
                title: const Text("Chụp ảnh mới"),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(index, ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.image_rounded),
                title: const Text("Chọn từ thư viện"),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(index, ImageSource.gallery);
                },
              ),
              if (_localImages[index] != null)
                ListTile(
                  leading: const Icon(
                    Icons.delete_forever_rounded,
                    color: Colors.red,
                  ),
                  title: const Text(
                    "Xóa ảnh hiện tại",
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _localImages[index] = null;
                    });
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  bool _hasChanges() {
    if (widget.menu.menuItems.length != _editableProducts.length) return true;
    for (int i = 0; i < _editableProducts.length; i++) {
      final original = widget.menu.menuItems[i];
      final current = _editableProducts[i];
      if (original.name != current.name ||
          original.price != current.price ||
          original.description != current.description ||
          original.category != current.category) {
        return true;
      }
    }
    return false;
  }

  Future<void> _saveAll() async {
    if (_editableProducts.isEmpty) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final productBloc = context.read<ProductBloc>();
      final correctionBloc = context.read<OcrCorrectionBloc>();

      // Submit feedback/correction if data changed
      if (_hasChanges() && widget.menu.documentId != null) {
        final correctedMenu = Menu(
          businessName: widget.menu.businessName,
          businessInfo: widget.menu.businessInfo,
          menuItems: _editableProducts,
          documentId: widget.menu.documentId,
        );
        correctionBloc.add(
          SubmitOcrCorrectionEvent(
            documentId: widget.menu.documentId!,
            correctedData: correctedMenu.toJson(),
          ),
        );
      }

      final List<Product> productsToCreate = [];
      final List<File?> productImages = [];

      for (int i = 0; i < _editableProducts.length; i++) {
        final p = _editableProducts[i];
        productsToCreate.add(
          Product(
            id: 0,
            name: p.name ?? '',
            price: p.price,
            description: p.description ?? '',
            categoryId: 2,
            url: '',
          ),
        );

        final localPath = _localImages[i];
        productImages.add(localPath != null ? File(localPath) : null);
      }

      productBloc.add(
        CreateBatchProductsEvent(
          products: productsToCreate,
          productImages: productImages,
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        NotificationUtils.showError(
          context: context,
          title: 'Lỗi',
          description: 'Lỗi khi chuẩn bị lưu sản phẩm: $e',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<ProductBloc, ProductState>(
          listener: (context, state) {
            if (state is ProductBatchCreateSuccess) {
              setState(() => _isSaving = false);
              NotificationUtils.showSuccess(
                context: context,
                title: 'Thành công',
                description: 'Đã thêm ${state.count} sản phẩm vào danh mục.',
              );
              Navigator.of(context).popUntil((route) => route.isFirst);
              context.read<ProductBloc>().add(GetProductsEvent());
            } else if (state is ProductFailure && _isSaving) {
              setState(() => _isSaving = false);
              NotificationUtils.showError(
                context: context,
                title: 'Lỗi tạo sản phẩm',
                description: state.message,
              );
            }
          },
        ),
        BlocListener<OcrCorrectionBloc, OcrCorrectionState>(
          listener: (context, state) {
            if (state is OcrCorrectionFailure && _isSaving) {
              debugPrint('Correction failed: ${state.message}');
              // We don't block the main flow if correction fails, just log it
            }
          },
        ),
      ],
      child: AppScaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        hasSafeArea: false,
        appBar: AppAppBar(title: TitleAppbarText(title: "Sản phẩm tìm thấy")),
        body: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  _buildSummaryHeader(),
                  Expanded(
                    child: Builder(
                      builder: (context) {
                        final grouped = _getGroupedIndices();
                        return ListView.builder(
                          padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 110.h),
                          itemCount: grouped.length,
                          itemBuilder: (context, catIndex) {
                            final entry = grouped.entries.elementAt(catIndex);
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                    vertical: 12.h,
                                    horizontal: 8.w,
                                  ),
                                  child: Text(
                                    entry.key.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blueGrey.shade800,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ),
                                ...entry.value.map(
                                  (idx) => _buildModernProductCard(idx),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _buildBottomActionBar(),
              ),
              if (_isSaving)
                const AILoadingOverlay(message: "Đang đồng bộ dữ liệu..."),
            ],
          ),
        ),
      ),
    );
  }

  Map<String, List<int>> _getGroupedIndices() {
    Map<String, List<int>> map = {};
    for (int i = 0; i < _editableProducts.length; i++) {
      String cat = _editableProducts[i].category ?? 'Khác';
      if (cat.isEmpty) cat = 'Khác';
      map.putIfAbsent(cat, () => []).add(i);
    }
    return map;
  }

  Widget _buildSummaryHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      margin: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryBlue, const Color(0xFF1565C0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.auto_awesome_rounded,
              color: Colors.white,
              size: 28.sp,
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Hoàn tất phân tích!",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18.sp,
                  ),
                ),
                Text(
                  "AI đã bóc tách được ${_editableProducts.length} sản phẩm từ ảnh",
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 13.sp,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernProductCard(int index) {
    final product = _editableProducts[index];

    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20.r),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.fromLTRB(16.w, 8.h, 8.w, 4.h),
              color: AppColors.primaryBlue.withValues(alpha: 0.05),
              child: Row(
                children: [
                  Text(
                    "SẢN PHẨM #${index + 1}",
                    style: TextStyle(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryBlue,
                      letterSpacing: 1,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(
                      Icons.remove_circle_outline_rounded,
                      color: Colors.red.shade300,
                      size: 20.sp,
                    ),
                    onPressed: () => _removeProduct(index),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildImageSelector(index),
                  SizedBox(height: 16.h),
                  _buildCategoryField(index, product),
                  SizedBox(height: 16.h),
                  _buildEditableField(
                    label: "Tên sản phẩm",
                    initialValue: product.name ?? '',
                    onChanged: (val) {
                      setState(() {
                        _editableProducts[index] = MenuItem(
                          category: product.category,
                          name: val,
                          price: product.price,
                          description: product.description,
                          thumbnailUrl: product.thumbnailUrl,
                        );
                      });
                    },
                    icon: Icons.edit_note_rounded,
                    isBold: true,
                  ),
                  SizedBox(height: 16.h),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: _buildEditableField(
                          label: "Giá bán",
                          initialValue: product.price.dot,
                          onChanged: (val) {
                            setState(() {
                              _editableProducts[index] = MenuItem(
                                category: product.category,
                                name: product.name,
                                price:
                                    CurrencyInputFormatter.parseValue(val) ?? 0,
                                description: product.description,
                                thumbnailUrl: product.thumbnailUrl,
                              );
                            });
                          },
                          icon: Icons.payments_rounded,
                          keyboardType: TextInputType.number,
                          inputFormatters: [CurrencyInputFormatter()],
                          suffix: "đ",
                        ),
                      ),
                      SizedBox(width: 16.w),
                      Expanded(
                        flex: 3,
                        child: _buildEditableField(
                          label: "Mô tả nhanh",
                          initialValue: product.description ?? "",
                          onChanged: (val) {
                            setState(() {
                              _editableProducts[index] = MenuItem(
                                category: product.category,
                                name: product.name,
                                price: product.price,
                                description: val,
                                thumbnailUrl: product.thumbnailUrl,
                              );
                            });
                          },
                          icon: Icons.description_rounded,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditableField({
    required String label,
    required String initialValue,
    required Function(String) onChanged,
    required IconData icon,
    bool isBold = false,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    String? suffix,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14.sp, color: Colors.grey.shade400),
            SizedBox(width: 4.w),
            Text(
              label.toUpperCase(),
              style: TextStyle(
                fontSize: 10.sp,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
        TextFormField(
          initialValue: initialValue,
          onChanged: onChanged,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          style: TextStyle(
            fontSize: 15.sp,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            color: Colors.blueGrey.shade800,
          ),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: EdgeInsets.symmetric(vertical: 8.h),
            border: InputBorder.none,
            suffixText: suffix,
            suffixStyle: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade400,
            ),
          ),
        ),
        Container(height: 1, color: Colors.grey.shade100),
      ],
    );
  }

  Widget _buildCategoryField(int index, MenuItem product) {
    // Collect all available categories from current items
    final categories =
        _editableProducts
            .map((e) => e.category?.trim() ?? '')
            .where((c) => c.isNotEmpty && c != 'Khác')
            .toSet()
            .toList();

    // Add 'Khác' to the list if not present
    if (!categories.contains('Khác')) categories.add('Khác');

    String currentCat = product.category?.trim() ?? 'Khác';
    if (currentCat.isEmpty) currentCat = 'Khác';

    // If the current category somehow isn't in the list, add it
    if (!categories.contains(currentCat)) {
      categories.add(currentCat);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.category_rounded,
              size: 14.sp,
              color: Colors.grey.shade400,
            ),
            SizedBox(width: 4.w),
            Text(
              "DANH MỤC".toUpperCase(),
              style: TextStyle(
                fontSize: 10.sp,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
        DropdownButtonFormField<String>(
          value: currentCat,
          isExpanded: true,
          icon: Icon(
            Icons.arrow_drop_down_rounded,
            color: Colors.grey.shade600,
          ),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: EdgeInsets.symmetric(vertical: 8.h),
            border: InputBorder.none,
          ),
          items: [
            ...categories.map(
              (c) => DropdownMenuItem(
                value: c,
                child: Text(
                  c,
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey.shade800,
                  ),
                ),
              ),
            ),
            DropdownMenuItem(
              value: '__ADD_NEW__',
              child: Row(
                children: [
                  Icon(
                    Icons.add_circle_outline_rounded,
                    color: AppColors.primaryBlue,
                    size: 18.sp,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    "Thêm danh mục mới",
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                ],
              ),
            ),
          ],
          onChanged: (val) async {
            // Restore previous value immediately to avoid UI glitch if they cancel

            if (val == '__ADD_NEW__') {
              final newCat = await _showAddCategoryDialog();
              if (newCat != null && newCat.isNotEmpty) {
                setState(() {
                  _editableProducts[index] = MenuItem(
                    category: newCat,
                    name: product.name,
                    price: product.price,
                    description: product.description,
                    thumbnailUrl: product.thumbnailUrl,
                  );
                });
              } else {
                // If cancelled, just setstate to force rebuild with original value
                setState(() {});
              }
            } else if (val != null) {
              setState(() {
                _editableProducts[index] = MenuItem(
                  category: val,
                  name: product.name,
                  price: product.price,
                  description: product.description,
                  thumbnailUrl: product.thumbnailUrl,
                );
              });
            }
          },
        ),
        Container(height: 1, color: Colors.grey.shade100),
      ],
    );
  }

  Future<String?> _showAddCategoryDialog() {
    final TextEditingController catCtrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          title: Text(
            "Tạo danh mục mới",
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey.shade800,
            ),
          ),
          content: TextField(
            controller: catCtrl,
            autofocus: true,
            decoration: InputDecoration(
              hintText: "Nhập tên danh mục",
              hintStyle: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 14.sp,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(color: AppColors.primaryBlue),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "Hủy",
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, catCtrl.text.trim()),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
              child: const Text("Thêm"),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBottomActionBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(24.w, 16.h, 24.w, 32.h),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Tổng cộng",
                  style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                ),
                Text(
                  "${_editableProducts.length} mặt hàng",
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 180.w,
            height: 52.h,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _saveAll,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.save_alt_rounded),
                  SizedBox(width: 8.w),
                  Text(
                    "Lưu lại",
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageSelector(int index) {
    final String? localPath = _localImages[index];

    return GestureDetector(
      onTap: () => _showImagePickerOptions(index),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.image_outlined,
                size: 14.sp,
                color: Colors.grey.shade400,
              ),
              SizedBox(width: 4.w),
              Text(
                "ẢNH SẢN PHẨM",
                style: TextStyle(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Container(
            width: double.infinity,
            height: 120.h,
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color:
                    localPath != null
                        ? AppColors.primaryBlue.withValues(alpha: 0.3)
                        : Colors.grey.shade200,
                width: 1.5,
              ),
            ),
            child:
                localPath != null
                    ? Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16.r),
                          child: Image.file(
                            File(localPath),
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.contain,
                          ),
                        ),
                        Positioned(
                          right: 8.w,
                          top: 8.h,
                          child: Container(
                            padding: EdgeInsets.all(4.w),
                            decoration: const BoxDecoration(
                              color: Colors.black45,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.edit_rounded,
                              size: 14.sp,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    )
                    : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_a_photo_outlined,
                          size: 32.sp,
                          color: Colors.grey.shade400,
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          "Chụp hoặc chọn ảnh",
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ],
                    ),
          ),
        ],
      ),
    );
  }
}
