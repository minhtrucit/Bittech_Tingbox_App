import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../ting_box.dart';

class ConfirmOrderDialog extends StatelessWidget {
  final List<Product> items;
  final VoidCallback onComplete;

  const ConfirmOrderDialog({
    Key? key,
    required this.items,
    required this.onComplete,
  }) : super(key: key);

  double get totalPrice =>
      items.fold(0, (sum, item) => sum + item.price * item.quantity);

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Container(
            height: 550.h,
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(12.r),
                bottom: Radius.circular(12.r),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Xác nhận đơn hàng',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, size: 20, color: Colors.grey),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),
                buildItemList(),

                Divider(),
                SizedBox(height: 16.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Tạm tính"),
                    Text("${formatMoney(totalPrice)}đ"),
                  ],
                ),
                SizedBox(height: 12.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Tổng cộng",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18.sp,
                      ),
                    ),
                    Text(
                      "${formatMoney(totalPrice)}đ",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryBlue,
                        fontSize: 18.sp,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 24.h),
                const Text("Phương thức thanh toán"),
                // Buttons
                SizedBox(height: 16.h),

                PaymentOptionSelector(),
                SizedBox(height: 24.h),

                buildCheckoutButton(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  SizedBox buildItemList() {
    return SizedBox(
                height: 150.h,
                child: SingleChildScrollView(
                  child: Column(
                    children: [...items
                        .map(
                          (item) => Column(
                            children: [
                              Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      'https://picsum.photos/200/300',
                                      width: 50,
                                      height: 50,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        Text(
                                          "Số lượng: ${item.quantity}",
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    "${formatMoney(item.price * item.quantity)}đ",
                                  ),
                                ],
                              ),
                              SizedBox(height: 16.h),
                            ],
                          ),
                    )
                        .toList(),],
                  ),
                ),
              );
  }

  Widget buildCheckoutButton(BuildContext context) {
    return Padding(
      padding:  EdgeInsets.only(top: 36.h),
      child: SizedBox(
        width: double.infinity,
        child: AppTextButton(
          style: ButtonStyle(
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            backgroundColor: WidgetStatePropertyAll(AppColors.primaryBlue),
            textStyle: WidgetStatePropertyAll(
              Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          onPressed: (){},
          label: Text(
            "Thanh Toán",
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
