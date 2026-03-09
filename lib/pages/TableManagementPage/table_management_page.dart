import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ting_box/pages/TableManagementPage/table_order_detail_page.dart';
import '../../../models/table_model.dart';
import '../../../ting_box.dart';

class TableManagementPage extends StatefulWidget {
  const TableManagementPage({super.key});

  @override
  State<TableManagementPage> createState() => _TableManagementPageState();
}

class _TableManagementPageState extends State<TableManagementPage> {
  // Mock data as a mutable list for the demo
  late List<TableModel> _mockTables;
  // Store temp orders for occupied tables
  final Map<int, Order> _tempOrders = {};
  User? _currentUser;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _mockTables = [
      TableModel(
        id: 0,
        name: 'Mang về',
        status: TableStatus.empty,
        capacity: 0,
        zone: 'Takeaway',
      ),
      TableModel(id: 1, name: 'Bàn 1', status: TableStatus.empty, capacity: 4),
      TableModel(
        id: 2,
        name: 'Bàn 2',
        status: TableStatus.occupied,
        capacity: 2,
        currentOrderId: 101,
      ),
      TableModel(
        id: 3,
        name: 'Bàn 3',
        status: TableStatus.reserved,
        capacity: 6,
      ),
      TableModel(id: 4, name: 'Bàn 4', status: TableStatus.empty, capacity: 4),
      TableModel(
        id: 5,
        name: 'Bàn 5',
        status: TableStatus.warning,
        capacity: 4,
      ),
      TableModel(id: 6, name: 'Bàn 6', status: TableStatus.empty, capacity: 4),
      TableModel(
        id: 7,
        name: 'Bàn 7',
        status: TableStatus.occupied,
        capacity: 8,
        currentOrderId: 102,
      ),
      TableModel(id: 8, name: 'Bàn 8', status: TableStatus.empty, capacity: 4),
    ];

