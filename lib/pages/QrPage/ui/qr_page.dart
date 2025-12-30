import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ting_box/models/payment_info.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../services/websocket_manager.dart';
import '../../../services/print_service.dart';
import '../../../ting_box.dart';
import '../../ConfigPage/bloc/config_bloc.dart';
import '../../ConfigPage/bloc/config_state.dart';

class QrPage extends StatefulWidget {
  final PaymentInfo paymentInfo;
  final String orderCode;
  final int orderId;
  final int userId;
  final String paymentStatus;

  const QrPage({
    required this.paymentInfo,
    required this.orderCode,
    required this.orderId,
    required this.userId,
    required this.paymentStatus,
    super.key,
  });

  @override
  State<QrPage> createState() => _QrPageState();
}

class _QrPageState extends State<QrPage> {
  // ==================== CONSTANTS ====================

  // ==================== STATE ====================
  late final WebSocketManager _webSocketManager = WebSocketManager();
  bool _isDevMode = false;
  bool _isSuccess = false;

  // ==================== LIFECYCLE ====================
  @override
  void initState() {
    super.initState();
    _setupWebSocket();
    _loadUserInfo();
  }

  @override
  void dispose() {
    _webSocketManager.off("payment.success");
    super.dispose();
  }

  // ==================== INITIALIZATION ====================
  void _setupWebSocket() {
    _webSocketManager.on("payment.success", _handlePaymentSuccess);
  }

  void _handlePaymentSuccess(dynamic data) {
    try {
      final jsonData = data as Map<String, dynamic>;
      debugPrint('Payment success event: $jsonData');
      context.read<OrderBloc>().add(OrderPaymentSuccessEvent(jsonData));
    } catch (e) {
      debugPrint('Error handling payment success: $e');
    }
  }

  Future<void> _loadUserInfo() async {
    final user = await UserRepository.getUser();
    if (user != null && mounted) {
      setState(() {
        _isDevMode = user.isDevMode ?? false;
      });
    }
  }

  // ==================== DIALOGS & SNACKBARS ====================
  void _showSuccessDialog({
    required BuildContext dialogContext,
    required Order order,
  }) {
    showDialog(
      context: dialogContext,
      barrierDismissible: false,
      builder:
          (childContext) =>
              _buildSuccessDialog(childContext, dialogContext, order),
    );
  }

  // ==================== WIDGET BUILDERS ====================
  Widget _buildSuccessDialog(
    BuildContext childContext,
    BuildContext dialogContext,
    Order order,
  ) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      backgroundColor: Colors.white,
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSuccessIcon(),
            SizedBox(height: 16.h),
            _buildSuccessTitle(),
            SizedBox(height: 24.h),
            _buildBackButton(childContext, dialogContext),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessIcon() {
    return Container(
      width: 64.w,
      height: 64.w,
      decoration: const BoxDecoration(
        color: Color(0xFFE8F5E9),
        shape: BoxShape.circle,
      ),
      child: Icon(Icons.check, color: const Color(0xFF4CAF50), size: 32.w),
    );
  }

  Widget _buildSuccessTitle() {
    return Text(
      "Thanh toán thành công",
      style: TextStyle(
        fontSize: 18.sp,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildBackButton(
    BuildContext childContext,
    BuildContext dialogContext,
  ) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          Navigator.of(childContext).pop();
          Navigator.of(dialogContext).pop();
          Navigator.of(dialogContext).pop();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFE3F2FD),
          elevation: 0,
          padding: EdgeInsets.symmetric(vertical: 14.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
        child: Text(
          "Trở về trang bán hàng",
          style: TextStyle(
            color: const Color(0xFF2962FF),
            fontSize: 16.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  void _handlePaymentSuccessState(
    BuildContext context,
    OrderPaymentSuccess state,
  ) {
    _isSuccess = true;
    final order = state.order;

    if (order != null) {
      // Handle Auto Print if configured
      final configState = context.read<ConfigBloc>().state;
      if (configState is ConfigLoaded) {
        final config = configState.config;
        if (config.printMode == PrintMode.auto) {
          debugPrint('🖨️ [QrPage] Triggering automatic print...');
          PrintService().autoPrintOrder(order, config).then((success) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    success ? 'Đã tự động gửi lệnh in' : 'Lỗi khi tự động in',
                  ),
                  backgroundColor: success ? Colors.green : Colors.red,
                ),
              );
            }
          });
        }
      }

      _showSuccessDialog(dialogContext: context, order: order);
    } else {
      debugPrint('⚠️ Order is null in OrderPaymentSuccess state');
    }
  }

