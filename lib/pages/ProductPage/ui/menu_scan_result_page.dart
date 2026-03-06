import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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

  @override
  void initState() {
    _editableProducts = List<MenuItem>.from(widget.menu.menuItems);
    super.initState();
  }

  void _removeProduct(int index) {
    setState(() {
      _editableProducts.removeAt(index);
    });
  }

  bool _hasChanges() {
    if (widget.menu.menuItems.length != _editableProducts.length) return true;
    for (int i = 0; i < _editableProducts.length; i++) {
      final original = widget.menu.menuItems[i];
      final current = _editableProducts[i];
      if (original.name != current.name ||
          original.price != current.price ||
          original.description != current.description) {
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

      final List<Product> productsToCreate =
          _editableProducts
              .map(
                (p) => Product(
                  id: 0,
                  name: p.name ?? '',
                  price: p.price,
                  description: p.description ?? '',
                  categoryId: 2,
                  url: '',
                ),
              )
              .toList();

      productBloc.add(CreateBatchProductsEvent(products: productsToCreate));
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        DialogUtils.showAppDialog(
          context: context,
          title: 'Lỗi',
          content: 'Lỗi khi chuẩn bị lưu sản phẩm: $e',
          onFirstAction: () => Navigator.pop(context),
          firstActionText: 'Đóng',
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
              DialogUtils.showAppDialog(
                context: context,
                title: 'Thành công',
                content: 'Đã thêm ${state.count} sản phẩm vào danh mục.',
                onFirstAction: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                  context.read<ProductBloc>().add(GetProductsEvent());
                },
                firstActionText: 'Đóng',
              );
            } else if (state is ProductFailure && _isSaving) {
              setState(() => _isSaving = false);
              DialogUtils.showAppDialog(
                context: context,
                title: 'Lỗi tạo sản phẩm',
                content: 'Lỗi khi tạo sản phẩm: vui lòng thử lại',
                onFirstAction: () => Navigator.pop(context),
                firstActionText: 'Đóng',
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
                    initialValue: product.name ?? '',
                    onChanged: (val) {
                      setState(() {
                        _editableProducts[index] = MenuItem(
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
