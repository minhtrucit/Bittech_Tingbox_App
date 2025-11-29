import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ting_box/extension/date_time_extension.dart';
import '../../../ting_box.dart';

class OrderDetailPage extends StatelessWidget {
  final Order order;

  const OrderDetailPage({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(context),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildOrderInfoCard(),
              SizedBox(height: 16.h),
              _buildProductsSection(),
              SizedBox(height: 16.h),
              _buildSummarySection(),
              SizedBox(height: 100.h),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomButton(context),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppAppBar(
      title: TitleAppbarText(title: 'Chi tiết Đơn hàng'),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildOrderInfoCard() {
    final orderId = '#${order.code}-${order.id}';
    debugPrint('Order ID: $orderId');
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        children: [
          // Order ID
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Mã đơn hàng: ',
                style: TextStyle(fontSize: 14.sp, color: Colors.grey.shade600),
              ),
              Text(
                orderId,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),

          // Status Badge
          Align(
            alignment: Alignment.center,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(
                color:
                    order.paymentStatus == 'unpaid'
                        ? Colors.orange.withValues(alpha: 0.1)
                        : Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Text(
                order.paymentStatus == 'unpaid'
                    ? 'Chưa thanh toán'
                    : 'Đã thanh toán',
                style: TextStyle(
                  fontSize: 13.sp,
                  color:
                      order.paymentStatus == 'unpaid'
                          ? Colors.orange
                          : Colors.green,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          SizedBox(height: 16.h),

          Divider(color: Colors.grey.shade200, height: 1),
          SizedBox(height: 16.h),

          // Order Date
          _buildInfoRow('Ngày đặt hàng', _formatOrderDate(order.createdAt)),
          SizedBox(height: 12.h),

          // Payment Method
          _buildInfoRow('Phương thức thanh toán', order.paymentMethod),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(fontSize: 14.sp, color: Colors.grey.shade600),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  String _formatOrderDate(String? createdAt) {
    if (createdAt == null) return '';

    return createdAt.toReadableDateTime();
  }

  Widget _buildProductsSection() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sản phẩm',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 16.h),

          // Product List
          ...order.items.map((item) => _buildProductItem(item)),
        ],
      ),
    );
  }

  Widget _buildProductItem(OrderItem item) {
    final productName = item.product?.name ?? 'Sản phẩm #${item.productId}';
    // Check if images list exists and is not empty before accessing first
    final productImage =
        item.product?.url ??
        ((item.product?.images != null && item.product!.images!.isNotEmpty)
            ? item.product!.images!.first.url
            : null);

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        children: [
          // Product Icon/Image
          Container(
            width: 48.w,
            height: 48.w,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8.r),
              image:
                  productImage != null
                      ? DecorationImage(
                        image: NetworkImage(productImage),
                        fit: BoxFit.cover,
                      )
                      : null,
            ),
            child:
                productImage == null
                    ? Icon(Icons.coffee, color: Colors.grey.shade600, size: 24)
                    : null,
          ),
          SizedBox(width: 12.w),

          // Product Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  productName,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  '${item.quantity} x ${formatMoney(item.unitPrice)}đ',
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),

          // Product Total
          Text(
            '${formatMoney(item.quantity * item.unitPrice)}đ',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummarySection() {
    final subtotal = order.totalAmount ?? 0;
    final discount = order.discount;
    final vat = order.vat;
    final paidAmount = order.paidAmount;
    final total = subtotal + vat - discount;
    final change = paidAmount - total;

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        children: [
          _buildSummaryRow('Tạm tính', '${formatMoney(subtotal)}đ', false),
          SizedBox(height: 12.h),
          _buildSummaryRow('VAT', '${formatMoney(vat)}%', false),
          SizedBox(height: 12.h),
          _buildSummaryRow('Giảm giá', '${formatMoney(discount)}đ', false),
          SizedBox(height: 16.h),
          Divider(color: Colors.grey.shade200, height: 1),
          SizedBox(height: 16.h),
          _buildSummaryRow('Tổng cộng', '${formatMoney(total)}đ', true),
          SizedBox(height: 12.h),
          _buildSummaryRow(
            'Đã thanh toán',
            '${formatMoney(paidAmount)}đ',
            false,
          ),
          SizedBox(height: 12.h),
          _buildSummaryRow(
            'Tiền thừa/Trả lại',
            '${formatMoney(change > 0 ? change : 0)}đ',
            false,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, bool isBold) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isBold ? 16.sp : 14.sp,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: isBold ? Colors.black87 : Colors.grey.shade600,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 18.sp : 14.sp,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: isBold ? AppColors.primaryBlue : Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomButton(BuildContext context) {
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
        child: Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 48.h,
                child: IconButton(
                  onPressed: () {
                    // TODO: Implement print invoice
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(content: Text('In hóa đơn')));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue.withValues(
                      alpha: 0.1,
                    ),
                    foregroundColor: AppColors.primaryBlue,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  icon: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.print, size: 24.sp),
                      SizedBox(width: 12.w),
                      Text(
                        'In hóa đơn',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: SizedBox(
                height: 48.h,
                child: ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Generate QR code for payment
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Tạo mã QR thanh toán')),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  icon: const Icon(Icons.qr_code, color: Colors.white),
                  label: Text(
                    'Tạo mã QR',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