    // Pre-populate mock orders for existing occupied tables
    _tempOrders[2] = _generateMockOrder(2, 'Bàn 2');
    _tempOrders[7] = _generateMockOrder(7, 'Bàn 7');
  }

  Future<void> _loadUser() async {
    final user = await UserRepository.getUser();
    if (mounted) {
      setState(() {
        _currentUser = user;
        // Role ID logic: 1 is Admin/Enterprise, others are Sub-users/Staff
        // Fallback to true if no user (for demo) but real app would check role
        _isAdmin = user?.roleId == 1 || user == null;
      });
    }
  }

  Order _generateMockOrder(int tableId, String tableName) {
    return Order(
      id: 100 + tableId,
      userId: 1,
      distributorId: 1,
      code: 'BILL-${tableName.toUpperCase()}',
      customerName:
          tableName == 'Mang về' ? 'Khách mang về' : 'Khách tại $tableName',
      customerPhone: '',
      customerEmail: '',
      shippingAddress: '',
      paymentMethod: 'CASH',
      items: [
        OrderItem(
          productId: 1,
          quantity: 2,
          unitPrice: 25000,
          product: Product(id: 1, name: 'Cà phê sữa', price: 25000),
        ),
      ],
      subtotal: 50000,
      totalAmount: 50000,
      createdAt: DateTime.now().toIso8601String(),
    );
  }

  void _updateTableStatus(int id, TableStatus newStatus) {
    setState(() {
      final index = _mockTables.indexWhere((t) => t.id == id);
      if (index != -1) {
        final table = _mockTables[index];
        _mockTables[index] = table.copyWith(status: newStatus);

        if (newStatus == TableStatus.empty) {
          _tempOrders.remove(id);
        }
      }
    });
  }

  void _updateTableOrders(TableModel table, List<OrderItem> newItems) {
    setState(() {
      final existingOrder = _tempOrders[table.id];
      if (existingOrder != null) {
        final updatedItems = [...existingOrder.items, ...newItems];
        double total = 0;
        for (var item in updatedItems) {
          total += item.quantity * item.unitPrice;
        }
        _tempOrders[table.id] = Order(
          id: existingOrder.id,
          userId: existingOrder.userId,
          distributorId: existingOrder.distributorId,
          code: existingOrder.code,
          customerName: existingOrder.customerName,
          customerPhone: existingOrder.customerPhone,
          customerEmail: existingOrder.customerEmail,
          shippingAddress: existingOrder.shippingAddress,
          paymentMethod: existingOrder.paymentMethod,
          items: updatedItems,
          subtotal: total,
          totalAmount: total,
          createdAt: existingOrder.createdAt,
        );
      } else {
        double total = 0;
        for (var item in newItems) {
          total += item.quantity * item.unitPrice;
        }
        _tempOrders[table.id] = Order(
          id: 100 + table.id,
          userId: 1,
          distributorId: 1,
          code: 'BILL-${table.name.toUpperCase()}',
          customerName:
              table.name == 'Mang về'
                  ? 'Khách mang về'
                  : 'Khách tại ${table.name}',
          customerPhone: '',
          customerEmail: '',
          shippingAddress: '',
          paymentMethod: 'CASH',
          items: newItems,
          subtotal: total,
          totalAmount: total,
          createdAt: DateTime.now().toIso8601String(),
        );
      }
    });
  }

  void _confirmCancelOrder(TableModel table) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Xác nhận xóa'),
            content: Text(
              'Xóa toàn bộ món và đặt ${table.name} về trạng thái TRỐNG?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Bỏ qua'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Close bottom sheet
                  _updateTableStatus(table.id, TableStatus.empty);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Bàn ${table.name} đã được dọn trống'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text(
                  'Xác nhận xóa',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      backgroundColor: AppColors.bgLightGrey,
      hasSafeArea: false,
      appBar: AppAppBar(
        title: TitleAppbarText(title: 'Quản lý bàn'),
        actions: [
          if (_isAdmin)
            IconButton(
              icon: const Icon(
                Icons.add_box_rounded,
                color: AppColors.primaryBlue,
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Chức năng dành cho Quản lý Doanh nghiệp: Thêm bàn mới',
                    ),
                  ),
                );
              },
            ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Column(
            children: [
              SizedBox(height: 16.h),
              _buildStatusLegend(),
              SizedBox(height: 20.h),
              Expanded(child: _buildTableGrid()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusLegend() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 8.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children:
            TableStatus.values.map((status) {
              return Row(
                children: [
                  Container(
                    width: 10.w,
                    height: 10.w,
                    decoration: BoxDecoration(
                      color: status.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: 6.w),
                  Text(
                    status.label,
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              );
            }).toList(),
      ),
    );
  }

  Widget _buildTableGrid() {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.1,
        crossAxisSpacing: 16.w,
        mainAxisSpacing: 16.w,
      ),
      itemCount: _mockTables.length,
      padding: EdgeInsets.only(bottom: 24.h),
      itemBuilder: (context, index) {
        final table = _mockTables[index];
        return _buildTableItem(table);
      },
    );
  }

  Widget _buildTableItem(TableModel table) {
    return GestureDetector(
      onTap: () => _showTableAction(table),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(5),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Status Pill (Top Right)
            Positioned(
              top: 12.h,
              right: 12.w,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: table.status.color.withAlpha(25),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  table.status.label,
                  style: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.bold,
                    color: table.status.color,
                  ),
                ),
              ),
            ),

            // Main Content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withAlpha(10),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      table.id == 0
                          ? Icons.shopping_bag_rounded
                          : Icons.table_bar_rounded,
                      color: AppColors.primaryBlue,
                      size: 28.sp,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    table.name,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTableAction(TableModel table) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle line
                Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
                SizedBox(height: 24.h),

                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(10.w),
                      decoration: BoxDecoration(
                        color: table.status.color.withAlpha(20),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Icon(
                        Icons.table_bar_rounded,
                        color: table.status.color,
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          table.name,
                          style: TextStyle(
                            fontSize: 20.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Trạng thái: ${table.status.label}',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Text(
                  'Tác vụ bàn',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_currentUser != null)
                  Padding(
                    padding: EdgeInsets.only(top: 4.h),
                    child: Text(
                      'Đang đăng nhập: ${_currentUser!.userName} (${_isAdmin ? "Quản trị" : "Nhân viên"})',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                SizedBox(height: 20.h),
                if (table.status == TableStatus.empty)
                  _buildActionButton(
                    icon: Icons.add_shopping_cart_rounded,
                    label: 'Tạo đơn hàng mới',
                    color: AppColors.primaryBlue,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProductsListPage(table: table),
                        ),
                      ).then((data) {
                        if (data is List<OrderItem>) {
                          _updateTableOrders(table, data);
                          _updateTableStatus(table.id, TableStatus.occupied);
                        }
                      });
                    },
                  ),

                if (table.status == TableStatus.occupied) ...[
                  _buildActionButton(
                    icon: Icons.receipt_long_rounded,
                    label: 'Xem đơn hàng',
                    color: const Color(0xFF1E88E5),
                    onTap: () {
                      final currentOrder =
                          _tempOrders[table.id] ??
                          _generateMockOrder(table.id, table.name);

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => TableOrderDetailPage(
                                table: table,
                                initialOrder: currentOrder,
                              ),
                        ),
                      );
                    },
                  ),
                  _buildActionButton(
                    icon: Icons.move_up_rounded,
                    label: 'Chuyển bàn / Gộp bàn',
                    color: Colors.purple,
                    onTap: () => _showTablePicker(table, 'Chuyển / Gộp'),
                  ),
                  _buildActionButton(
                    icon: Icons.cancel_presentation_rounded,
                    label: 'Xóa đơn & Giải phóng bàn',
                    color: Colors.redAccent,
                    onTap: () => _confirmCancelOrder(table),
                  ),
                ],

                _buildActionButton(
                  icon: Icons.sync_rounded,
                  label: 'Thay đổi trạng thái',
                  color: Colors.grey[700]!,
                  onTap: () => _showStatusPicker(table),
                ),

                if (_isAdmin) ...[
                  const Divider(),
                  _buildActionButton(
                    icon: Icons.edit_note_rounded,
                    label: 'Sửa thông tin bàn',
                    color: Colors.orange.shade700,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Chức năng Quản lý: Chỉnh sửa tên/sức chứa',
                          ),
                        ),
                      );
                    },
                  ),
                  _buildActionButton(
                    icon: Icons.delete_forever_rounded,
                    label: 'Xóa bàn',
                    color: Colors.red.shade800,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Chức năng Quản lý: Xóa bàn khỏi sơ đồ',
                          ),
                        ),
                      );
                    },
                  ),
                ],
                SizedBox(height: 12.h),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: InkWell(
        onTap: () {
          Navigator.pop(context);
          onTap();
        },
        borderRadius: BorderRadius.circular(16.r),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: Colors.grey[100]!),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 22.sp),
              SizedBox(width: 16.w),
              Text(
                label,
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.grey[400],
                size: 20.sp,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showStatusPicker(TableModel table) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            padding: EdgeInsets.all(24.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Chọn trạng thái cho ${table.name}',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 20.h),
                ...TableStatus.values.map(
                  (status) => ListTile(
                    leading: Icon(
                      Icons.circle,
                      color: status.color,
                      size: 16.sp,
                    ),
                    title: Text(status.label),
                    onTap: () {
                      _updateTableStatus(table.id, status);
                      Navigator.pop(context); // Close picker
                    },
                  ),
                ),
              ],
            ),
          ),
    );
  }

  void _showTablePicker(TableModel fromTable, String action) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            padding: EdgeInsets.all(24.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Chọn bàn để $action',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 16.h),
                SizedBox(
                  height: 250.h,
                  child: ListView(
                    children:
                        _mockTables
                            .where((t) => t.id != fromTable.id)
                            .map(
                              (t) => ListTile(
                                leading: Icon(
                                  Icons.table_bar_rounded,
                                  color:
                                      t.status == TableStatus.empty
                                          ? Colors.grey
                                          : AppColors.primaryBlue,
                                ),
                                title: Text(t.name),
                                subtitle: Text(t.status.label),
                                onTap: () {
                                  _updateTableStatus(
                                    fromTable.id,
                                    TableStatus.empty,
                                  );
                                  _updateTableStatus(
                                    t.id,
                                    TableStatus.occupied,
                                  );
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Đã ${action.toLowerCase()} từ ${fromTable.name} sang ${t.name}',
                                      ),
                                    ),
                                  );
                                },
                              ),
                            )
                            .toList(),
                  ),
                ),
              ],
            ),
          ),
    );
  }
}
