import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';

class ProductsListSkeleton extends StatelessWidget {
  const ProductsListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // Search bar skeleton
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            child: _buildShimmerBox(
              height: 48.h,
              width: double.infinity,
              borderRadius: 12.r,
            ),
          ),
          // Filter row skeleton
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Row(
              children: [
                _buildShimmerBox(height: 36.h, width: 100.w, borderRadius: 20.r),
                SizedBox(width: 8.w),
                _buildShimmerBox(height: 36.h, width: 80.w, borderRadius: 20.r),
                SizedBox(width: 8.w),
                _buildShimmerBox(height: 36.h, width: 90.w, borderRadius: 20.r),
              ],
            ),
          ),
          SizedBox(height: 16.h),
          // Product grid skeleton
          Expanded(
            child: GridView.builder(
              padding: EdgeInsets.all(16.w),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: 12.w,
                mainAxisSpacing: 12.h,
              ),
              itemCount: 8,
              itemBuilder: (context, index) {
                return _buildProductCardSkeleton();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCardSkeleton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image skeleton
          Expanded(
            child: _buildShimmerBox(
              width: double.infinity,
              height: double.infinity,
              borderRadius: 12.r,
            ),
          ),
          // Product info skeleton
          Padding(
            padding: EdgeInsets.all(12.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildShimmerBox(
                  height: 14.h,
                  width: double.infinity,
                  borderRadius: 4.r,
                ),
                SizedBox(height: 8.h),
                _buildShimmerBox(height: 12.h, width: 80.w, borderRadius: 4.r),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerBox({
    required double height,
    required double width,
    required double borderRadius,
  }) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}
