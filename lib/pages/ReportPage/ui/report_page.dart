import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ting_box/extension/date_time_extension.dart';

import '../../../ting_box.dart';

class ReportPage extends StatefulWidget {
  const ReportPage({super.key});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage>
    with AutomaticKeepAliveClientMixin {
  StatisticOrder? statistic;
  Revenue? revenue;
  bool isLoading = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // Check if we need to load data
    final currentState = context.read<OrderBloc>().state;
    if (currentState is! OrderGetStatisticSuccess) {
      context.read<OrderBloc>().add(OrderGetStatisticsEvent());
    } else {
      // If already loaded, sync local state
      statistic = currentState.statistic;
      revenue = statistic?.revenue;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return BlocListener<OrderBloc, OrderState>(
      listenWhen: (prev, curr) {
        // Ignore loading if we already have data to prevent skeleton flicker from other tabs
        if (statistic != null && curr is OrderLoading) return false;

        return curr is OrderGetStatisticSuccess ||
            curr is OrderLoading ||
            curr is OrderFailure;
      },
      listener: (context, state) {
        if (state is OrderLoading) {
          setState(() => isLoading = true);
        }

        if (state is OrderGetStatisticSuccess) {
          setState(() {
            isLoading = false;
            statistic = state.statistic;
            revenue = statistic?.revenue;
          });
        }

        if (state is OrderFailure) {
          setState(() => isLoading = false);
        }
      },
      child: AppScaffold(
        hasSafeArea: false,
        backgroundColor: Color(0xFFF4F7FC),
        appBar: AppAppBar(title: TitleAppbarText(title: "Quản Lý Quỹ")),
        body: Builder(
          builder: (context) {
            if (isLoading && statistic == null) {
              return const ReportPageSkeleton();
            }

            if (statistic != null && revenue != null) {
              return SafeArea(
                child: SingleChildScrollView(
                  physics: BouncingScrollPhysics(),
                  padding: EdgeInsets.all(16.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildRevenueSection(revenue!),
                      SizedBox(height: 20.h),
                      _buildExpenseSection(),
                      SizedBox(height: 20.h),
                      _buildRecentTransactionsSection(statistic!),
                    ],
                  ),
                ),
              );
            }

            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Không có dữ liệu"),
                  SizedBox(height: 16.h),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      context.read<OrderBloc>().add(OrderGetStatisticsEvent());
                    },
                    child: const Text(
                      "Tải lại",
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // -------------------------------
  // SECTION: Tổng Thu
  // -------------------------------
  Widget _buildRevenueSection(Revenue revenue) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Tổng Thu",
            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 8.h),
          Text(
            "${formatMoney(revenue.total.amount)}đ",
            style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16.h),
          _buildIconRow(
            Icons.money,
            "Tiền mặt từ đơn hàng",
            formatMoney(revenue.cash.amount),
          ),
          SizedBox(height: 12.h),
          _buildIconRow(
            Icons.account_balance,
            "Chuyển khoản từ đơn hàng",
            formatMoney(revenue.bankTransfer.amount),
          ),
        ],
      ),
    );
  }

  // Một hàng nhỏ có icon + label + số tiền
  Widget _buildIconRow(IconData icon, String title, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.green, size: 20),
        SizedBox(width: 8.w),
        Expanded(child: Text(title)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }

  // -------------------------------
  // SECTION: Tổng Chi (tạm = 0)
  // -------------------------------
  Widget _buildExpenseSection() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Tổng Chi",
            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 8.h),
          Text(
            "-0đ",
            style: TextStyle(
              fontSize: 20.sp,
              color: Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16.h),
          _buildExpenseRow("Chi trả nhà cung cấp", '-0'),
          SizedBox(height: 12.h),
          _buildExpenseRow("Chi phí vận hành", '-0'),
          SizedBox(height: 12.h),
          _buildExpenseRow("Chi phí khác", '-0'),
        ],
      ),
    );
  }

  Widget _buildExpenseRow(String title, String value) {
    return Row(
      children: [
        Icon(Icons.circle, color: Colors.redAccent, size: 12),
        SizedBox(width: 8.w),
        Expanded(child: Text(title)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }

  // -------------------------------
  // SECTION: Giao Dịch Gần Đây
  // -------------------------------
  Widget _buildRecentTransactionsSection(StatisticOrder statistic) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                "Giao dịch gần đây",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
            Text(
              "Xem tất cả",
              style: TextStyle(color: Colors.blue, fontSize: 14.sp),
            ),
          ],
        ),
        SizedBox(height: 12.h),

        // Danh sách đơn hàng gần đây
        ...statistic.recentOrders.map(_buildTransactionItem),
      ],
    );
  }

  Widget _buildTransactionItem(Order order) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6),
        ],
      ),
      child: Row(
        children: [
          // Icon cố định: xanh + arrow_downward
          Icon(Icons.arrow_downward, color: Colors.green, size: 22),
          SizedBox(width: 12.w),

          // Thông tin giao dịch
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tổng tiền
                Text(
                  "${formatMoney(order.totalAmount ?? 0)}đ",
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15.sp,
                  ),
                ),
                SizedBox(height: 4.h),

                // Phương thức thanh toán
                Text(
                  order.paymentMethod,
                  style: TextStyle(fontSize: 13.sp, color: Colors.blueGrey),
                ),

                SizedBox(height: 4.h),

                // Thời gian tạo
                Text(
                  '${order.createdAt?.toReadableDateTime()}',
                  style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
