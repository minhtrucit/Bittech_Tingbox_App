import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../ting_box.dart';

class CashPaymentPage extends StatefulWidget {
  final int orderId;
  final int userId;
  final String orderCode;
  final String paymentStatus;
  final double amount;

  const CashPaymentPage({
    super.key,
    required this.orderId,
    required this.userId,
    required this.orderCode,
    required this.paymentStatus,
    required this.amount,
  });

  @override
  State<CashPaymentPage> createState() => _CashPaymentPageState();
}

class _CashPaymentPageState extends State<CashPaymentPage> {
  bool _isSuccess = false;

  @override
  Widget build(BuildContext context) {
    return BlocListener<OrderBloc, OrderState>(
      listener: (context, state) {
        if (state is OrderUpdateStatusLoading) {
          // Show progress or handled by UI
        }
        if (state is OrderUpdateStatusSuccess) {
          _isSuccess = true;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.green,
            ),
          );
          // Navigate to some result or back
          context.read<OrderBloc>().add(
            OrderGetAllOrdersbyUserIdEvent(userId: state.order.userId, page: 1),
          );
          Navigator.of(
            context,
          ).pop(); // Back to selection if needed or elsewhere
          Navigator.of(context).pop(); // Exit cash page
        }
        if (state is OrderUpdateStatusFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        }
      },
      child: PopScope(
        onPopInvokedWithResult: (didPop, result) {
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
        },
        child: Stack(
          children: [
            AppScaffold(
              backgroundColor: Colors.white,
              appBar: AppAppBar(
                title: const TitleAppbarText(title: 'Thanh toán tiền mặt'),
                leading: IconButton(
                  icon: const Icon(
                    Icons.arrow_back_outlined,
                    color: Colors.black,
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ),
              body: SafeArea(
                child: Padding(
                  padding: EdgeInsets.all(20.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(16.w),
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlue.withValues(alpha: .05),
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(
                            color: AppColors.primaryBlue.withValues(alpha: .1),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Mã đơn hàng: ${widget.orderCode}',
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: Colors.grey[700],
                              ),
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              'Số tiền cần thu:',
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              '${formatMoney(widget.amount)}đ',
                              style: TextStyle(
                                fontSize: 24.sp,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryBlue,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 32.h),
                      Text(
                        'Chọn trạng thái đơn hàng:',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 16.h),
                      BlocBuilder<OrderBloc, OrderState>(
                        builder: (context, state) {
                          final isUpdating = state is OrderUpdateStatusLoading;
                          return Column(
                            children: [
                              _buildOptionCard(
                                context: context,
                                title: 'Chờ thanh toán',
                                subtitle: 'Ghi nhận đơn hàng và thu tiền sau',
                                icon: Icons.timer_outlined,
                                color: Colors.orange,
                                onTap:
                                    isUpdating
                                        ? null
                                        : () {
                                          if (widget.paymentStatus !=
                                              PaymentStatus.unpaid) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Đơn hàng không ở trạng thái cần cập nhật',
                                                ),
                                                backgroundColor: Colors.orange,
                                              ),
                                            );
                                            return;
                                          }
                                          context.read<OrderBloc>().add(
                                            OrderGetAllOrdersbyUserIdEvent(
                                              userId: widget.userId,
                                              page: 1,
                                            ),
                                          );
                                          Navigator.pop(context);
                                        },
                              ),
                              SizedBox(height: 16.h),
                              _buildOptionCard(
                                context: context,
                                title: 'Đã thanh toán',
                                subtitle:
                                    'Xác nhận đã thu đủ tiền mặt từ khách',
                                icon:
                                    isUpdating
                                        ? Icons.hourglass_empty
                                        : Icons.check_circle_outline,
                                color: isUpdating ? Colors.grey : Colors.green,
                                onTap:
                                    isUpdating
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
                                            OrderUpdateStatusEvent(
                                              orderId: widget.orderId,
                                              status: PaymentStatus.paid,
                                            ),
                                          );
                                        },
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            BlocBuilder<OrderBloc, OrderState>(
              builder: (context, state) {
                if (state is OrderUpdateStatusLoading) {
                  return const LoadingOverlay();
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: color.withValues(alpha: .1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28.sp),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 13.sp, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16.sp, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}
