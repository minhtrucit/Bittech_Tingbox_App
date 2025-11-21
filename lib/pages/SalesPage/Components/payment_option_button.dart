import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../ting_box.dart';

class PaymentOptionSelector extends StatefulWidget {
  const PaymentOptionSelector({super.key});

  @override
  State<PaymentOptionSelector> createState() => _PaymentOptionSelectorState();
}

class _PaymentOptionSelectorState extends State<PaymentOptionSelector> {
  String selectedPayment = "transfer";

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: PaymentOptionButton(
            label: "Chuyển khoản",
            icon: Icons.account_balance_outlined,
            selected: selectedPayment == "transfer",
            onTap: () {
              setState(() {
                selectedPayment = "transfer";
              });
            },
          ),
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: PaymentOptionButton(
            label: "Tiền mặt",
            icon: Icons.payment,
            selected: selectedPayment == "cash",
            onTap: () {
              setState(() {
                selectedPayment = "cash";
              });
            },
          ),
        ),
      ],
    );
  }
}

class PaymentOptionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final double height;

  const PaymentOptionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.height = 42,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height.h,
      child: AppTextButton(
        onPressed: onTap,
        style: ButtonStyle(
          padding: WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 12.w), // hạn chế padding
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: selected
                  ? BorderSide.none
                  : BorderSide(width: 1.w, color: Colors.grey.shade300),
            ),
          ),
          backgroundColor: WidgetStatePropertyAll(
            selected ? AppColors.primaryBlue : AppColors.white,
          ),
          textStyle: WidgetStatePropertyAll(
            Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: selected ? Colors.white : AppColors.primaryBlue,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20.sp,
              color: selected ? Colors.white : AppColors.primaryBlue,
            ),
            SizedBox(width: 4.w),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: selected ? Colors.white : AppColors.primaryBlue,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

