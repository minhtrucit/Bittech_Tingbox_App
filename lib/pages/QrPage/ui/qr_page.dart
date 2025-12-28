import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ting_box/models/payment_info.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ting_box/pages/ConfigPage/bloc/config_bloc.dart';
import 'package:ting_box/pages/ConfigPage/bloc/config_state.dart';

import '../../../services/websocket_manager.dart';
import '../../../services/printer_discovery_service.dart';
import '../../../ting_box.dart';

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
  static const Duration _snackBarDuration = Duration(seconds: 5);
  static const Duration _snackBarLongDuration = Duration(seconds: 8);
  static const Duration _successSnackBarDuration = Duration(seconds: 2);
  static const Duration _navigationDelay = Duration(milliseconds: 500);

  // ==================== STATE ====================
  late final WebSocketManager _webSocketManager = WebSocketManager();
  bool _isDevMode = false;
  bool _isSuccess = false;

  StreamSubscription? _discoverySubscription;

  // ==================== LIFECYCLE ====================
  @override
  void initState() {
    super.initState();
    _setupWebSocket();
    _loadUserInfo();
    _setupPrinterDiscoveryListener();

    // Only trigger discovery if printing is enabled
    final currentConfig = _getCurrentConfig(context);
    if (currentConfig?.printMode != PrintMode.none) {
      PrinterDiscoveryService().discover();
    }
  }

  @override
  void dispose() {
    _webSocketManager.off("payment.success");
    _discoverySubscription?.cancel();
    super.dispose();
  }

  void _setupPrinterDiscoveryListener() {
    _discoverySubscription = PrinterDiscoveryService().discoveryResultStream
        .listen((url) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.print, color: Colors.white, size: 20),
                    SizedBox(width: 12.w),
                    const Text('Đã kết nối máy in!'),
                  ],
                ),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        });
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
      debugPrint('Dev mode: $_isDevMode');
    }
  }

  // ==================== PRINTER LOGIC ====================
  Future<void> _handlePrint(
    BuildContext context,
    Order order,
    ConfigModel? config,
  ) async {
    final printerService = PrinterService();

    // Step 1: Check printer availability
    final printerInfo = await _checkPrinterWithLoading(context, printerService);
    if (printerInfo == null) return;

    // Step 2: Validate printer status
    if (!_validatePrinterStatus(context, printerInfo, order, config)) {
      return;
    }

    // Step 3: Print receipt
    await _printReceipt(context, printerService, order, config, printerInfo);
  }

  Future<Map<String, dynamic>?> _checkPrinterWithLoading(
    BuildContext context,
    PrinterService printerService,
  ) async {
    if (!context.mounted) return null;

    _showLoadingDialog(context, 'Đang kiểm tra máy in...');

    final printerInfo = await printerService.checkPrinterAvailability();

    if (!context.mounted) return null;
    Navigator.pop(context);

    if (printerInfo == null) {
      _showPrintAgentError(context);
      return null;
    }

    return printerInfo;
  }

  bool _validatePrinterStatus(
    BuildContext context,
    Map<String, dynamic> printerInfo,
    Order order,
    ConfigModel? config,
  ) {
    final isAvailable = printerInfo['available'] as bool? ?? false;

    if (!isAvailable) {
      final errorInfo = _analyzePrinterError(printerInfo);
      _showPrinterError(context, errorInfo, order, config);
      return false;
    }

    return true;
  }

  PrinterErrorInfo _analyzePrinterError(Map<String, dynamic> printerInfo) {
    final totalPrinters = printerInfo['totalPrinters'] as int? ?? 0;
    final onlinePrinters = printerInfo['onlinePrinters'] as int? ?? 0;
    final defaultIsOnline = printerInfo['defaultIsOnline'] as bool? ?? false;
    final defaultPrinter = printerInfo['defaultPrinter'] as String? ?? 'N/A';
    final defaultStatus = printerInfo['defaultStatus'] as String? ?? 'Unknown';

    if (totalPrinters == 0) {
      return PrinterErrorInfo(
        message:
            'Không tìm thấy máy in nào trong hệ thống.\n'
            'Vui lòng cài đặt máy in và thử lại.',
        color: Colors.red,
      );
    }

    if (onlinePrinters == 0) {
      return PrinterErrorInfo(
        message:
            'Tìm thấy $totalPrinters máy in nhưng tất cả đang offline.\n\n'
            'Máy in mặc định: "$defaultPrinter"\n'
            'Trạng thái: $defaultStatus\n\n'
            'Vui lòng kiểm tra:\n'
            '• Máy in đã bật nguồn chưa?\n'
            '• Cáp USB/mạng có kết nối không?\n'
            '• Máy in có giấy không?',
        color: Colors.orange,
      );
    }

    if (!defaultIsOnline) {
      return PrinterErrorInfo(
        message:
            'Máy in mặc định "$defaultPrinter" đang offline.\n'
            'Trạng thái: $defaultStatus\n\n'
            'Có $onlinePrinters máy in khác đang online.\n'
            'Vui lòng bật máy in "$defaultPrinter" hoặc đổi máy in mặc định.',
        color: Colors.orange,
      );
    }

    return PrinterErrorInfo(
      message: 'Không thể kết nối với máy in.\nVui lòng kiểm tra lại.',
      color: Colors.red,
    );
  }

  Future<void> _printReceipt(
    BuildContext context,
    PrinterService printerService,
    Order order,
    ConfigModel? config,
    Map<String, dynamic> printerInfo,
  ) async {
    if (!context.mounted) return;

    final defaultPrinter = printerInfo['defaultPrinter'] as String? ?? 'N/A';
    final defaultStatus = printerInfo['defaultStatus'] as String? ?? 'Unknown';

    _showPrintingDialog(context, defaultPrinter, defaultStatus);

    try {
      final success = await printerService.printReceipt(order, config: config);

      if (!context.mounted) return;
      Navigator.pop(context); // Close loading

      if (success) {
        await _handlePrintSuccess(context);
      } else {
        throw Exception('In thất bại');
      }
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context); // Close loading
      _showPrintError(context, e.toString(), order, config);
    }
  }

  Future<void> _handlePrintSuccess(BuildContext context) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8.w),
            const Text('Đã in hóa đơn thành công'),
          ],
        ),
        backgroundColor: Colors.green,
        duration: _successSnackBarDuration,
      ),
    );

    // Navigate back to sales page
    await Future.delayed(_navigationDelay);
    if (!context.mounted) return;
    Navigator.pop(context); // Close success dialog
    Navigator.pop(context); // Close QR page
  }

  // ==================== DIALOGS & SNACKBARS ====================
  void _showLoadingDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _buildLoadingDialog(message),
    );
  }

  void _showPrintingDialog(
    BuildContext context,
    String printerName,
    String status,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _buildPrintingDialog(printerName, status),
    );
  }

  void _showPrintAgentError(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            SizedBox(width: 8.w),
            const Expanded(
              child: Text(
                'Không kết nối được Print Agent. Vui lòng kiểm tra Print Agent đã chạy chưa.',
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red,
        duration: _snackBarDuration,
        action: SnackBarAction(
          label: 'Thử lại',
          textColor: Colors.white,
          onPressed: () {
            // Will be handled by retry button
          },
        ),
      ),
    );
  }

  void _showPrinterError(
    BuildContext context,
    PrinterErrorInfo errorInfo,
    Order order,
    ConfigModel? config,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.warning, color: Colors.white),
            SizedBox(width: 8.w),
            Expanded(child: Text(errorInfo.message)),
          ],
        ),
        backgroundColor: errorInfo.color,
        duration: _snackBarLongDuration,
        action: SnackBarAction(
          label: 'Thử lại',
          textColor: Colors.white,
          onPressed: () => _handlePrint(context, order, config),
        ),
      ),
    );
  }

  void _showPrintError(
    BuildContext context,
    String error,
    Order order,
    ConfigModel? config,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Lỗi in hóa đơn: $error'),
        backgroundColor: Colors.red,
        action: SnackBarAction(
          label: 'Thử lại',
          textColor: Colors.white,
          onPressed: () => _handlePrint(context, order, config),
        ),
      ),
    );
  }

  void _showSuccessDialog({
    required BuildContext dialogContext,
    required bool isManualPrint,
    required Order order,
    required ConfigModel? config,
  }) {
    showDialog(
      context: dialogContext,
      barrierDismissible: false,
      builder:
          (childContext) => _buildSuccessDialog(
            childContext,
            dialogContext,
            isManualPrint,
            order,
            config,
          ),
    );
  }

  // ==================== WIDGET BUILDERS ====================
  Widget _buildLoadingDialog(String message) {
    return Material(
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
              Text(message),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrintingDialog(String printerName, String status) {
    return Material(
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
              const Text('Đang in hóa đơn...'),
              SizedBox(height: 8.h),
              Text(
                'Máy in: $printerName',
                style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
              ),
              Text(
                'Trạng thái: $status',
                style: TextStyle(
                  fontSize: 11.sp,
                  color: Colors.green,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessDialog(
    BuildContext childContext,
    BuildContext dialogContext,
    bool isManualPrint,
    Order order,
    ConfigModel? config,
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
            if (isManualPrint) _buildPrintButton(dialogContext, order, config),
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

  Widget _buildPrintButton(
    BuildContext dialogContext,
    Order order,
    ConfigModel? config,
  ) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => _handlePrint(dialogContext, order, config),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2962FF),
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

  ConfigModel? _getCurrentConfig(BuildContext context) {
    final configState = context.read<ConfigBloc>().state;

    if (configState is ConfigLoaded) {
      return configState.config;
    } else if (configState is ConfigUpdateSuccess) {
      return configState.config;
    } else if (configState is ConfigCreateSuccess) {
      return configState.config;
    }

    return null;
  }

  void _handlePaymentSuccessState(
    BuildContext context,
    OrderPaymentSuccess state,
  ) {
    _isSuccess = true;
    final currentConfig = _getCurrentConfig(context);
    final order = state.order;

    if (order != null) {
      _showSuccessDialog(
        dialogContext: context,
        isManualPrint: currentConfig?.printMode == PrintMode.manual,
        order: order,
        config: currentConfig,
      );
    } else {
      debugPrint('⚠️ Order is null in OrderPaymentSuccess state');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lỗi: Không tìm thấy thông tin đơn hàng'),
          backgroundColor: Colors.orange,
        ),
      );
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
        child: Stack(
          children: [
            AppScaffold(backgroundColor: Colors.grey[100], body: _buildBody()),
            _buildDiscoveryOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildDiscoveryOverlay() {
    // Don't show overlay if printing is disabled
    final currentConfig = _getCurrentConfig(context);
    if (currentConfig?.printMode == PrintMode.none)
      return const SizedBox.shrink();

    return StreamBuilder<bool>(
      stream: PrinterDiscoveryService().discoveryStatusStream,
      builder: (context, snapshot) {
        final isScanning = snapshot.data ?? false;
        if (!isScanning) return const SizedBox.shrink();

        return Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 16.w),
              color: Colors.blue.withValues(alpha: 0.9),
              child: SafeArea(
                bottom: false,
                child: Row(
                  children: [
                    SizedBox(
                      width: 16.w,
                      height: 16.w,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Text(
                        'Đang tìm máy in trong mạng...',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
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
          spacing: 8.w,
          children: [
            if (_isDevMode) _buildDemoButton(isLoading),
            _buildCloseButton(),
          ],
        );
      },
    );
  }

  Widget _buildDemoButton(bool isLoading) {
    return Expanded(
      child: SizedBox(
        height: 48.h,
        child: AppTextButton(
          onPressed: isLoading ? null : _handleDemoPayment,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.1),
            foregroundColor: AppColors.primaryBlue,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
          ),
          label:
              isLoading
                  ? SizedBox(
                    width: 20.w,
                    height: 20.w,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primaryBlue,
                    ),
                  )
                  : Text(
                    'Demo thanh toán',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryBlue,
                    ),
                  ),
        ),
      ),
    );
  }

  void _handleDemoPayment() {
    if (widget.paymentStatus != PaymentStatus.unpaid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đơn hàng đã được thanh toán rồi'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    context.read<OrderBloc>().add(
      OrderSePayWebHookEvent(
        orderId: widget.orderId,
        orderCode: widget.orderCode,
        transferAmount: widget.paymentInfo.amount.toInt(),
        transactionDate: DateTime.now().toString(),
        paymentInfo: widget.paymentInfo,
      ),
    );
  }

  Widget _buildCloseButton() {
    return Expanded(
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

// ==================== HELPER CLASSES ====================
class PrinterErrorInfo {
  final String message;
  final Color color;

  PrinterErrorInfo({required this.message, required this.color});
}
