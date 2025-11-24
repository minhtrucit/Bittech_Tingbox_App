import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ting_box/models/payment_info.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../services/websocket_manager.dart';
import '../../../ting_box.dart';

class QrPage extends StatefulWidget {
  const QrPage({required this.paymentInfo, super.key});
  final PaymentInfo paymentInfo;

  @override
  State<QrPage> createState() => _QrPageState();
}

class _QrPageState extends State<QrPage> {
  late WebSocketManager webSocketManager = WebSocketManager();
  @override
  void initState() {
    webSocketManager.on("payment.success", (data) {
      try {
        final jsonData = data as Map<String, dynamic>;
        debugPrint('event data from websocket json: $jsonData');

        context.read<OrderBloc>().add(OrderPaymentSuccessEvent(jsonData));
      } catch (e) {
        debugPrint('event data from websocket error $e');
      }
    });
    super.initState();
  }

  void showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.r),
            ),
            backgroundColor: Colors.white,
            child: Padding(
              padding: EdgeInsets.all(24.w),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon check
                  Container(
                    width: 64.w,
                    height: 64.w,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9), // Light green
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check,
                      color: const Color(0xFF4CAF50), // Green
                      size: 32.w,
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // Title
                  Text(
                    "Thanh toán thành công",
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 24.h),

                  // Button: In hóa đơn
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2962FF), // Blue
                        elevation: 0,
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: Text(
                        "In hóa đơn",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 12.h),

                  // Button: Trở về trang bán hàng
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE3F2FD), // Light Blue
                        elevation: 0,
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: Text(
                        "Trở về trang bán hàng",
                        style: TextStyle(
                          color: const Color(0xFF2962FF), // Blue text
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<OrderBloc, OrderState>(
      listener: (context, state) {
        if (state is OrderPaymentSuccess) {
          showSuccessDialog();
        }
      },
      child: AppScaffold(
        backgroundColor: Colors.grey[100],
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(24.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Thanh toán đơn hàng",
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // QR Code
                  Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Image.network(
                      widget.paymentInfo.qrCodeUrl,
                      width: 200.w,
                      height: 200.w,
                      fit: BoxFit.contain,
                      errorBuilder:
                          (_, __, ___) => Icon(
                            Icons.qr_code,
                            size: 200.w,
                            color: Colors.grey,
                          ),
                    ),
                  ),
                  SizedBox(height: 24.h),

                  // Payment info
                  _buildInfoRow("Ngân hàng", widget.paymentInfo.bankCode),
                  _buildInfoRow(
                    "Số tài khoản",
                    widget.paymentInfo.accountNumber,
                  ),
                  _buildInfoRow(
                    "Chủ tài khoản",
                    widget.paymentInfo.accountName,
                  ),
                  _buildInfoRow(
                    "Số tiền",
                    "${formatMoney(widget.paymentInfo.amount)} đ",
                  ),
                  _buildInfoRow("Nội dung", widget.paymentInfo.content),
                  SizedBox(height: 16.h),
                  Text(
                    widget.paymentInfo.note,
                    style: TextStyle(fontSize: 14.sp, color: Colors.grey[700]),
                    textAlign: TextAlign.center,
                  ),

                  SizedBox(height: 24.h),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      minimumSize: Size(double.infinity, 48.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    child: Text(
                      "Đóng",
                      style: TextStyle(
                        fontSize: 16.sp,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "$label:",
            style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14.sp),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 14.sp),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
