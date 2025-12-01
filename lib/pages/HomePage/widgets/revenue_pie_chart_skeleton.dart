import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';

class RevenuePieChartSkeleton extends StatelessWidget {
  const RevenuePieChartSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Column(
          children: [
            // Circle Chart Skeleton
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  height: 160.h,
                  width: 160.h,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 30.w),
                  ),
                ),
                // Center text skeleton
                Column(
                  children: [
                    Container(width: 60.w, height: 12.sp, color: Colors.white),
                    SizedBox(height: 4.h),
                    Container(width: 100.w, height: 20.sp, color: Colors.white),
                  ],
                ),
              ],
            ),
            SizedBox(height: 20.h),
            // Legend Items Skeleton
            ...List.generate(
              3,
              (index) => Padding(
                padding: EdgeInsets.only(bottom: 10.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 10.w,
                          height: 14.w,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Container(
                          width: 80.w,
                          height: 18.sp,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      width: 60.w,
                      height: 18.sp,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
