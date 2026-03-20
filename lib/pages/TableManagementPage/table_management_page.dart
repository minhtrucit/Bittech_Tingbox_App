import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ting_box/pages/TableManagementPage/table_order_detail_page.dart';
import '../../../models/table_model.dart';
import '../../../models/zone_model.dart';
import '../../../ting_box.dart';
import 'bloc/table_bloc.dart';
import 'bloc/table_event.dart';
import 'bloc/table_state.dart';

class TableManagementPage extends StatefulWidget {
  const TableManagementPage({super.key});

  @override
  State<TableManagementPage> createState() => _TableManagementPageState();
}

class _TableManagementPageState extends State<TableManagementPage> {
  bool _canManageInfra = false;
   bool _canManageOrders = false;
  int? _roleId;
  int? _userId;
  int? _configId;
  ZoneModel? _selectedZone;
  List<ZoneModel> _zones = [];
  TableModel? _targetTable;

  @override
  void initState() {
    super.initState();
    _loadUserAndConfig();
  }

  Future<void> _loadUserAndConfig() async {
    final user = await UserRepository.getUser();
    final configIdStr = await UserRepository.getConfigId();
    if (mounted) {
      setState(() {
        _canManageInfra = user?.canManageInfrastructure ?? false;
        _canManageOrders = user?.canManageOrders ?? false;
        _userId = user?.id;
        _roleId = user?.roleId;
        if (configIdStr != null) {
          _configId = int.tryParse(configIdStr);
        }
      });

      if (_configId != null) {
        context.read<TableBloc>().add(FetchZones(_configId!));
        context.read<TableBloc>().add(SubscribeToTableUpdates(_configId!));
      }
    }
  }

  @override
  void dispose() {
    context.read<TableBloc>().add(UnsubscribeFromTableUpdates());
    super.dispose();
  }

