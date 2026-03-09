import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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

  @override
  void initState() {
    super.initState();
    _currentOrder = widget.initialOrder;
  }

  void _updateQuantity(int index, int delta) {
    setState(() {
      final item = _currentOrder.items[index];
      final newQuantity = item.quantity + delta;

      if (newQuantity <= 0) {
        _removeItem(index);
      } else {
        _currentOrder.items[index] = OrderItem(
          productId: item.productId,
          quantity: newQuantity,
          unitPrice: item.unitPrice,
          product: item.product,
        );
        _recalculateTotal();
      }
    });
  }

  void _removeItem(int index) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Xác nhận'),
            content: const Text('Bạn có muốn xóa món này khỏi đơn hàng không?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Hủy'),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _currentOrder.items.removeAt(index);
                    _recalculateTotal();
                  });
                  Navigator.pop(context);
                },
                child: const Text('Xóa', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );
  }

  void _recalculateTotal() {
    double subtotal = 0;
    for (var item in _currentOrder.items) {
      subtotal += item.quantity * item.unitPrice;
    }
    _currentOrder.subtotal = subtotal;
    // For simplicity in mock, total = subtotal
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
        body: SafeArea(
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
    return Dismissible(
      key: Key('item_${item.productId}_$index'),
      direction: DismissDirection.endToStart,
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(5),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Image/Icon placeholder
            Container(
              width: 50.w,
              height: 50.w,
              decoration: BoxDecoration(
                color: AppColors.bgLightGrey,
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(
                Icons.coffee_rounded,
                color: AppColors.primaryBlue,
                size: 24.sp,
              ),
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
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    '${formatMoney(item.unitPrice)} đ',
                    style: TextStyle(fontSize: 13.sp, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),

            // Quantity Controls
            Row(
              children: [
                _buildQtyButton(Icons.remove, () => _updateQuantity(index, -1)),
                Container(
                  width: 30.w,
                  alignment: Alignment.center,
                  child: Text(
                    '${item.quantity}',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildQtyButton(Icons.add, () => _updateQuantity(index, 1)),
                SizedBox(width: 8.w),
                // Explicit delete button
                IconButton(
                  onPressed: () => _removeItem(index),
                  icon: Icon(
                    Icons.delete_outline,
                    color: Colors.red[300],
                    size: 20.sp,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQtyButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(6.w),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 16.sp, color: Colors.black87),
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
                        if (data is List<OrderItem>) {
                          setState(() {
                            for (var newItem in data) {
                              // Check if item already exists in the order
                              final existingIndex = _currentOrder.items
                                  .indexWhere(
                                    (item) =>
                                        item.productId == newItem.productId,
                                  );
                              if (existingIndex != -1) {
                                final existingItem =
                                    _currentOrder.items[existingIndex];
                                _currentOrder.items[existingIndex] = OrderItem(
                                  productId: existingItem.productId,
                                  quantity:
                                      existingItem.quantity + newItem.quantity,
                                  unitPrice: existingItem.unitPrice,
                                  product: existingItem.product,
                                );
                              } else {
                                _currentOrder.items.add(newItem);
                              }
                            }
                            _recalculateTotal();
                          });
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
                      if (_currentOrder.items.isEmpty) {
                        NotificationUtils.showError(
                          context: context,
                          title: 'Lỗi',
                          description: 'Vui lòng thêm món trước khi thanh toán',
                        );
                        return;
                      }

                      // Map OrderItems to Products for the existing flow
                      final products =
                          _currentOrder.items.map((item) {
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
