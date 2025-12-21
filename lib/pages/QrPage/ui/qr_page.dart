import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ting_box/models/payment_info.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ting_box/pages/ConfigPage/bloc/config_bloc.dart';
import 'package:ting_box/pages/ConfigPage/bloc/config_state.dart';

import '../../../services/websocket_manager.dart';
import '../../../ting_box.dart';

class QrPage extends StatefulWidget {
  const QrPage({
    required this.paymentInfo,
    required this.orderCode,
    required this.orderId,
    super.key,
  });
  final PaymentInfo paymentInfo;
  final String orderCode;
  final int orderId;

  @override
  State<QrPage> createState() => _QrPageState();
}

class _QrPageState extends State<QrPage> {
  late WebSocketManager webSocketManager = WebSocketManager();
  bool isDevMode = false;
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
    getUserInfo();
    super.initState();
  }

  Future<void> getUserInfo() async {
    final user = await UserRepository.getUser();
    debugPrint('user: $user');
    if (user != null) {
      isDevMode = user.isDevMode ?? false;
      setState(() {});
      debugPrint('isDevMode: $isDevMode');
    }
  }

  @override
  void dispose() {
    webSocketManager.off("payment.success");
    super.dispose();
  }

  Future<void> _handlePrint(BuildContext context) async {
    // Lấy order từ OrderBloc state
    final orderState = context.read<OrderBloc>().state;
    Order? order;

    if (orderState is OrderPaymentSuccess) {
      order = orderState.order;
    }

    if (order == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không tìm thấy thông tin đơn hàng'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Lấy config từ ConfigBloc state
    final configState = context.read<ConfigBloc>().state;
    ConfigModel? config;

    if (configState is ConfigLoaded) {
      config = configState.config;
    } else if (configState is ConfigUpdateSuccess) {
      config = configState.config;
    } else if (configState is ConfigCreateSuccess) {
      config = configState.config;
    }

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
        // Đóng success dialog
        Navigator.pop(context);
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

  void showSuccessDialog({required BuildContext dialogContext, required bool isManualPrint}) {
    showDialog(
      context: dialogContext,
      barrierDismissible: false,
      builder:
          (childContext) => Dialog(
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

                  if (isManualPrint)
                    Padding(
                      padding: EdgeInsets.only(bottom: 12.h),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => _handlePrint(dialogContext),
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
                    ),

                  // Button: Trở về trang bán hàng
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        // Đóng dialog thành công
                        Navigator.of(childContext).pop();
                        Navigator.of(dialogContext).pop();
                        Navigator.of(dialogContext).pop();

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
          final configState = context.read<ConfigBloc>().state;
          ConfigModel? currentConfig;

          if (configState is ConfigLoaded) {
            currentConfig = configState.config;
          } else if (configState is ConfigUpdateSuccess) {
            currentConfig = configState.config;
          } else if (configState is ConfigCreateSuccess) {
            currentConfig = configState.config;
          }

          showSuccessDialog(
            dialogContext: context,
            isManualPrint: currentConfig?.printMode == PrintMode.manual,
          );
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
                  Row(
                    spacing: 8.w,
                    children: [
                      if (isDevMode)
                        Expanded(
                          child: SizedBox(
                            height: 48.h,
                            child: AppTextButton(
                              onPressed: () {
                                context.read<OrderBloc>().add(
                                  OrderSePayWebHookEvent(
                                    orderId: widget.orderId,
                                    orderCode: widget.orderCode,
                                    transferAmount:
                                        widget.paymentInfo.amount.toInt(),
                                    transactionDate: DateTime.now().toString(),
                                    paymentInfo: widget.paymentInfo,
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryBlue
                                    .withValues(alpha: 0.1),
                                foregroundColor: AppColors.primaryBlue,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                              ),
                              label: Text(
                                'Demo thanh toán',
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primaryBlue,
                                ),
                              ),
                            ),
                          ),
                        ),
                      Expanded(
                        child: ElevatedButton(
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
                      ),
                    ],
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