  void _onZoneSelected(ZoneModel zone) {
    setState(() {
      _selectedZone = zone;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      backgroundColor: AppColors.bgLightGrey,
      hasSafeArea: false,
      appBar: AppAppBar(
        title: TitleAppbarText(title: 'Quản lý bàn'),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.refresh_rounded,
              color: AppColors.primaryBlue,
            ),
            onPressed: () {
              if (_configId != null) {
                context.read<TableBloc>().add(FetchZones(_configId!));
              }
            },
          ),
          if (_canManageInfra)
            IconButton(
              icon: const Icon(
                Icons.add_box_rounded,
                color: AppColors.primaryBlue,
              ),
              onPressed: () => _showCreateZoneOrTable(),
            ),
        ],
      ),
      body: SafeArea(
        child: BlocConsumer<TableBloc, TableState>(
          listener: (tableContext, state) {
            if (state is TableActionSuccess) {
              NotificationUtils.showSuccess(
                context: context,
                title: 'Thành công',
                description: state.message,
              );
              if (_configId != null) {
                context.read<TableBloc>().add(FetchZones(_configId!));
              }
            } else if (state is TableActionFailure) {
              NotificationUtils.showError(
                context: context,
                title: 'Lỗi',
                description: state.message,
              );
            } else if (state is TableOrderLoaded) {
              if (_targetTable != null) {
                final tableToOpen = _targetTable!;
                _targetTable = null;

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => TableOrderDetailPage(
                          table: tableToOpen,
                          initialOrder: state.order,
                        ),
                  ),
                ).then((_) {
                  if (!tableContext.mounted) return;
                  if (_configId != null) {
                    context.read<TableBloc>().add(FetchZones(_configId!));
                  }
                });
              }
            }
          },
          builder: (context, state) {
            if (state is ZonesLoaded) {
              _zones = state.zones;
              if (_selectedZone == null && _zones.isNotEmpty) {
                _selectedZone = _zones.first;
              } else if (_selectedZone != null && _zones.isNotEmpty) {
                try {
                  _selectedZone = _zones.firstWhere(
                    (z) => z.id == _selectedZone!.id,
                  );
                } catch (_) {
                  _selectedZone = _zones.first;
                }
              }
            }

            if (state is TableLoading && _zones.isEmpty) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primaryBlue),
              );
            }

            if (_zones.isNotEmpty) {
              return Column(
                children: [
                  if (state is TableLoading)
                    const LinearProgressIndicator(
                      backgroundColor: Colors.transparent,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.primaryBlue,
                      ),
                      minHeight: 2,
                    ),
                  _buildZoneTabs(_zones),
                  SizedBox(height: 16.h),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: _buildStatusLegend(
                      (_selectedZone?.tables ?? [])
                          .where((t) => t.isActive)
                          .toList(),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      child: _buildTableGrid(
                        (_selectedZone?.tables ?? [])
                            .where((t) => t.isActive)
                            .toList(),
                      ),
                    ),
                  ),
                ],
              );
            }

            // If empty and not loading, or other initial states
            if (_zones.isEmpty && state is! TableLoading) {
              return _buildEmptyState(
                'Không có dữ liệu. Vui lòng làm mới hoặc tạo khu vực.',
              );
            }

            return const Center(
              child: CircularProgressIndicator(color: AppColors.primaryBlue),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.table_bar_outlined,
              size: 64.sp,
              color: Colors.grey[300],
            ),
            SizedBox(height: 16.h),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 14.sp),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildZoneTabs(List<ZoneModel> zones) {
    return Container(
      height: 50.h,
      margin: EdgeInsets.only(top: 12.h),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        itemCount: zones.length,
        itemBuilder: (context, index) {
          final zone = zones[index];
          final isSelected = _selectedZone?.id == zone.id;
          return Padding(
            padding: EdgeInsets.only(right: 12.w),
            child: ChoiceChip(
              label: Text(zone.name),
              selected: isSelected,
              onSelected: (_) => _onZoneSelected(zone),
              selectedColor: AppColors.primaryBlue,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.r),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusLegend(List<TableModel> tables) {
    return Container(
      padding: EdgeInsets.all(12.w),
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
      child: Wrap(
        alignment: WrapAlignment.start,
        spacing: 12.w,
        runSpacing: 8.h,
        children:
            TableStatus.values.map((status) {
              final count = tables.where((t) => t.status == status).length;
              return Row(
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
                  SizedBox(width: 4.w),
                  Text(
                    '${status.label} ($count)',
                    style: TextStyle(fontSize: 11.sp, color: Colors.grey[700]),
                  ),
                ],
              );
            }).toList(),
      ),
    );
  }

  Widget _buildTableGrid(List<TableModel> tables) {
    if (tables.isEmpty) {
      return Center(
        child: Text(
          'Chưa có bàn nào trong khu vực này.',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.1,
        crossAxisSpacing: 16.w,
        mainAxisSpacing: 16.w,
      ),
      itemCount: tables.length,
      padding: EdgeInsets.only(bottom: 24.h),
      itemBuilder: (context, index) {
        final table = tables[index];
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
                      Icons.table_bar_rounded,
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
      builder: (sContext) {
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
              SizedBox(height: 24.h),
              if (_roleId == 5) ...[
                const Divider(),
                SizedBox(height: 12.h),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Cập nhật trạng thái bàn',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
                SizedBox(height: 16.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatusOption(sContext, table, TableStatus.empty),
                    _buildStatusOption(sContext, table, TableStatus.occupied),
                    _buildStatusOption(sContext, table, TableStatus.reserved),
                  ],
                ),
                SizedBox(height: 16.h),
                const Divider(),
                SizedBox(height: 12.h),
              ],
              SizedBox(height: 12.h),
              if (table.status == TableStatus.empty && _canManageOrders)
                _buildActionButton(
                  sContext,
                  icon: Icons.add_shopping_cart_rounded,
                  label: 'Gọi món',
                  color: AppColors.primaryBlue,
                  onTap: () {
                    final tableBloc = context.read<TableBloc>();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProductsListPage(table: table),
                      ),
                    ).then((data) {
                      if (!mounted) return;
                      if (data is List<OrderItem>) {
                        final itemsMap =
                            data
                                .map(
                                  (item) => {
                                    'productId': item.productId,
                                    'quantity': item.quantity,
                                    'unitPrice': item.unitPrice,
                                  },
                                )
                                .toList();

                        tableBloc.add(
                          CreateTempOrder(
                            userId: _userId ?? 1,
                            tableId: table.id,
                            items: itemsMap,
                          ),
                        );
                      }
                    });
                  },
                ),
              if (table.status == TableStatus.occupied && _canManageOrders) ...[
                _buildActionButton(
                  sContext,
                  icon: Icons.receipt_long_rounded,
                  label: 'Chi tiết & Thanh toán',
                  color: const Color(0xFF1E88E5),
                  onTap: () {
                    final tableBloc = context.read<TableBloc>();
                    if (table.currentOrder != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => TableOrderDetailPage(
                                table: table,
                                initialOrder: table.currentOrder!,
                              ),
                        ),
                      ).then((_) {
                        if (!mounted) return;
                        if (_configId != null) {
                          tableBloc.add(FetchZones(_configId!));
                        }
                      });
                    } else if (table.currentOrderId != null) {
                      _targetTable = table;
                      tableBloc.add(FetchTableOrder(table.currentOrderId!));
                    } else {
                      NotificationUtils.showError(
                        context: context,
                        title: 'Lỗi',
                        description: 'Không tìm thấy ID đơn hàng cho bàn này.',
                      );
                    }
                  },
                ),
                _buildActionButton(
                  sContext,
                  icon: Icons.move_up_rounded,
                  label: 'Chuyển bàn',
                  color: Colors.deepPurple,
                  onTap:
                      () => _showTableSelectionDialog(
                        'Chuyển từ ${table.name} sang:',
                        (toTable) {
                          if (!mounted) return;
                          if (table.currentOrderId != null) {
                            context.read<TableBloc>().add(
                              MoveTableOrder(
                                orderId: table.currentOrderId!,
                                toTableId: toTable.id,
                              ),
                            );
                          }
                        },
                        excludeId: table.id,
                        availableOnly: true,
                      ),
                ),
                _buildActionButton(
                  sContext,
                  icon: Icons.merge_type_rounded,
                  label: 'Gộp bàn',
                  color: Colors.indigo,
                  onTap:
                      () => _showTableSelectionDialog(
                        'Gộp từ ${table.name} vào:',
                        (toTable) {
                          if (!mounted) return;
                          if (table.currentOrderId != null &&
                              toTable.currentOrderId != null) {
                            context.read<TableBloc>().add(
                              MergeTableOrder(
                                sourceOrderId: table.currentOrderId!,
                                destinationOrderId: toTable.currentOrderId!,
                              ),
                            );
                          }
                        },
                        excludeId: table.id,
                        occupiedOnly: true,
                      ),
                ),
              ],
              if (_canManageInfra)
                _buildActionButton(
                  sContext,
                  icon: Icons.edit_rounded,
                  label: 'Sửa thông tin bàn',
                  color: Colors.orange,
                  onTap: () => _showEditTable(table),
                ),
              if (_canManageInfra)
                _buildActionButton(
                  sContext,
                  icon: Icons.delete_forever_rounded,
                  label: 'Xóa bàn',
                  color: Colors.red,
                  onTap: () => _confirmDeleteTable(table),
                ),
              SizedBox(height: 12.h),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusOption(
    BuildContext context,
    TableModel table,
    TableStatus status,
  ) {
    final isSelected = table.status == status;
    return InkWell(
      onTap: () {
        if (isSelected) return;
        Navigator.pop(context);
        context.read<TableBloc>().add(
          UpdateTable(table.id, {'status': status.name}),
        );
      },
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        width: 100.w,
        padding: EdgeInsets.symmetric(vertical: 12.h),
        decoration: BoxDecoration(
          color: isSelected ? status.color.withAlpha(20) : Colors.grey[50],
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isSelected ? status.color : Colors.grey[200]!,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              isSelected ? Icons.check_circle_rounded : Icons.circle_outlined,
              size: 20.sp,
              color: isSelected ? status.color : Colors.grey[400],
            ),
            SizedBox(height: 4.h),
            Text(
              status.label,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? status.color : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
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

  void _showCreateZoneOrTable() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (sContext) => Container(
            padding: EdgeInsets.all(24.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Quản trị',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 20.h),
                _buildActionButton(
                  context,
                  icon: Icons.grid_view_rounded,
                  label: 'Thêm khu vực mới',
                  color: Colors.teal,
                  onTap: () => _showAddZoneDialog(),
                ),
                _buildActionButton(
                  context,
                  icon: Icons.add_circle_outline_rounded,
                  label: 'Thêm bàn mới',
                  color: Colors.blueAccent,
                  onTap: () => _showAddTableDialog(),
                ),
              ],
            ),
          ),
    );
  }

  void _showAddZoneDialog() {
    final nameController = TextEditingController();
    showDialog(
      context: context,
        builder: (dContext) => AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.r),
            ),
            title: Text(
              'Thêm khu vực',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryBlue,
              ),
            ),
            content: TextField(
              controller: nameController,
              decoration: InputDecoration(
                hintText: 'Tên khu vực',
                filled: true,
                fillColor: Colors.grey[50],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(color: Colors.grey[200]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(color: AppColors.primaryBlue),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(color: Colors.grey[200]!),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dContext),
                child: Text('Hủy', style: TextStyle(color: Colors.grey[600])),
              ),
              ElevatedButton(
                onPressed: () {
                  if (nameController.text.isNotEmpty && _configId != null) {
                    context.read<TableBloc>().add(
                      CreateZone({
                        'name': nameController.text,
                        'configId': _configId,
                      }),
                    );
                    Navigator.pop(dContext);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  elevation: 0,
                ),
                child: const Text('Lưu', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
    );
  }

  void _showAddTableDialog() {
    if (_selectedZone == null) return;
    final nameController = TextEditingController();
    showDialog(
      context: context,
        builder: (dContext) => AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.r),
            ),
            title: Text(
              'Thêm bàn vào ${_selectedZone!.name}',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryBlue,
              ),
            ),
            content: TextField(
              controller: nameController,
              decoration: InputDecoration(
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(color: AppColors.primaryBlue),
                ),
                hintText: 'Tên bàn',
                filled: true,
                fillColor: Colors.grey[50],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(color: Colors.grey[200]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(color: Colors.grey[200]!),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dContext),
                child: Text('Hủy', style: TextStyle(color: Colors.grey[600])),
              ),
              ElevatedButton(
                onPressed: () {
                  if (nameController.text.isNotEmpty) {
                    context.read<TableBloc>().add(
                      CreateTable({
                        'name': nameController.text,
                        'zoneId': _selectedZone!.id,
                        'status': 'empty',
                      }),
                    );
                    Navigator.pop(dContext);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  elevation: 0,
                ),
                child: const Text('Lưu', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
    );
  }

  void _showEditTable(TableModel table) {
    final nameController = TextEditingController(text: table.name);
    showDialog(
      context: context,
        builder: (dContext) => AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.r),
            ),
            title: Text(
              'Sửa thông tin bàn',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryBlue,
              ),
            ),
            content: TextField(
              controller: nameController,
              decoration: InputDecoration(
                hintText: 'Tên bàn',
                filled: true,
                fillColor: Colors.grey[50],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(color: Colors.grey[200]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(color: Colors.grey[200]!),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dContext),
                child: Text('Hủy', style: TextStyle(color: Colors.grey[600])),
              ),
              ElevatedButton(
                onPressed: () {
                  if (nameController.text.isNotEmpty) {
                    context.read<TableBloc>().add(
                      UpdateTable(table.id, {'name': nameController.text}),
                    );
                    Navigator.pop(dContext);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Cập nhật',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );
  }

  void _confirmDeleteTable(TableModel table) {
    showDialog(
      context: context,
        builder: (dContext) => AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.r),
            ),
            title: const Text(
              'Xác nhận xóa',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
            ),
            content: Text(
              'Bạn có chắc chắn muốn xóa ${table.name}?',
              style: TextStyle(fontSize: 15.sp),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dContext),
                child: Text('Hủy', style: TextStyle(color: Colors.grey[600])),
              ),
              ElevatedButton(
                onPressed: () {
                  context.read<TableBloc>().add(DeleteTable(table.id));
                  Navigator.pop(dContext);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[50],
                  foregroundColor: Colors.red,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
                child: const Text(
                  'Xóa',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
    );
  }

  void _showTableSelectionDialog(
    String title,
    Function(TableModel) onSelected, {
    int? excludeId,
    bool availableOnly = false,
    bool occupiedOnly = false,
  }) {
    List<TableModel> allTables = [];
    for (var zone in _zones) {
      if (zone.tables != null) {
        allTables.addAll(zone.tables!.where((t) => t.isActive));
      }
    }

    if (excludeId != null) {
      allTables.removeWhere((t) => t.id == excludeId);
    }
    if (availableOnly) {
      allTables.removeWhere((t) => t.status != TableStatus.empty);
    }
    if (occupiedOnly) {
      allTables.removeWhere((t) => t.status != TableStatus.occupied);
    }

    showDialog(
      context: context,
      builder:
          (dContext) => AlertDialog(
            backgroundColor: Colors.white,
            title: Text(
              title,
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
            ),
            content: SizedBox(
              width: double.maxFinite,
              child:
                  allTables.isEmpty
                      ? const Center(child: Text('Không có bàn nào phù hợp.'))
                      : ListView.separated(
                        shrinkWrap: true,
                        itemCount: allTables.length,
                        separatorBuilder: (_, __) => const Divider(),
                        itemBuilder: (context, index) {
                          final tableSelection = allTables[index];
                          return ListTile(
                            title: Text(tableSelection.name),
                            trailing: Container(
                              width: 8.w,
                              height: 8.w,
                              decoration: BoxDecoration(
                                color: tableSelection.status.color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            onTap: () {
                              Navigator.pop(dContext);
                              onSelected(tableSelection);
                            },
                          );
                        },
                      ),
            ),
          ),
    );
  }
}
