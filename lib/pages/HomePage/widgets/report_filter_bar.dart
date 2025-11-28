import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../ting_box.dart';

class ReportFilterBar extends StatelessWidget {
  final String selectedFilter;
  final Function(String) onFilterChanged;

  const ReportFilterBar({
    super.key,
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final filters = ['Hôm nay', 'Hôm qua', 'Tuần này'];

    return SizedBox(
      width: double.infinity,
      child: CupertinoSlidingSegmentedControl<String>(
        backgroundColor: Colors.white,
        thumbColor: AppColors.primaryBlue,
        groupValue: selectedFilter,
        padding: EdgeInsets.all(4.w),
        children: {
          for (var filter in filters)
            filter: Padding(
              padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 8.w),
              child: Text(
                filter,
                style: TextStyle(
                  color: selectedFilter == filter ? Colors.white : Colors.grey,
                  fontWeight:
                      selectedFilter == filter
                          ? FontWeight.bold
                          : FontWeight.normal,
                  fontSize: 14.sp,
                ),
              ),
            ),
        },
        onValueChanged: (value) {
          if (value != null) {
            onFilterChanged(value);
          }
        },
      ),
    );
  }
}
