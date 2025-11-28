import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../ting_box.dart';

class TransactionsPage extends StatefulWidget {
  final List<StatisticTransaction> transactions;

  const TransactionsPage({super.key, required this.transactions});

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  String _selectedFilter = 'all'; // 'all', 'income', 'expense'
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      backgroundColor: AppColors.bgLightGrey,
      hasSafeArea: false,
      appBar: AppAppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        centerTitle: true,
        title: const TitleAppbarText(title: 'Giao Dịch'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Bar
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 8.h),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(5),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm theo nội dung...',
                    hintStyle: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 14.sp,
                    ),
                    prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 14.h,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {});
                  },
                ),
              ),
            ),

            // Filter Tabs
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              child: Row(
                children: [
                  Expanded(
                    child: _buildFilterTab(label: 'Tất cả', value: 'all'),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: _buildFilterTab(label: 'Thu', value: 'income'),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: _buildFilterTab(label: 'Chi', value: 'expense'),
                  ),
                ],
              ),
            ),

            // Transactions List
            Expanded(
              child: ListView(
                padding: EdgeInsets.all(16.w),
                children: _getFilteredTransactions(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterTab({required String label, required String value}) {
    final isSelected = _selectedFilter == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = value;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 10.h),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryBlue : Colors.white,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(
            color: isSelected ? AppColors.primaryBlue : Colors.transparent,
            width: 1,
          ),
          boxShadow:
              isSelected
                  ? []
                  : [
                    BoxShadow(
                      color: Colors.black.withAlpha(5),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : Colors.grey[600],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _getFilteredTransactions() {
    final filtered =
        widget.transactions.where((tx) {
          // Filter by type
          final isIncome = (tx.amount ?? 0) >= 0;
          if (_selectedFilter == 'income' && !isIncome) return false;
          if (_selectedFilter == 'expense' && isIncome) return false;

          // Filter by search text (title/subject)
          if (_searchController.text.isNotEmpty) {
            final query = _searchController.text.toLowerCase();
            final desc = (tx.subject ?? '').toLowerCase();
            if (!desc.contains(query)) return false;
          }

          return true;
        }).toList();

    if (filtered.isEmpty) {
      return [
        Padding(
          padding: EdgeInsets.only(top: 40.h),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.search_off, size: 48.sp, color: Colors.grey[400]),
                SizedBox(height: 16.h),
                Text(
                  'Không tìm thấy giao dịch nào',
                  style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ),
      ];
    }

    return filtered.map((tx) => _buildTransactionItem(tx)).toList();
  }

  Widget _buildTransactionItem(StatisticTransaction tx) {
    final isIncome = (tx.amount ?? 0) >= 0;
    final color = isIncome ? Colors.green : Colors.red;
    final icon = isIncome ? Icons.arrow_downward : Icons.arrow_upward;
    final bgColor = isIncome ? Colors.green[50] : Colors.red[50];

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 24.sp),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.subject ?? 'Giao dịch',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  tx.date != null
                      ? DateFormat('HH:mm dd/MM/yyyy').format(tx.date!)
                      : '',
                  style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                ),
              ],
            ),
          ),
          Text(
            (tx.amount ?? 0).formatMoney(),
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
