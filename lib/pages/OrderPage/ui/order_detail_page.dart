import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ting_box/extension/date_time_extension.dart';
import 'package:ting_box/models/payment_info.dart';
import 'package:ting_box/services/websocket_manager.dart';
import 'package:ting_box/pages/ConfigPage/bloc/config_bloc.dart';
import 'package:ting_box/pages/ConfigPage/bloc/config_state.dart';
import '../../../ting_box.dart';
import '../../../common/constants.dart';

class OrderDetailPage extends StatefulWidget {
  final Order order;

  const OrderDetailPage({super.key, required this.order});

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  late Order _currentOrder;

  @override
  void initState() {
    super.initState();
    _currentOrder = widget.order;
  }

  void handleGenerateQRCode() {
    context.read<OrderBloc>().add(
      OrderGenerateQRCodeEvent(orderId: _currentOrder.id.toString()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<OrderBloc, OrderState>(
      listener: (context, state) {
        if (state is OrderGenerateQRCodeSuccess && state.paymentInfo != null) {
          _showQrBottomSheet(context, state.paymentInfo!);
        } else if (state is OrderPaymentSuccess) {
          setState(() {
            if (state.order != null) {
              _currentOrder = state.order!;
            } else {
              _currentOrder.paymentStatus = PaymentStatus.paid;
              _currentOrder.paidAmount = _currentOrder.totalAmount ?? 0;
            }
          });
        } else if (state is OrderUpdateStatusSuccess) {
          setState(() {
            _currentOrder = state.order;
          });
        }
      },
      child: AppScaffold(
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
        bottomNavigationBar: _buildBottomButton(context, _currentOrder),
      ),
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
    final orderId = '#${_currentOrder.code}-${_currentOrder.id}';
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
                    _currentOrder.paymentStatus == PaymentStatus.unpaid
                        ? Colors.orange.withValues(alpha: 0.1)
                        : Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Text(
                _currentOrder.paymentStatus == PaymentStatus.unpaid
                    ? 'Chưa thanh toán'
                    : 'Đã thanh toán',
                style: TextStyle(
                  fontSize: 13.sp,
                  color:
                      _currentOrder.paymentStatus == PaymentStatus.unpaid
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
          _buildInfoRow(
            'Ngày đặt hàng',
            _formatOrderDate(_currentOrder.createdAt),
          ),
          SizedBox(height: 12.h),

          // Payment Method
          _buildInfoRow(
            'Phương thức thanh toán',
            _translatePaymentMethod(_currentOrder.paymentMethod),
          ),
        ],
      ),
    );
  }

  String _translatePaymentMethod(String method) {
    switch (method.toUpperCase()) {
      case 'CASH':
        return 'Tiền mặt';
      case 'BANK_TRANSFER':
        return 'Chuyển khoản';
      default:
        return method;
    }
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
          ..._currentOrder.items.map((item) => _buildProductItem(item)),
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
    final subtotal = _currentOrder.subtotal ?? 0;
    final discount = _currentOrder.discount;
    final vat = _currentOrder.vat;
    final paidAmount = _currentOrder.paidAmount;
    final total = _currentOrder.totalAmount ?? 0;
    final remaining = total - paidAmount; // Số tiền còn thiếu
    final change = paidAmount - total; // Số tiền thừa

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
            remaining > 0 ? 'Còn lại' : 'Tiền thừa',
            '${formatMoney(remaining > 0 ? remaining : (change > 0 ? change : 0))}đ',
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

  Widget _buildBottomButton(BuildContext context, Order order) {
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
                  onPressed: () async {
                    // Lấy config hiện tại
                    final configState = context.read<ConfigBloc>().state;
                    ConfigModel? currentConfig;

                    if (configState is ConfigLoaded) {
                      currentConfig = configState.config;
                    } else if (configState is ConfigUpdateSuccess) {
                      currentConfig = configState.config;
                    } else if (configState is ConfigCreateSuccess) {
                      currentConfig = configState.config;
                    }

                    // Mở preview hóa đơn
                    await PrintHelper.openPreviewFromDetail(
                      context,
                      order: order,
                      config: currentConfig,
                    );
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
            if (order.paymentStatus != PaymentStatus.paid)
              Expanded(
                child: SizedBox(
                  height: 48.h,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (order.paymentMethod.toUpperCase() == 'CASH') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) => CashPaymentPage(
                                  orderId: order.id ?? 0,
                                  userId: order.userId,
                                  orderCode: order.code ?? '',
                                  paymentStatus:
                                      order.paymentStatus ?? 'unpaid',
                                  amount: order.totalAmount ?? 0,
                                ),
                          ),
                        );
                      } else {
                        context.read<OrderBloc>().add(
                          OrderGenerateQRCodeEvent(
                            orderId: order.id.toString(),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    icon: Icon(
                      order.paymentMethod.toUpperCase() == 'CASH'
                          ? Icons.payments_outlined
                          : Icons.qr_code,
                      color: Colors.white,
                    ),
                    label: Text(
                      order.paymentMethod.toUpperCase() == 'CASH'
                          ? 'Thanh toán'
                          : 'Tạo mã QR',
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

  void _showQrBottomSheet(BuildContext context, PaymentInfo paymentInfo) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            height: MediaQuery.of(context).size.height * 0.85,
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).systemGestureInsets.bottom),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
            ),
            child: _QrSheetContent(
              paymentInfo: paymentInfo,
              orderCode: _currentOrder.code ?? _currentOrder.id.toString(),
              createdAt: _currentOrder.createdAt,
              orderId: _currentOrder.id ?? 0,
              paymentStatus:
                  _currentOrder.paymentStatus ?? PaymentStatus.unpaid,
              userId: _currentOrder.userId,
            ),
          ),
    );
  }
}

class _QrSheetContent extends StatefulWidget {
  final PaymentInfo paymentInfo;
  final String orderCode;
  final String? createdAt;
  final int orderId;
  final String paymentStatus;
  final int userId;

