import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'bloc/table_bloc.dart';
import 'bloc/table_event.dart';
import 'bloc/table_state.dart';
import 'package:ting_box/ting_box.dart';
import '../../../models/table_model.dart';

class TableOrderDetailPage extends StatefulWidget {
  final TableModel table;
  final Order initialOrder;

  const TableOrderDetailPage({
    super.key,
    required this.table,
    required this.initialOrder,
  });

  @override
  State<TableOrderDetailPage> createState() => _TableOrderDetailPageState();
}

class _TableOrderDetailPageState extends State<TableOrderDetailPage> {
  late Order _currentOrder;
  bool _canManageOrders = false;
  int? _roleId;

  @override
  void initState() {
    super.initState();
    _currentOrder = widget.initialOrder;
    _loadUserPermissions();
  }

  Future<void> _loadUserPermissions() async {
    final user = await UserRepository.getUser();
    if (mounted) {
      setState(() {
        _canManageOrders = user?.canManageOrders ?? false;
        _roleId = user?.roleId;
      });
    }
  }

  void _removeItem(int index) {
    if (!_canManageOrders || _roleId == 6) return;
    final item = _currentOrder.items[index];
    _showVoidDialog(item, index);
  }

  void _showVoidDialog(OrderItem item, int index) {
    int voidQuantity = 1;
    final reasonController = TextEditingController(
      text: 'Khách yêu cầu hủy món',
    );

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setDialogState) => AlertDialog(
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  title: Text(
                    'Hủy món: ${item.product?.name ?? 'Sản phẩm'}',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Số lượng hủy',
                        style: TextStyle(fontSize: 14.sp, color: Colors.grey),
                      ),
                      SizedBox(height: 12.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildDialogQtyButton(Icons.remove, () {
                            if (voidQuantity > 1) {
                              setDialogState(() => voidQuantity--);
                            }
                          }),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 24.w),
                            child: Text(
                              '$voidQuantity',
                              style: TextStyle(
                                fontSize: 24.sp,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryBlue,
                              ),
                            ),
                          ),
                          _buildDialogQtyButton(Icons.add, () {
                            if (voidQuantity < item.quantity) {
                              setDialogState(() => voidQuantity++);
                            }
                          }),
                        ],
                      ),
                      SizedBox(height: 24.h),
                      TextField(
                        controller: reasonController,

                        decoration: InputDecoration(
                          hintText: 'Lý do hủy',

                          hintStyle: TextStyle(fontSize: 14.sp),
                          filled: true,
                          fillColor: AppColors.bgLightGrey,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.r),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.r),
                            borderSide: const BorderSide(
                              color: AppColors.primaryBlue,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Hủy',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        if (reasonController.text.isNotEmpty) {
                          context.read<TableBloc>().add(
                            VoidOrderItem(
                              orderId: _currentOrder.id!,
                              productId: item.productId,
                              quantity: voidQuantity,
                              reason: reasonController.text,
                            ),
                          );
                          Navigator.pop(context);
                        } else {
                          NotificationUtils.showError(
                            context: context,
                            title: 'Lỗi',
                            description: 'Vui lòng nhập lý do hủy.',
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Xác nhận',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
          ),
    );
  }

  Widget _buildDialogQtyButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(8.w),
        decoration: BoxDecoration(
          color: AppColors.bgLightGrey,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Icon(icon, size: 20.sp, color: Colors.black87),
      ),
    );
  }

  void _recalculateTotal() {
    double subtotal = 0;
    for (var item in _currentOrder.items) {
      final isVoided = item.isVoided || item.voidReason != null || item.voidAt != null;
      if (!isVoided) {
        subtotal += item.quantity * item.unitPrice;
      }
    }
    _currentOrder.subtotal = subtotal;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.pop(context, _currentOrder);
      },
      child: AppScaffold(
        backgroundColor: AppColors.bgLightGrey,
        hasSafeArea: false,
        appBar: AppAppBar(
          title: TitleAppbarText(title: 'Bàn: ${widget.table.name}'),
          leading: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.black,
            size: 20,
          ),
          onLeadingClick: () => Navigator.pop(context, _currentOrder),
          actions: [
            IconButton(
              icon: const Icon(
                Icons.print_outlined,
                color: AppColors.primaryBlue,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ReceiptPreviewPage(order: _currentOrder),
                  ),
                );
              },
              tooltip: 'In tạm tính',
            ),
          ],
        ),
        body: MultiBlocListener(
          listeners: [
            BlocListener<TableBloc, TableState>(
              listener: (context, state) {
                if (state is TableActionSuccess) {
                  NotificationUtils.showSuccess(
                    context: context,
                    title: 'Thành công',
                    description: state.message,
                  );
                  // Refresh order after voiding
                  if (_currentOrder.id != null) {
                    context.read<TableBloc>().add(FetchTableOrder(_currentOrder.id!));
                  }
                } else if (state is TableActionFailure) {
                  NotificationUtils.showError(
                    context: context,
                    title: 'Thất bại',
                    description: state.message,
                  );
                } else if (state is TableOrderLoaded) {
                  setState(() {
                    _currentOrder = state.order;
                    _recalculateTotal();
                  });
                }
              },
            ),
            BlocListener<OrderBloc, OrderState>(
              listener: (context, state) {
                if (state is OrderAddItemsSuccess) {
                  NotificationUtils.showSuccess(
                    context: context,
                    title: 'Thành công',
                    description: state.message,
                  );
                  // Refresh the order to get latest state
                  if (_currentOrder.id != null) {
                    context.read<TableBloc>().add(FetchTableOrder(_currentOrder.id!));
                  }
                } else if (state is OrderAddItemsFailure) {
                  NotificationUtils.showError(
                    context: context,
                    title: 'Thất bại',
                    description: state.message,
                  );
                }
              },
            ),
          ],
          child: SafeArea(
            child: Column(
              children: [
                _buildOrderHeader(),
                Expanded(
                  child:
                      _currentOrder.items.isEmpty
                          ? _buildEmptyState()
                          : _buildItemList(),
                ),
                _buildBottomAction(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderHeader() {
    return Container(
      padding: EdgeInsets.all(16.w),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Mã đơn: ${_currentOrder.code}',
                style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
              ),
              SizedBox(height: 4.h),
              Text(
                'Giờ vào: 08:30', // Mock time
                style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
              ),
            ],
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withAlpha(15),
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Text(
              'Đang phục vụ',
              style: TextStyle(
                fontSize: 12.sp,
                color: AppColors.primaryBlue,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemList() {
    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: _currentOrder.items.length,
      itemBuilder: (context, index) {
        final item = _currentOrder.items[index];
        return _buildOrderItemCard(item, index);
      },
    );
  }

  Widget _buildOrderItemCard(OrderItem item, int index) {
    final isVoided = item.isVoided || item.voidReason != null || item.voidAt != null;

    return Dismissible(
      key: Key('item_${item.productId}_$index'),
      direction:
          (_canManageOrders && !isVoided && _roleId != 6)
              ? DismissDirection.endToStart
              : DismissDirection.none,
      onDismissed: (direction) {
        setState(() {
          _currentOrder.items.removeAt(index);
          _recalculateTotal();
        });
        NotificationUtils.showInfo(
          context: context,
          title: 'Thông báo',
          description: 'Đã xóa ${item.product?.name}',
        );
      },
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                backgroundColor: Colors.white,
                title: const Text('Xác nhận'),
                content: const Text(
                  'Bạn có muốn xóa món này khỏi đơn hàng không?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Hủy'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text(
                      'Xóa',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
        );
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        margin: EdgeInsets.only(bottom: 12.h),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: isVoided ? Colors.red.withAlpha(10) : Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: isVoided ? Border.all(color: Colors.red.withAlpha(30)) : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(5),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                // Image/Icon placeholder
                Stack(
                  children: [
                    Container(
                      width: 50.w,
                      height: 50.w,
                      decoration: BoxDecoration(
                        color: AppColors.bgLightGrey,
                        borderRadius: BorderRadius.circular(10.r),
                        image: (item.product?.url != null || (item.product?.images != null && item.product!.images!.isNotEmpty))
                            ? DecorationImage(
                                image: NetworkImage(item.product?.url ?? item.product!.images!.first.url),
                                fit: BoxFit.cover,
                                colorFilter: isVoided
                                    ? const ColorFilter.mode(Colors.grey, BlendMode.saturation)
                                    : null,
                              )
                            : null,
                      ),
                      child: (item.product?.url == null && (item.product?.images == null || item.product!.images!.isEmpty))
                          ? Icon(
                              Icons.coffee_rounded,
                              color: isVoided ? Colors.grey : AppColors.primaryBlue,
                              size: 24.sp,
                            )
                          : null,
                    ),
                    if (isVoided)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(100),
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                          child: Icon(Icons.close_rounded, color: Colors.red, size: 24.sp),
                        ),
                      ),
                  ],
                ),
                SizedBox(width: 12.w),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.product?.name ?? 'Sản phẩm',
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.bold,
                          color: isVoided ? Colors.grey : Colors.black87,
                          decoration: isVoided ? TextDecoration.lineThrough : null,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4.h),
                      Row(
                        children: [
                          Text(
                            '${formatMoney(item.unitPrice)} đ',
                            style: TextStyle(
                              fontSize: 13.sp,
                              color: isVoided ? Colors.grey : Colors.grey[600],
                              decoration: isVoided ? TextDecoration.lineThrough : null,
                            ),
                          ),
                          Spacer(),
                          Text(
                            'SL:${item.quantity}',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.bold,
                              color: isVoided ? Colors.grey : AppColors.primaryBlue,
                            ),
                          ),
                          SizedBox(width: 16.w),
                        ],
                      ),
                    ],
                  ),
                ),

                if (_canManageOrders && !isVoided && _roleId != 6)
                  IconButton(
                    onPressed: () => _removeItem(index),
                    icon: Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.red[400],
                      size: 22.sp,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: 'Hủy món',
                  ),
              ],
            ),
            if (isVoided && item.voidReason != null) ...[
              SizedBox(height: 8.h),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Lý do hủy: ${item.voidReason}',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.red[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_basket_outlined,
            size: 64.sp,
            color: Colors.grey[300],
          ),
          SizedBox(height: 16.h),
          Text(
            'Chưa có món nào',
            style: TextStyle(fontSize: 16.sp, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomAction() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tổng cộng:',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '${formatMoney(_currentOrder.subtotal ?? 0)} đ',
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryBlue,
                  ),
                ),
              ],
            ),
            SizedBox(height: 20.h),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) =>
                                  ProductsListPage(table: widget.table),
                        ),
                      ).then((data) {
                        if (!mounted) return;
                        if (data is List<OrderItem> && data.isNotEmpty) {
                          context.read<OrderBloc>().add(
                                OrderAddItemsEvent(
                                  orderId: _currentOrder.id!,
                                  items: data,
                                ),
                              );
                        }
                      });
                    },
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Thêm món'),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      foregroundColor: AppColors.primaryBlue,
                      side: const BorderSide(color: AppColors.primaryBlue),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      final nonVoidedItems = _currentOrder.items.where((item) => !item.isVoided).toList();
                      
                      if (nonVoidedItems.isEmpty) {
                        NotificationUtils.showError(
                          context: context,
                          title: 'Lỗi',
                          description:
                              'Vui lòng thêm món trước khi thanh toán',
                        );
                        return;
                      }

                      // Map OrderItems to Products for the existing flow
                      final products =
                          nonVoidedItems.map((item) {
                            return Product(
                              id: item.productId,
                              name: item.product?.name ?? 'Sản phẩm',
                              price: item.unitPrice,
                              quantity: item.quantity,
                              url: item.product?.url,
                              images: item.product?.images,
                            );
                          }).toList();

                      showDialog(
                        context: context,
                        builder:
                            (_) => ConfirmOrderDialog(
                              items: products,
                              parentContext: context,
                              existingOrderId:
                                  _currentOrder.id, // Pass existing order ID
                              tableId: widget.table.id, // Pass table ID
                            ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF43A047),
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Thanh toán',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