  // ==================== BUILD ====================
  @override
  Widget build(BuildContext context) {
    return BlocListener<OrderBloc, OrderState>(
      listener: (context, state) {
        if (state is OrderPaymentSuccess) {
          _handlePaymentSuccessState(context, state);
        }
      },
      child: PopScope(
        onPopInvokedWithResult: _handlePopInvoked,
        child: AppScaffold(
          backgroundColor: Colors.grey[100],
          body: _buildBody(),
        ),
      ),
    );
  }

  void _handlePopInvoked(bool didPop, dynamic result) {
    if (didPop) {
      context.read<OrderBloc>().add(
        OrderGetAllOrdersbyUserIdEvent(userId: widget.userId, page: 1),
      );

      if (widget.paymentStatus != PaymentStatus.paid && !_isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã ghi nhận đơn hàng và thu tiền sau'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Widget _buildBody() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(24.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: const [
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
              _buildTitle(),
              SizedBox(height: 16.h),
              _buildQrCode(),
              SizedBox(height: 24.h),
              _buildPaymentInfo(),
              SizedBox(height: 16.h),
              _buildNote(),
              SizedBox(height: 24.h),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return Text(
      "Thanh toán đơn hàng",
      style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildQrCode() {
    return Container(
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
            (_, __, ___) =>
                Icon(Icons.qr_code, size: 200.w, color: Colors.grey),
      ),
    );
  }

  Widget _buildPaymentInfo() {
    return Column(
      children: [
        _buildInfoRow("Ngân hàng", widget.paymentInfo.bankCode),
        _buildInfoRow("Số tài khoản", widget.paymentInfo.accountNumber),
        _buildInfoRow("Chủ tài khoản", widget.paymentInfo.accountName),
        _buildInfoRow("Số tiền", "${formatMoney(widget.paymentInfo.amount)} đ"),
        _buildInfoRow("Nội dung", widget.paymentInfo.content),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey[600], fontSize: 13.sp),
          ),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.sp),
          ),
        ],
      ),
    );
  }

  String formatMoney(num amount) {
    return amount
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }

  Widget _buildNote() {
    return Text(
      widget.paymentInfo.note,
      style: TextStyle(fontSize: 14.sp, color: Colors.grey[700]),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildActionButtons() {
    return BlocBuilder<OrderBloc, OrderState>(
      builder: (context, state) {
        final isLoading = state is OrderSePayWebHookLoading;
        return Row(
          children: [
            if (_isDevMode) Expanded(child: _buildDemoButton(isLoading)),
            if (_isDevMode) SizedBox(width: 8.w),
            Expanded(child: _buildCloseButton()),
          ],
        );
      },
    );
  }

  Widget _buildDemoButton(bool isLoading) {
    return SizedBox(
      height: 48.h,
      child: ElevatedButton(
        onPressed: isLoading ? null : _handleDemoPayment,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
        child: const Text("Demo Thành công"),
      ),
    );
  }

  void _handleDemoPayment() {
    _handlePaymentSuccess({"orderId": widget.orderId});
  }

  Widget _buildCloseButton() {
    return SizedBox(
      height: 48.h,
      child: ElevatedButton(
        onPressed: () => Navigator.pop(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey[200],
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
        child: const Text("Đóng"),
      ),
    );
  }
}
