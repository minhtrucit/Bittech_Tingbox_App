import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../ting_box.dart';
import 'orders_list_skeleton.dart';

class OrdersListPage extends StatefulWidget {
  const OrdersListPage({super.key});

  @override
  State<OrdersListPage> createState() => _OrdersListPageState();
}

class _OrdersListPageState extends State<OrdersListPage>
    with AutomaticKeepAliveClientMixin {
  String _selectedTimeFilter = 'Hôm nay';
  String _selectedStatusFilter = 'Tất cả';

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();

    final currentState = context.read<OrderBloc>().state;
    if (currentState is! OrderCreateSuccess) {
      context.read<OrderBloc>().add(OrderGetAllOrdersEvent());
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return AppScaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: SafeArea(
        child: Column(
          children: [
            _buildTimeFilterTabs(),
            _buildStatusFilterChips(),
            Expanded(child: _buildOrdersList()),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppAppBar(
      title: TitleAppbarText(title: 'Đơn hàng'),
      actions: [
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: () {
            // TODO: Implement search
          },
        ),
      ],
    );
  }

  Widget _buildTimeFilterTabs() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: CupertinoSlidingSegmentedControl<String>(
        groupValue: _selectedTimeFilter,
        onValueChanged: (value) {
          if (value != null) {
            setState(() {
              _selectedTimeFilter = value;
            });
          }
        },
        backgroundColor: Colors.grey.shade100,
        thumbColor: AppColors.white,
        children: {
          'Hôm nay': Padding(
            padding: EdgeInsets.symmetric(vertical: 8.h),
            child: Text(
              'Hôm nay',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color:
                    _selectedTimeFilter == 'Hôm nay'
                        ? AppColors.primaryBlue
                        : Colors.grey.shade700,
              ),
            ),
          ),
          'Tuần này': Padding(
            padding: EdgeInsets.symmetric(vertical: 8.h),
            child: Text(
              'Tuần này',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color:
                    _selectedTimeFilter == 'Tuần này'
                        ? AppColors.primaryBlue
                        : Colors.grey.shade700,
              ),
            ),
          ),
          'Tháng này': Padding(
            padding: EdgeInsets.symmetric(vertical: 8.h),
            child: Text(
              'Tháng này',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color:
                    _selectedTimeFilter == 'Tháng này'
                        ? AppColors.primaryBlue
                        : Colors.grey.shade700,
              ),
            ),
          ),
        },
      ),
    );
  }

  Widget _buildStatusFilterChips() {
    final statuses = ['Tất cả', 'Đã thanh toán', 'Đang xử lý', 'Đã hủy'];

    return Container(
      color: Colors.white,
      height: 56.h,
      child: SingleChildScrollView(
        physics: BouncingScrollPhysics(),
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        child: Row(
          children:
              statuses.map((status) {
                final isSelected = _selectedStatusFilter == status;
                return Container(
                  margin: EdgeInsets.only(right: 8.w),
                  child: FilterChip(
                    checkmarkColor: AppColors.primaryBlue,
                    label: Text(status),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedStatusFilter = status;
                      });
                    },
                    backgroundColor: Colors.grey.shade100,
                    selectedColor: AppColors.white,
                    labelStyle: TextStyle(
                      fontSize: 13.sp,
                      color:
                          isSelected
                              ? AppColors.primaryBlue
                              : Colors.grey.shade700,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.r),
                      side: BorderSide(
                        color:
                            isSelected
                                ? AppColors.primaryBlue
                                : Colors.transparent,
                      ),
                    ),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    pressElevation: 0,
                    elevation: 0,
                    shadowColor: Colors.transparent,
                    surfaceTintColor: Colors.transparent,
                  ),
                );
              }).toList(),
        ),
      ),
    );
  }

  Widget _buildOrdersList() {
    final state = context.watch<OrderBloc>().state;

    if (state is OrderLoading) {
      return const OrdersListSkeleton();
    }

    if (state is OrderGetAllOrdersSuccess) {
      final filteredOrders = _filterOrders(state.orders);

      if (filteredOrders.isEmpty) {
        return _buildEmptyState();
      }

      return ListView.builder(
        physics: BouncingScrollPhysics(),
        padding: EdgeInsets.only(
          bottom: 64.h,
          left: 16.w,
          right: 16.w,
          top: 16.h,
        ),
        itemCount: filteredOrders.length,
        itemBuilder: (context, index) {
          return _buildOrderCard(filteredOrders[index]);
        },
      );
    }

    return _buildEmptyState();
  }

  List<Order> _filterOrders(List<Order> orders) {
    List<Order> filtered = orders;

    // Filter by time
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    filtered =
        filtered.where((order) {
          if (order.createdAt == null) return false;

          try {
            final orderDate = DateTime.parse(order.createdAt!);
            final orderDay = DateTime(
              orderDate.year,
              orderDate.month,
              orderDate.day,
            );

            switch (_selectedTimeFilter) {
              case 'Hôm nay':
                return orderDay.isAtSameMomentAs(today);
              case 'Tuần này':
                final weekStart = today.subtract(
                  Duration(days: today.weekday - 1),
                );
                return orderDay.isAfter(
                      weekStart.subtract(Duration(days: 1)),
                    ) &&
                    orderDay.isBefore(today.add(Duration(days: 1)));
              case 'Tháng này':
                return orderDate.year == now.year &&
                    orderDate.month == now.month;
              default:
                return true;
            }
          } catch (e) {
            return false;
          }
        }).toList();

    // Filter by status
    if (_selectedStatusFilter != 'Tất cả') {
      filtered =
          filtered.where((order) {
            final status = _getOrderStatus(order);
            return status.label == _selectedStatusFilter;
          }).toList();
    }

    return filtered;
  }

  Widget _buildOrderCard(Order order) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey.shade200),
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
          _buildOrderHeader(order),
          SizedBox(height: 8.h),
          _buildOrderCustomer(order),
          SizedBox(height: 8.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [_buildOrderTime(order), _buildOrderStatus(order)],
          ),
        ],
      ),
    );
  }

  Widget _buildOrderHeader(Order order) {
    final orderId =
        order.createdAt != null
            ? 'HD${order.createdAt!.replaceAll(RegExp(r'[^0-9]'), '').substring(0, 6)}'
            : 'HD000000';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '#$orderId',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        Text(
          '${formatMoney(order.totalAmount ?? 0)}đ',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildOrderCustomer(Order order) {
    return Text(
      order.customerName.isNotEmpty ? order.customerName : 'Khách vãng lai',
      style: TextStyle(fontSize: 14.sp, color: Colors.grey.shade600),
    );
  }

  Widget _buildOrderTime(Order order) {
    return Text(
      _formatOrderTime(order.createdAt),
      style: TextStyle(fontSize: 13.sp, color: Colors.grey.shade500),
    );
  }

  String _formatOrderTime(String? createdAt) {
    if (createdAt == null) return '';

    try {
      final dateTime = DateTime.parse(createdAt);
      String timeStr =
          '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
      String dateStr =
          '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year}';

      return '$timeStr - $dateStr';
    } catch (e) {
      return createdAt;
    }
  }

  Widget _buildOrderStatus(Order order) {
    final status = _getOrderStatus(order);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: status.color.withAlpha(10),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8.w,
            height: 8.w,
            decoration: BoxDecoration(
              color: status.color,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 6.w),
          Text(
            status.label,
            style: TextStyle(
              fontSize: 13.sp,
              color: status.color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  OrderStatusInfo _getOrderStatus(Order order) {
    final paymentMethod = order.paymentMethod.toLowerCase();

    if (paymentMethod.contains('tiền mặt') || paymentMethod.contains('cash')) {
      return OrderStatusInfo(label: 'Đã thanh toán', color: Colors.green);
    } else if (paymentMethod.contains('chuyển khoản') ||
        paymentMethod.contains('transfer')) {
      return OrderStatusInfo(label: 'Đang xử lý', color: Colors.orange);
    } else {
      return OrderStatusInfo(label: 'Đã thanh toán', color: Colors.green);
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 64,
            color: Colors.grey.shade300,
          ),
          SizedBox(height: 16.h),
          Text(
            'Chưa có đơn hàng nào',
            style: TextStyle(fontSize: 16.sp, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}

class OrderStatusInfo {
  final String label;
  final Color color;

  OrderStatusInfo({required this.label, required this.color});
}
