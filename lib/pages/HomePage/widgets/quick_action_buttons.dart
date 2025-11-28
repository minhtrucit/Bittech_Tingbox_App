import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../ting_box.dart';

class QuickActionButtons extends StatelessWidget {
  const QuickActionButtons({super.key, required this.configId});

  final int configId;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildActionButton(
          icon: Icons.bar_chart_rounded,
          label: 'Thống kê',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ReportPage()),
            );
          },
        ),
        SizedBox(width: 12.w),
        _buildActionButton(
          icon: Icons.account_balance_wallet_outlined,
          label: 'Nhập thu',
          onTap: () {
            // Get yesterday's statistic from StatisticsBloc
            final statisticsState = context.read<StatisticsBloc>().state;
            Statistic? yesterdayStatistic;

            if (statisticsState is StatisticsLoaded) {
              yesterdayStatistic = statisticsState.statistic;
            }

            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) =>
                        StartingBalancePage(configId: configId),
              ),
            );
          },
        ),
        SizedBox(width: 12.w),
        _buildActionButton(
          icon: Icons.receipt_long_rounded,
          label: 'Nhập chi',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ExpensePage()),
            );
          },
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 100.h,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(5),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withAlpha(10),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: AppColors.primaryBlue, size: 24.sp),
              ),
              SizedBox(height: 8.h),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
