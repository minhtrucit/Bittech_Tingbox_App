import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ting_box/extension/date_time_extension.dart';
import '../../ting_box.dart';

class ReceiptPreviewPage extends StatelessWidget {
  final Order order;
  final ConfigModel? config;

  const ReceiptPreviewPage({super.key, required this.order, this.config});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      hasSafeArea: false,
      backgroundColor: Colors.grey[200],
      appBar: AppAppBar(title: TitleAppbarText(title: 'Xem trước hóa đơn')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.w),
          child: Center(
            child: Container(
              width: 300.w, // Giả lập khổ giấy 58mm
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(10),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: _buildReceiptContent(context),
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildActionButtons(context),
    );
  }

  Widget _buildReceiptContent(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Logo (nếu có)
          if (config?.logo != null && config!.logo!.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(bottom: 12.h),
              child: Image.network(
                config!.logo!,
                height: 60.h,
                errorBuilder: (context, error, stackTrace) => SizedBox(),
              ),
            ),

          // Tên cửa hàng
          Text(
            config?.unitName ?? 'TÊN CỬA HÀNG',
            style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),

          SizedBox(height: 4.h),

          // Địa chỉ
          if (config?.address != null && config!.address!.isNotEmpty)
            Text(
              config!.address!,
              style: TextStyle(fontSize: 11.sp, color: Colors.grey[700]),
              textAlign: TextAlign.center,
            ),

          // Số điện thoại
          if (config?.phone != null && config!.phone!.isNotEmpty)
            Text(
              'ĐT: ${config!.phone}',
              style: TextStyle(fontSize: 11.sp, color: Colors.grey[700]),
              textAlign: TextAlign.center,
            ),

          Divider(height: 24.h, thickness: 1),

          // Thông tin đơn hàng
          _buildInfoRow('Mã đơn:', '#${order.id}'),
          SizedBox(height: 4.h),
          _buildInfoRow('Ngày:', order.createdAt?.toReadableDateTime() ?? ''),
          if (order.customerName.isNotEmpty) ...[
            SizedBox(height: 4.h),
            _buildInfoRow('Khách hàng:', order.customerName),
          ],

          Divider(height: 24.h, thickness: 1),

          // Danh sách sản phẩm
          ...order.items.map((item) => _buildProductRow(item)),

          Divider(height: 24.h, thickness: 1),

          // Tạm tính
          _buildSummaryRow('Tạm tính:', order.subtotal ?? 0),
          SizedBox(height: 8.h),

          // VAT
          if (order.vat > 0) ...[
            _buildSummaryRow(
              'VAT (${order.vat.toStringAsFixed(0)}%):',
              (order.subtotal ?? 0) * order.vat / 100,
            ),
            SizedBox(height: 8.h),
          ],

          // Giảm giá
          if (order.discount > 0) ...[
            _buildSummaryRow('Giảm giá:', -order.discount, isNegative: true),
            SizedBox(height: 8.h),
          ],

          Divider(height: 24.h, thickness: 2),

          // Tổng tiền
          _buildTotalRow('TỔNG CỘNG:', order.totalAmount ?? 0),

          SizedBox(height: 12.h),

          // Đã thanh toán
          _buildSummaryRow('Đã thanh toán:', order.paidAmount),
          SizedBox(height: 8.h),

          // Còn lại / Tiền thừa
          _buildSummaryRow(
            (order.totalAmount ?? 0) > order.paidAmount
                ? 'Còn lại:'
                : 'Tiền thừa:',
            ((order.totalAmount ?? 0) - order.paidAmount).abs(),
            isHighlight: true,
          ),

          SizedBox(height: 16.h),

          // Footer
          Text(
            'Cảm ơn quý khách!',
            style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
          ),
          Text('Hẹn gặp lại', style: TextStyle(fontSize: 12.sp)),

          SizedBox(height: 8.h),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 12.sp, color: Colors.grey[700])),
        Text(
          value,
          style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildProductRow(OrderItem item) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  item.product?.name ?? 'Sản phẩm #${item.productId}',
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                formatMoney(item.unitPrice * item.quantity),
                style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Text(
                '${item.quantity} x ${formatMoney(item.unitPrice)}',
                style: TextStyle(fontSize: 11.sp, color: Colors.grey[600]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    double amount, {
    bool isNegative = false,
    bool isHighlight = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            color: isHighlight ? Colors.black87 : Colors.grey[700],
            fontWeight: isHighlight ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        Text(
          '${isNegative ? "-" : ""}${formatMoney(amount)}',
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: isHighlight ? FontWeight.w600 : FontWeight.w500,
            color:
                isNegative
                    ? Colors.red
                    : isHighlight
                    ? Colors.black87
                    : Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildTotalRow(String label, double amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
        ),
        Text(
          formatMoney(amount),
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryBlue,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(10),
              blurRadius: 10,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: ElevatedButton.icon(
          onPressed: () => _handlePrint(context),
          icon: Icon(Icons.print),
          label: Text('In hóa đơn'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryBlue,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(vertical: 14.h),
          ),
        ),
      ),
    );
  }

  Future<void> _handlePrint(BuildContext context) async {
    final printerService = PrinterService();

    // Kiểm tra đã kết nối máy in chưa
    final isConnected = await printerService.isConnected();

    if (!isConnected) {
      // Hiện dialog chọn máy in
      if (!context.mounted) return;
      final connected = await showDialog<bool>(
        context: context,
        builder: (context) => PrinterSelectorDialog(),
      );

      if (connected != true) return;
    }

    // Hiển thị loading
    if (!context.mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => Material(
            color: Colors.transparent,
            child: Center(
              child: Container(
                padding: EdgeInsets.all(24.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      color: AppColors.primaryBlue,
                      strokeWidth: 2,
                    ),
                    SizedBox(height: 16.h),
                    Text('Đang in hóa đơn...'),
                  ],
                ),
              ),
            ),
          ),
    );

    // In hóa đơn
    try {
      final success = await printerService.printReceipt(order, config: config);

      if (!context.mounted) return;
      Navigator.pop(context); // Đóng loading

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8.w),
                Text('Đã in hóa đơn thành công'),
              ],
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context); // Đóng preview page
      } else {
        throw Exception('In thất bại');
      }
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context); // Đóng loading

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi in hóa đơn: $e'),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: 'Thử lại',
            textColor: Colors.white,
            onPressed: () => _handlePrint(context),
          ),
        ),
      );
    }
  }
}
