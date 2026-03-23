import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ting_box/extension/date_time_extension.dart';
import 'package:ting_box/models/table_model.dart';
import 'package:ting_box/models/zone_model.dart';
import 'package:ting_box/pages/ConfigPage/bloc/config_bloc.dart';
import 'package:ting_box/pages/ConfigPage/bloc/config_state.dart';
import 'package:ting_box/services/table_service.dart';
import '../../../ting_box.dart';
import 'orders_list_skeleton.dart';

class OrdersListPage extends StatefulWidget {
  final bool isVisible;

  const OrdersListPage({super.key, this.isVisible = false});

  @override
  State<OrdersListPage> createState() => _OrdersListPageState();
}

class _OrdersListPageState extends State<OrdersListPage>
    with AutomaticKeepAliveClientMixin {
  String _selectedStatusFilter = 'Tất cả';
  int? _currentPaymentStatus; // Track current filter for API
  List<Order>? _orders;
  int? _selectedTableId;
  String? _selectedTableName;
  SubscriptionPlan _currentPlan = SubscriptionPlan.basic;
  Map<int, String> _tableNames = {};

  @override
  bool get wantKeepAlive => true;

  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;
  int _currentPage = 1;
  bool _canLoadMore = true;
  int? _userId;
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  String _searchQuery = '';

  @override
  void didUpdateWidget(OrdersListPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible && !oldWidget.isVisible) {
      if (_userId != null) {
        _fetchOrders(
          userId: _userId!,
          page: 1,
          paymentStatus: _currentPaymentStatus,
          searchQuery: _searchQuery,
          tableId: _selectedTableId,
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _initData();

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
      }
    }
  }

  Future<void> _initData() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString(UserRepository.keyUserId);
    final user = await UserRepository.getUser();

    if (mounted) {
      setState(() {
        if (userId != null) {
          _userId = int.parse(userId);
        }

        final roleId = user?.roleId ?? 0;
        if (roleId == 1) {
          _currentPlan = SubscriptionPlan.admin;
        } else if (roleId == 2) {
          _currentPlan = SubscriptionPlan.premium;
        } else if (roleId == 5 || roleId == 6) {
          _currentPlan = SubscriptionPlan.fnb;
        } else {
          _currentPlan = SubscriptionPlan.basic;
        }

        final configState = context.read<ConfigBloc>().state;
        if (configState is ConfigLoaded &&
            configState.config.subscriptionPlan == SubscriptionPlan.fnb) {
          _currentPlan = SubscriptionPlan.fnb;
        }
      });

      if (_currentPlan == SubscriptionPlan.fnb) {
        _loadTableNames();
      }

      if (_orders == null && _userId != null) {
        _fetchOrders(
          userId: _userId!,
          page: 1,
          paymentStatus: _currentPaymentStatus,
          searchQuery: _searchQuery,
          tableId: _selectedTableId,
        );
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadTableNames() async {
    final configState = context.read<ConfigBloc>().state;
    if (configState is ConfigLoaded) {
      final configId = configState.config.id;
      if (configId != null) {
        try {
          final zones = await context.read<TableService>().getZones(configId);
          final Map<int, String> names = {};
          for (var zone in zones) {
            // Check if tables are already in the zone response
            if (zone.tables != null && zone.tables!.isNotEmpty) {
              for (var table in zone.tables!) {
                names[table.id] = table.name;
              }
            } else {
              // Otherwise fetch tables for this zone
              final tables = await context.read<TableService>().getTables(
                zone.id,
              );
              for (var table in tables) {
                names[table.id] = table.name;
              }
            }
          }
          if (mounted) {
            setState(() {
              _tableNames = names;
            });
          }
        } catch (e) {
          debugPrint('Error loading table names: $e');
        }
      }
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _canLoadMore) {
      _loadMore();
    }
  }

  void _fetchOrders({
    required int userId,
    int? page,
    int? paymentStatus,
    String? searchQuery,
    int? tableId,
    int limit = 10,
  }) {
    context.read<OrderBloc>().add(
      OrderGetAllOrdersbyUserIdEvent(
        userId: userId,
        page: page,
        paymentStatus: paymentStatus,
        searchQuery: searchQuery,
        tableId: tableId,
        limit: limit,
      ),
    );
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        _searchQuery = query;
        _currentPage = 1;
        _orders = null;
        _canLoadMore = true;

        // Nếu có tìm kiếm, chúng ta nên reset filter trạng thái về 'Tất cả'
        // để người dùng không bị bối rối khi kết quả hiện ra ở mọi trạng thái.
        if (query.isNotEmpty) {
          _selectedStatusFilter = 'Tất cả';
          _currentPaymentStatus = null;
        }
      });
      if (_userId != null) {
        _fetchOrders(
          userId: _userId!,
          page: 1,
          // Khi tìm kiếm, chúng ta tìm toàn bộ trạng thái (paymentStatus = null)
          // và tăng limit lên cao (100) để "tìm hết" và "chính xác" nhất.
          paymentStatus: query.isNotEmpty ? null : _currentPaymentStatus,
          searchQuery: _searchQuery,
          tableId: _selectedTableId,
          limit: query.isNotEmpty ? 100 : 10,
        );
      }
    });
  }

  void _loadMore() {
    setState(() {
      _isLoadingMore = true;
    });
    // Load more with current filter
    if (_userId != null) {
      _fetchOrders(
        userId: _userId!,
        page: _currentPage + 1,
        paymentStatus: _currentPaymentStatus,
        searchQuery: _searchQuery,
        tableId: _selectedTableId,
      );
    }
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
        _currentPaymentStatus = null;
      }

      _currentPage = 1;
      _orders = null; // Clear old data
      _canLoadMore = true;
    });

    // Fetch with new filter from page 1
    if (_userId != null) {
      _fetchOrders(
        userId: _userId!,
        page: 1,
        paymentStatus: _currentPaymentStatus,
        searchQuery: _searchQuery,
        tableId: _selectedTableId,
      );
    }
  }

  Future<void> _showTableFilterDialog() async {
    final configState = context.read<ConfigBloc>().state;
    if (configState is! ConfigLoaded) {
      NotificationUtils.showError(
        context: context,
        title: 'Lỗi',
        description: 'Vui lòng chờ cấu hình hệ thống',
      );
      return;
    }

    final configId = configState.config.id;
    if (configId == null) return;

    final tableService = context.read<TableService>();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (sContext) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Container(
            constraints: BoxConstraints(maxHeight: 0.7.sh, maxWidth: 0.8.sw),
            padding: EdgeInsets.all(16.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Chọn bàn',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(sContext),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _selectedTableId = null;
                      _selectedTableName = null;
                      _currentPage = 1;
                      _orders = null;
                      _canLoadMore = true;
                    });
                    Navigator.pop(sContext);
                    if (_userId != null) {
                      _fetchOrders(
                        userId: _userId!,
                        page: 1,
                        paymentStatus: _currentPaymentStatus,
                        tableId: null,
                        searchQuery: _searchQuery,
                      );
                    }
                  },
                  icon: const Icon(
                    Icons.filter_list_off,
                    size: 18,
                    color: AppColors.primaryBlue,
                  ),
                  label: const Text(
                    'Tất cả các bàn',
                    style: TextStyle(color: AppColors.primaryBlue),
                  ),
                ),
                const Divider(),
                Expanded(
                  child: FutureBuilder<List<ZoneModel>>(
                    future: tableService.getZones(configId),
                    builder: (context, zoneSnapshot) {
                      if (!zoneSnapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final zones = zoneSnapshot.data!;
                      return ListView.builder(
                        shrinkWrap: true,
                        itemCount: zones.length,
                        itemBuilder: (context, zIndex) {
                          final zone = zones[zIndex];
                          return FutureBuilder<List<TableModel>>(
                            future: tableService.getTables(zone.id),
                            builder: (context, tableSnapshot) {
                              if (!tableSnapshot.hasData) {
                                return const SizedBox();
                              }
                              final tables = tableSnapshot.data!;
                              final activeTables =
                                  tables.where((t) => t.isActive).toList();

                              if (activeTables.isEmpty) {
                                return const SizedBox();
                              }

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: EdgeInsets.symmetric(
                                      vertical: 8.h,
                                    ),
                                    child: Text(
                                      zone.name,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primaryBlue,
                                        fontSize: 14.sp,
                                      ),
                                    ),
                                  ),
                                  Wrap(
                                    spacing: 8.w,
                                    runSpacing: 8.h,
                                    children:
                                        activeTables.map((table) {
                                          final isSelected =
                                              _selectedTableId == table.id;
                                          return InkWell(
                                            onTap: () {
                                              setState(() {
                                                _selectedTableId = table.id;
                                                _selectedTableName = table.name;
                                                _currentPage = 1;
                                                _orders = null;
                                                _canLoadMore = true;
                                              });
                                              Navigator.pop(sContext);
                                              if (_userId != null) {
                                                _fetchOrders(
                                                  userId: _userId!,
                                                  page: 1,
                                                  paymentStatus:
                                                      _currentPaymentStatus,
                                                  tableId: table.id,
                                                  searchQuery: _searchQuery,
                                                );
                                              }
                                            },
                                            child: Container(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 12.w,
                                                vertical: 8.h,
                                              ),
                                              decoration: BoxDecoration(
                                                color:
                                                    isSelected
                                                        ? AppColors.primaryBlue
                                                        : Colors.grey.shade100,
                                                borderRadius:
                                                    BorderRadius.circular(8.r),
                                              ),
                                              child: Text(
                                                table.name,
                                                style: TextStyle(
                                                  color:
                                                      isSelected
                                                          ? Colors.white
                                                          : Colors.black87,
                                                  fontSize: 13.sp,
                                                ),
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                  ),
                                  SizedBox(height: 12.h),
                                ],
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
            _buildSearchBar(),
            _buildStatusFilterChips(),
            Expanded(child: _buildOrdersList()),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 4.h),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        decoration: InputDecoration(
          hintText: 'Mã đơn, ID, Tên hoặc SĐT khách hàng...',
          hintStyle: TextStyle(fontSize: 14.sp, color: Colors.grey),
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          suffixIcon:
              _searchController.text.isNotEmpty
                  ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.grey),
                    onPressed: () {
                      _searchController.clear();
                      _onSearchChanged('');
                    },
                  )
                  : null,
          filled: true,
          fillColor: Colors.grey.shade100,
          contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 16.w),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: BorderSide(color: AppColors.primaryBlue, width: 1),
          ),
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
          children: [
            if (_currentPlan == SubscriptionPlan.fnb ||
                (context.watch<ConfigBloc>().state is ConfigLoaded &&
                    (context.watch<ConfigBloc>().state as ConfigLoaded)
                            .config
                            .subscriptionPlan ==
                        SubscriptionPlan.fnb))
              _buildTableFilterButton(),
            ...statuses.map((status) {
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
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildTableFilterButton() {
    final isSelected = _selectedTableId != null;
    return Container(
      margin: EdgeInsets.only(right: 8.w),
      child: FilterChip(
        label: Text(_selectedTableName ?? 'Bàn'),
        selected: isSelected,
        onSelected: (_) => _showTableFilterDialog(),
        avatar: Icon(
          Icons.table_bar_rounded,
          size: 16.sp,
          color: isSelected ? Colors.white : Colors.grey,
        ),
        backgroundColor: Colors.grey.shade100,
        selectedColor: AppColors.primaryBlue,
        labelStyle: TextStyle(
          fontSize: 13.sp,
          color: isSelected ? Colors.white : Colors.grey.shade700,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
          side: BorderSide(
            color: isSelected ? AppColors.primaryBlue : Colors.transparent,
          ),
        ),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
        debugPrint("OrdersListPage: ${_orders?.length}");
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
              if (_userId != null) {
                _fetchOrders(
                  userId: _userId!,
                  page: 1,
                  paymentStatus: _currentPaymentStatus,
                  searchQuery: _searchQuery,
                  tableId: _selectedTableId,
                );
              }
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildOrderHeader(order),
                _buildOrderBadge(order),
              ],
            ),
            SizedBox(height: 8.h),
            _buildOrderCustomer(order),
            SizedBox(height: 16.h),
            Text(
              '${formatMoney(order.totalAmount ?? 0)} đ',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 16.h),
            _buildOrderStatus(order),
            SizedBox(height: 8.h),
            _buildOrderTime(order),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderHeader(Order order) {
    final orderId = '#${order.code}-${order.id}';

    return Expanded(
      child: Text(
        orderId,
        style: TextStyle(
          fontSize: 16.sp,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildOrderBadge(Order order) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: AppColors.primaryBlue.withAlpha(10),
        borderRadius: BorderRadius.circular(6.r),
        border: Border.all(color: AppColors.primaryBlue.withAlpha(20)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.table_bar_rounded,
            size: 12.sp,
            color: AppColors.primaryBlue,
          ),
          SizedBox(width: 4.w),
          Text(
            (order.tableId != null && _tableNames.containsKey(order.tableId))
                ? _tableNames[order.tableId]!
                : (order.tableName != null && order.tableName!.isNotEmpty)
                ? order.tableName!
                : (order.tableId != null && order.tableId != 0
                    ? 'Bàn ${order.tableId}'
                    : 'Mang về'),
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryBlue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCustomer(Order order) {
    return Text(
      order.customerName.isNotEmpty ? order.customerName : 'Khách vãng lai',
      style: TextStyle(fontSize: 14.sp, color: Colors.grey.shade600),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildOrderTime(Order order) {
    return Row(
      children: [
        Icon(Icons.access_time_rounded, size: 16.sp, color: Colors.grey),
        SizedBox(width: 6.w),
        Text(
          _formatOrderTime(order.createdAt),
          style: TextStyle(fontSize: 13.sp, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  String _formatOrderTime(String? createdAt) {
    if (createdAt == null) return '';

    // Trying to format as HH:mm • dd/MM/yyyy
    try {
      final dateTime = DateTime.parse(createdAt).toLocal();
      final time =
          '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
      final date =
          '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year}';
      return '$time • $date';
    } catch (e) {
      return createdAt.toReadableDateTime();
    }
  }

  Widget _buildOrderStatus(Order order) {
    final status = _getOrderStatus(order);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10.w,
          height: 10.w,
          decoration: BoxDecoration(
            color: status.color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: status.color.withAlpha(50),
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
        SizedBox(width: 8.w),
        Text(
          status.label,
          style: TextStyle(
            fontSize: 14.sp,
            color: Colors.grey.shade800,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  OrderStatusInfo _getOrderStatus(Order order) {
    debugPrint(
      'PaymentId: ${order.userId} - Payment status: ${order.paymentStatus}',
    );
    final paymentStatus = order.paymentStatus?.toLowerCase();

    if (paymentStatus == PaymentStatus.paid) {
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
              if (_userId != null) {
                _fetchOrders(
                  userId: _userId!,
                  page: 1,
                  paymentStatus: _currentPaymentStatus,
                  tableId: _selectedTableId,
                );
              }
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
