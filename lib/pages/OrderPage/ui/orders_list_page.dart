import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ting_box/extension/date_time_extension.dart';
import '../../../ting_box.dart';
import 'orders_list_skeleton.dart';

class OrdersListPage extends StatefulWidget {
  const OrdersListPage({super.key});

  @override
  State<OrdersListPage> createState() => _OrdersListPageState();
}

class _OrdersListPageState extends State<OrdersListPage>
    with AutomaticKeepAliveClientMixin {
  String _selectedStatusFilter = 'Tất cả';
  int? _currentPaymentStatus; // Track current filter for API
  List<Order>? _orders;

  @override
  bool get wantKeepAlive => true;

  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;
  int _currentPage = 1;
  bool _canLoadMore = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    // Only load orders if we don't have any data yet
    if (_orders == null) {
      final currentState = context.read<OrderBloc>().state;
      if (currentState is OrderGetAllOrdersSuccess) {
        // If we already have data in bloc, use it
        setState(() {
          _orders = currentState.orders;
          _canLoadMore = currentState.canLoadMore;
          _currentPage = currentState.page ?? 1;
        });
      } else {
        // Otherwise fetch new data
        _fetchOrders(page: 1, paymentStatus: _currentPaymentStatus);
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _canLoadMore) {
      _loadMore();
    }
  }

  void _fetchOrders({int? page, int? paymentStatus}) {
    context.read<OrderBloc>().add(
      OrderGetAllOrdersEvent(page: page, paymentStatus: paymentStatus),
    );
  }

  void _loadMore() {
    setState(() {
      _isLoadingMore = true;
    });
    // Load more with current filter
    _fetchOrders(page: _currentPage + 1, paymentStatus: _currentPaymentStatus);
  }

  void _onFilterChanged(String filter) {
    setState(() {
      _selectedStatusFilter = filter;
      // Map UI filter to API paymentStatus
      if (filter == 'Đã thanh toán') {
        _currentPaymentStatus = 2;
      } else if (filter == 'Chưa thanh toán') {
        _currentPaymentStatus = 0;
      } else {
        _currentPaymentStatus = null; // 'Tất cả'
      }

      // Reset pagination when filter changes
      _currentPage = 1;
      _orders = null; // Clear old data
      _canLoadMore = true;
    });

    // Fetch with new filter from page 1
    _fetchOrders(
      page: 1,
      paymentStatus: _currentPaymentStatus,
    );
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
            _buildStatusFilterChips(),
            Expanded(child: _buildOrdersList()),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppAppBar(title: TitleAppbarText(title: 'Đơn hàng'));
  }

  Widget _buildStatusFilterChips() {
    final statuses = ['Tất cả', 'Đã thanh toán', 'Chưa thanh toán'];

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
                      _onFilterChanged(status);
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
    return BlocConsumer<OrderBloc, OrderState>(
      listener: (context, state) {
        if (state is OrderGetAllOrdersSuccess) {
          setState(() {
            _orders = state.orders;
            _canLoadMore = state.canLoadMore;
            _currentPage = state.page ?? 1;
            _isLoadingMore = false;
          });
        } else if (state is OrderFailure) {
          setState(() {
            _isLoadingMore = false;
          });
        }
      },
      buildWhen: (previous, current) {
        return current is OrderGetAllOrdersSuccess ||
            (current is OrderLoading && _orders == null) ||
            current is OrderFailure;
      },
      builder: (context, state) {
        if (state is OrderLoading && _orders == null) {
          return const OrdersListSkeleton();
        }

        if (_orders != null) {
          if (_orders!.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            color: AppColors.primaryBlue,
            backgroundColor: AppColors.white,
            onRefresh: () async {
              // Refresh with current filter
              _fetchOrders(page: 1, paymentStatus: _currentPaymentStatus);
              await Future.delayed(const Duration(milliseconds: 500));
            },
            child: RawScrollbar(
              controller: _scrollController,
              child: ListView.builder(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: EdgeInsets.only(
                  bottom: 64.h,
                  left: 16.w,
                  right: 16.w,
                  top: 16.h,
                ),
                itemCount: _orders!.length + (_isLoadingMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _orders!.length) {
                    return Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primaryBlue,
                          strokeWidth: 2,
                        ),
                      ),
                    );
                  }
                  return _buildOrderCard(_orders![index]);
                },
              ),
            ),
          );
        }

        return _buildEmptyState();
      },
    );
  }

  Widget _buildOrderCard(Order order) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OrderDetailPage(order: order),
          ),
        );
      },
      child: Container(
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
      ),
    );
  }

  Widget _buildOrderHeader(Order order) {
    final orderId = '#${order.code}-${order.id}';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          orderId,
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

    return createdAt.toReadableDateTime();
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
    debugPrint(
      'PaymentId: ${order.userId} - Payment status: ${order.paymentStatus}',
    );
    final paymentStatus = order.paymentStatus?.toLowerCase();

    if (paymentStatus == 'paid') {
      return OrderStatusInfo(label: 'Đã thanh toán', color: Colors.green);
    } else {
      // Default to unpaid for null or 'unpaid' or any other value
      return OrderStatusInfo(label: 'Chưa thanh toán', color: Colors.orange);
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
          SizedBox(height: 16.h),

          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              context.read<OrderBloc>().add(OrderGetStatisticsEvent());
            },
            child: const Text("Tải lại", style: TextStyle(fontSize: 16)),
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
