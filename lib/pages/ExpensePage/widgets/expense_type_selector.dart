import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../ting_box.dart';

class ExpenseTypeSelector extends StatelessWidget {
  final String selectedType;
  final ValueChanged<String> onTypeChanged;

  const ExpenseTypeSelector({
    super.key,
    required this.selectedType,
    required this.onTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Nguồn tiền',
          style: TextStyle(
            fontSize: 14.sp,
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 8.h),
        Row(
          children: [
            Expanded(child: _buildTypeButton(label: 'Tiền mặt', type: 'cash')),
            SizedBox(width: 12.w),
            Expanded(child: _buildTypeButton(label: 'Ngân hàng', type: 'bank')),
          ],
        ),
      ],
    );
  }

  Widget _buildTypeButton({required String label, required String type}) {
    final isSelected = selectedType == type;
    return GestureDetector(
      onTap: () => onTypeChanged(type),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryBlue : Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isSelected ? AppColors.primaryBlue : Colors.grey[300]!,
            width: 1.5,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : Colors.grey[700],
            ),
          ),
        ),
      ),
    );
  }
}