  const _QrSheetContent({
    required this.paymentInfo,
    required this.orderCode,
    this.createdAt,
    required this.orderId,
    required this.paymentStatus,
    required this.userId,
  });

  @override
  State<_QrSheetContent> createState() => _QrSheetContentState();
}

class _QrSheetContentState extends State<_QrSheetContent> {
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
    if (user != null) {
      isDevMode = user.isDevMode ?? false;
      if (mounted) setState(() {});
    }
  }

  @override
  void dispose() {
    webSocketManager.off("payment.success");
    super.dispose();
  }

  void showSuccessDialog({required bool isManualPrint}) {
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
                  Container(
                    width: 64.w,
                    height: 64.w,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check,
                      color: const Color(0xFF4CAF50),
                      size: 32.w,
                    ),
                  ),
                  SizedBox(height: 16.h),
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
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context); // Close dialog
                          Navigator.pop(context); // Close bottom sheet
                        },
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
                  SizedBox(height: 12.h),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context); // Close dialog
                        Navigator.pop(context); // Close bottom sheet
                        Navigator.pop(context); // Close bottom sheet
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
            isManualPrint: currentConfig?.printMode == PrintMode.manual,
          );
        } else if (state is OrderSePayWebHookFailed) {
          DialogUtils.showAppDialog(
            context: context,
            title: "Lỗi",
            content: state.message,
            firstActionText: "Đóng",
            onFirstAction: () {
              Navigator.pop(context);
            },
          );
        }
      },
      child: PopScope(
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) {
            context.read<OrderBloc>().add(
              OrderGetAllOrdersbyUserIdEvent(userId: widget.userId, page: 1),
            );
          }
        },
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 8.h),
              Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              SizedBox(height: 24.h),
              Text(
                "Thanh toán đơn hàng",
                style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16.h),
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
                      (_, __, ___) =>
                          Icon(Icons.qr_code, size: 200.w, color: Colors.grey),
                ),
              ),
              SizedBox(height: 24.h),
              _buildInfoRow("Ngân hàng", widget.paymentInfo.bankCode),
              _buildInfoRow("Số tài khoản", widget.paymentInfo.accountNumber),
              _buildInfoRow("Chủ tài khoản", widget.paymentInfo.accountName),
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
              Spacer(),
              BlocBuilder<OrderBloc, OrderState>(
                builder: (context, state) {
                  final isProcessing = state is OrderSePayWebHookLoading;
                  return Row(
                    children: [
                      if (isDevMode) ...[
                        Expanded(
                          child: SizedBox(
                            height: 48.h,
                            child: AppTextButton(
                              onPressed:
                                  isProcessing
                                      ? null
                                      : () {
                                        if (widget.paymentStatus !=
                                            PaymentStatus.unpaid) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Đơn hàng đã được thanh toán rồi',
                                              ),
                                              backgroundColor: Colors.orange,
                                            ),
                                          );
                                          return;
                                        }

                                        context.read<OrderBloc>().add(
                                          OrderSePayWebHookEvent(
                                            orderId: widget.orderId,
                                            orderCode: widget.orderCode,
                                            transferAmount:
                                                widget.paymentInfo.amount
                                                    .toInt(),
                                            transactionDate:
                                                widget.createdAt
                                                    ?.toReadableDateTime() ??
                                                DateTime.now().toString(),
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
                              label:
                                  isProcessing
                                      ? SizedBox(
                                        width: 20.w,
                                        height: 20.w,
                                        child: const CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: AppColors.primaryBlue,
                                        ),
                                      )
                                      : Text(
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
                        SizedBox(width: 12.w),
                      ],
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            context.read<OrderBloc>().add(
                              OrderGetAllOrdersbyUserIdEvent(
                                userId: widget.userId,
                                page: 1,
                              ),
                            );
                          },
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
                  );
                },
              ),
              SizedBox(height: 16.h),
            ],
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
