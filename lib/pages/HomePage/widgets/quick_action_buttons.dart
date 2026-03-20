import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ting_box/pages/TableManagementPage/table_management_page.dart';
import '../../../ting_box.dart';

class QuickActionButtons extends StatelessWidget {
  const QuickActionButtons({
    super.key,
    required this.configId,
    this.onRefresh,
    this.plan = SubscriptionPlan.fnb,
    this.isTable = false,
    this.isAdmin = false,
  });

  final int configId;
  final VoidCallback? onRefresh;
  final SubscriptionPlan plan;
  final bool isTable;
  final bool isAdmin;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          // Common action: Table Management (Only for FnB if isTable is true)
          if (plan == SubscriptionPlan.fnb && isTable) ...[
            _buildActionButton(
              context,
              icon: Icons.grid_view_rounded,
              label: 'Quản lý bàn',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TableManagementPage(),
                  ),
                ).then((_) => onRefresh?.call());
              },
            ),
            SizedBox(width: 12.w),
          ],

          if (isAdmin) ...[
            _buildActionButton(
              context,
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
              context,
              icon: Icons.account_balance_wallet_outlined,
              label: 'Phiếu thu',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => StartingBalancePage(configId: configId),
                  ),
                ).then((_) => onRefresh?.call());
              },
            ),
            SizedBox(width: 12.w),
            _buildActionButton(
              context,
              icon: Icons.receipt_long_rounded,
              label: 'Phiếu chi',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ExpensePage()),
                ).then((_) => onRefresh?.call());
              },
            ),
            if (plan != SubscriptionPlan.basic) ...[
              SizedBox(width: 12.w),
              _buildActionButton(
                context,
                icon: Icons.inventory_2_outlined,
                label: 'Sản phẩm',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProductsListPage(),
                    ),
                  ).then((_) => onRefresh?.call());
                },
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 100.h,
        width: (MediaQuery.of(context).size.width - 32.w - 24.w) / 3,
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
    );
  }
}
