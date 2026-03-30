import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../ting_box.dart';
import 'edit_product_page.dart';

class ProductDetailPage extends StatefulWidget {
  final Product product;

  const ProductDetailPage({super.key, required this.product});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  late Product currentProduct;
  bool isLoading = false;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    currentProduct = widget.product;
    _loadUser();
  }

  void _loadUser() async {
    final user = await UserRepository.getUser();
    if (mounted) {
      setState(() {
        _isAdmin = user?.canManageProducts ?? false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ProductBloc, ProductState>(
      listener: (context, state) {
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
              Navigator.pop(context); // Pop ProductDetailPage
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
            backgroundColor: Colors.white,
            hasSafeArea: false,
            appBar: _buildAppBar(context),
            body: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProductImage(),
                  Padding(
                    padding: EdgeInsets.all(16.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildProductName(),
                        SizedBox(height: 8.h),
                        _buildProductPrice(),
                        SizedBox(height: 24.h),
                        _buildDescriptionSection(),
                        SizedBox(height: 24.h),
                        _buildCategorySection(),
                        SizedBox(height: 100.h),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            bottomNavigationBar: _isAdmin ? _buildBottomActions(context) : null,
          ),
          if (isLoading) const LoadingOverlay(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppAppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: buildBackButton(context),
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

  Widget _buildProductImage() {
    return Hero(
      tag: 'product_${currentProduct.id}',
      child: Container(
        width: double.infinity,
        height: 300.h,
        decoration: const BoxDecoration(color: Color(0xFF2C3E50)),
        child:
            currentProduct.images != null && currentProduct.images!.isNotEmpty
                ? Image.network(
                  currentProduct.images!.first.url,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return _buildPlaceholderImage();
                  },
                )
                : _buildPlaceholderImage(),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Center(
      child: Icon(
        Icons.image_outlined,
        size: 80,
        color: Colors.white.withValues(alpha: 0.5),
      ),
    );
  }

  Widget _buildProductName() {
    return Text(
      currentProduct.name,
      style: TextStyle(
        fontSize: 24.sp,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildProductPrice() {
    return Text(
      '${formatMoney(currentProduct.price)}đ',
      style: TextStyle(
        fontSize: 20.sp,
        fontWeight: FontWeight.w600,
        color: AppColors.primaryBlue,
      ),
    );
  }

  Widget _buildDescriptionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mô tả',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 8.h),
        if (currentProduct.description != null)
          Text(
            currentProduct.description!.isNotEmpty
                ? currentProduct.description!
                : 'Không có mô tả',
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey.shade700,
              height: 1.5,
            ),
          ),
      ],
    );
  }

  Widget _buildCategorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Danh mục',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 8.h),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: AppColors.primaryBlue.withAlpha(10),
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Text(
            currentProduct.category != null &&
                    currentProduct.category!.name.isNotEmpty
                ? currentProduct.category!.name
                : 'Không có danh mục',
            style: TextStyle(
              fontSize: 14.sp,
              color: AppColors.primaryBlue,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomActions(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              height: 48.h,
              child: ElevatedButton(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => EditProductPage(product: currentProduct),
                    ),
                  );

                  // If product was updated, refresh the detail page
                  if (result != null && result is Product && mounted) {
                    setState(() {
                      currentProduct = result;
                    });
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                child: Text(
                  'Sửa sản phẩm',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            SizedBox(height: 12.h),
            SizedBox(
              width: double.infinity,
              height: 48.h,
              child: OutlinedButton(
                onPressed: () {
                  _showDeleteConfirmation(context);
                },
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.red, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                child: Text(
                  'Xóa sản phẩm',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.red,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    DialogUtils.showAppDialog(
      context: context,
      title: 'Xác nhận xóa',
      content: 'Bạn có chắc chắn muốn xóa sản phẩm "${currentProduct.name}"?',
      firstActionText: 'Hủy',
      secondActionText: 'Xóa',
      onFirstAction: () {
        Navigator.pop(context);
      },
      onSecondAction: () {
        Navigator.pop(context); // Close dialog
        setState(() {
          isLoading = true;
        });
        context.read<ProductBloc>().add(
          DeleteProductEvent(productId: currentProduct.id),
        );
      },
    );
  }
}
