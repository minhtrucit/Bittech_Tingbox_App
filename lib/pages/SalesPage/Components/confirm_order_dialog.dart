
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../ting_box.dart';

enum PaymentMethod { BANK_TRANSFER, CASH }

class ConfirmOrderDialog extends StatefulWidget {
  final List<Product> items;
  final VoidCallback onComplete;
  final BuildContext parentContext;

  const ConfirmOrderDialog({
    Key? key,
    required this.items,
    required this.parentContext,
    required this.onComplete,
  }) : super(key: key);

  @override
  State<ConfirmOrderDialog> createState() => _ConfirmOrderDialogState();
}

class _ConfirmOrderDialogState extends State<ConfirmOrderDialog> {
  String _selectedPaymentMethod = PaymentMethod.BANK_TRANSFER.toString();

  void onCreateOrder(BuildContext context, String paymentMethod) {
    final order = Order(
      userId: 1,
      distributorId: 2,
      customerName: "Trần Lâm Huy",
      customerPhone: "0901234567",
      customerEmail: "tlhuy02@gmail.com",
      shippingAddress: "123 Lê Lợi, Phường Bến Thành, Quận 1, TP. Hồ Chí Minh",
      discount: 0,
      paymentMethod: paymentMethod,
      note: "Giao giờ hành chính, vui lòng gọi trước khi giao.",
      items:
          widget.items
              .map(
                (p) => OrderItem(
                  productId: p.id,
                  quantity: p.quantity,
                  unitPrice: p.price,
                ),
              )
              .toList(),
    );

    context.read<OrderBloc>().add(OrderCreateOrderEvent(order: order));

    debugPrint("📝 Order submitted: ${order.toJson()}");
  }

  double get totalPrice =>
      widget.items.fold(0, (sum, item) => sum + item.price * item.quantity);

  bool isShowOverlay = false;

  @override
  Widget build(BuildContext context) {
    return BlocListener<OrderBloc, OrderState>(
      listener: (childContext, state) {
        if (state is OrderLoading) {
          setState(() {
            isShowOverlay = true;
          });
        }

        if (state is OrderCreateSuccess) {
          setState(() {
            isShowOverlay = false;
          });
          Navigator.pop(context);
          final paymentInfo = state.paymentInfo;

          if (state.paymentMethod == PaymentMethod.BANK_TRANSFER) {
            Future.delayed(Duration(seconds: 1), () {
              Navigator.push(
                widget.parentContext,
                MaterialPageRoute(
                  builder: (_) => QrPage(paymentInfo: paymentInfo!),
                ),
              );
            });
          } else {
            // Todo handle for cash method
          }
        }

        if (state is OrderFailure) {
          setState(() {
            isShowOverlay = false;
          });
          DialogUtils.showAppDialog(
            context: context,
            title: 'Lỗi khi tạo đơn hàng',
            content: state.message,
            onFirstAction: () {
              Navigator.pop(context);
            },
            firstActionText: 'OK',
          );
        }
      },
      child: Stack(
        children: [
          AppScaffold(
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
                      Flexible(
                        child: Row(
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
                              icon: Icon(
                                Icons.close,
                                size: 20,
                                color: Colors.grey,
                              ),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
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

                      PaymentOptionSelector(
                        onPaymentSelected: (method) {
                          setState(() {
                            _selectedPaymentMethod =
                                method == "transfer" ? "BANK_TRANSFER" : "CASH";
                          });
                        },
                      ),
                      SizedBox(height: 24.h),

                      buildCheckoutButton(context),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (isShowOverlay) LoadingOverlay(),
        ],
      ),
    );
  }

  SizedBox buildItemList() {
    return SizedBox(
      height: 150.h,
      child: SingleChildScrollView(
        child: Column(
          children: [
            ...widget.items
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
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  "Số lượng: ${item.quantity}",
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          ),
                          Text("${formatMoney(item.price * item.quantity)}đ"),
                        ],
                      ),
                      SizedBox(height: 16.h),
                    ],
                  ),
                )
                .toList(),
          ],
        ),
      ),
    );
  }

  Widget buildCheckoutButton(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 36.h),
      child: SizedBox(
        width: double.infinity,
        child: AppTextButton(
          style: ButtonStyle(
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            backgroundColor: WidgetStatePropertyAll(AppColors.primaryBlue),
            textStyle: WidgetStatePropertyAll(
              Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          onPressed: () {
            onCreateOrder(context, _selectedPaymentMethod);
          },
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
