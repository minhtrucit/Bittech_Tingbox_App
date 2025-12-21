import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../ting_box.dart';

class QuickActionButtons extends StatelessWidget {
  const QuickActionButtons({super.key, required this.configId, this.onRefresh});

  final int configId;
  final VoidCallback? onRefresh;

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
            ).then((_) => onRefresh?.call());
          },
        ),
        SizedBox(width: 12.w),
        _buildActionButton(
          icon: Icons.account_balance_wallet_outlined,
          label: 'Tạo phiếu thu',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => StartingBalancePage(configId: configId),
              ),
            ).then((_) => onRefresh?.call());
          },
        ),
        SizedBox(width: 12.w),
        _buildActionButton(
          icon: Icons.receipt_long_rounded,
          label: 'Tạo phiếu chi',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ExpensePage()),
            ).then((_) => onRefresh?.call());
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
