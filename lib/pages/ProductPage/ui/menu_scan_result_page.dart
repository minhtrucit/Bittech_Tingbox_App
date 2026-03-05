import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../ting_box.dart';

class MenuScanResultPage extends StatefulWidget {
  final String imagePath;
  final List<Map<String, dynamic>> detectedProducts;

  const MenuScanResultPage({
    super.key,
    required this.imagePath,
    required this.detectedProducts,
  });

  @override
  State<MenuScanResultPage> createState() => _MenuScanResultPageState();
}

class _MenuScanResultPageState extends State<MenuScanResultPage> {
  late List<Map<String, dynamic>> _editableProducts;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Clone list to make it editable
    _editableProducts = List<Map<String, dynamic>>.from(
      widget.detectedProducts.map((p) => Map<String, dynamic>.from(p)),
    );
  }

  void _removeProduct(int index) {
    setState(() {
      _editableProducts.removeAt(index);
    });
  }

  Future<void> _saveAll() async {
    if (_editableProducts.isEmpty) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final productBloc = context.read<ProductBloc>();

      for (final p in _editableProducts) {
        final productData = Product(
          id: 0,
          name: p['name'],
          price: (p['price'] as num).toDouble(),
          description: p['description'] ?? '',
          categoryId: 2, // Default or selected category
          url: '',
        );

        // We'll need to adapt CreateProductEvent to support batch or handle it sequentially
        // For simplicity in UI demo, we show the process
        productBloc.add(
          CreateProductEvent(productData: productData, images: []),
        );
        await Future.delayed(const Duration(milliseconds: 500));
      }

      if (mounted) {
        DialogUtils.showAppDialog(
          context: context,
          title: 'Thành công',
          content: 'Đã thêm ${_editableProducts.length} sản phẩm vào danh mục.',
          onFirstAction: () {
            Navigator.of(context).popUntil((route) => route.isFirst);
            productBloc.add(GetProductsEvent());
          },
          firstActionText: 'Tuyệt vời',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi khi lưu sản phẩm: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
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
                  child: ListView.builder(
                    padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 110.h),
                    itemCount: _editableProducts.length,
                    itemBuilder: (context, index) {
                      return _buildModernProductCard(index);
                    },
                  ),
                ),
              ],
            ),

            // Fixed Bottom Action Bar
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
    );
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
                  _buildEditableField(
                    label: "Tên sản phẩm",
                    initialValue: product['name'],
                    onChanged: (val) => product['name'] = val,
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
                          initialValue: product['price'].toString(),
                          onChanged:
                              (val) =>
                                  product['price'] = double.tryParse(val) ?? 0,
                          icon: Icons.payments_rounded,
                          keyboardType: TextInputType.number,
                          suffix: "đ",
                        ),
                      ),
                      SizedBox(width: 16.w),
                      Expanded(
                        flex: 3,
                        child: _buildEditableField(
                          label: "Mô tả nhanh",
                          initialValue: product['description'] ?? "",
                          onChanged: (val) => product['description'] = val,
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
}
