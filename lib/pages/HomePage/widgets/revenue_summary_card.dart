import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ting_box/ting_box.dart';

class RevenueSummaryCard extends StatelessWidget {
  final StatisticRevenue? revenue;

  const RevenueSummaryCard({super.key, this.revenue});

  @override
  Widget build(BuildContext context) {
    // Default values if revenue is null
    final total = revenue?.total ?? 0;
    final difference = revenue?.difference ?? 0;
    final isPositive = difference >= 0;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: const Color(
          0xFFF0F4FF,
        ), // Light blue background as seen in image
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tổng Doanh Thu',
                style: TextStyle(color: Colors.grey[600], fontSize: 14.sp),
              ),
              // We can remove the static date or pass it in if needed
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            total.formatMoney(),
            style: TextStyle(
              color: AppColors.primaryBlue,
              fontSize: 32.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            '${isPositive ? '+' : ''}${difference.formatMoney()} so với kỳ trước',
            style: TextStyle(
              color: isPositive ? Colors.green : Colors.red,
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
