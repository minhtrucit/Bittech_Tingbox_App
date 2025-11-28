import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ting_box/common/app_colors.dart';
import 'package:ting_box/utils/currency_input_formatter.dart';

class ExpenseAmountField extends StatelessWidget {
  final TextEditingController controller;
  final bool hasError;
  final ValueChanged<String>? onChanged;

  const ExpenseAmountField({
    super.key,
    required this.controller,
    this.hasError = false,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Số tiền chi',
          style: TextStyle(
            fontSize: 14.sp,
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 8.h),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: hasError ? Colors.red : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            inputFormatters: [CurrencyInputFormatter()],
            style: TextStyle(
              fontSize: 28.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
            onChanged: onChanged,
            decoration: InputDecoration(
              hintText: '0',
              hintStyle: TextStyle(
                fontSize: 28.sp,
                fontWeight: FontWeight.w600,
                color: Colors.grey[400],
              ),
              suffixText: 'VND',
              suffixStyle: TextStyle(fontSize: 16.sp, color: Colors.grey[400]),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(color: AppColors.primaryBlue),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 20.w,
                vertical: 16.h,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
