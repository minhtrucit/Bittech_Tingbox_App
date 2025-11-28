import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';

class ReportPageSkeleton extends StatelessWidget {
  const ReportPageSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(top: 12.h, bottom: 64.h),

        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCardShimmer(height: 120.h),
              SizedBox(height: 20.h),
              _buildCardShimmer(height: 120.h),
              SizedBox(height: 20.h),
              _buildListShimmer(),
            ],
          ),
        ),
      ),
    );
  }

  // -------------------------
  // Card shimmer (Tổng thu, Tổng chi)
  // -------------------------
  Widget _buildCardShimmer({required double height}) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        height: height,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
        ),
      ),
    );
  }

  // -------------------------
  // Danh sách giao dịch gần đây (mỗi item shimmer)
  // -------------------------
  Widget _buildListShimmer() {
    return Column(
      children: List.generate(5, (index) => _buildItemShimmer()),
    );
  }

  Widget _buildItemShimmer() {
    return Padding(
      padding: EdgeInsets.only(bottom: 14.h),
      child: Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: Container(
          height: 60.h,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
      ),
    );
  }
}
