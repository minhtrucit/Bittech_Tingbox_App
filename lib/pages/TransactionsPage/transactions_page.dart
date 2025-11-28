import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../ting_box.dart';

class TransactionsPage extends StatefulWidget {
  const TransactionsPage({super.key});

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  String _selectedFilter = 'all'; // 'all', 'income', 'expense'

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
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded, color: Colors.black),
            onPressed: () {
              // Show add transaction dialog
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Filter Tabs
            Container(
              color: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
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
          color: isSelected ? AppColors.primaryBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(
            color: isSelected ? AppColors.primaryBlue : Colors.grey[300]!,
            width: 1,
          ),
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
    // Sample transaction data
    final allTransactions = [
      {
        'title': 'Bán hàng #001',
        'time': '10:30 AM',
        'amount': '+500.000đ',
        'isIncome': true,
        'icon': Icons.shopping_bag,
        'color': Colors.green.withAlpha(25),
        'iconColor': Colors.green,
      },
      {
        'title': 'Chi phí vận chuyển',
        'time': '09:15 AM',
        'amount': '-50.000đ',
        'isIncome': false,
        'icon': Icons.local_shipping,
        'color': Colors.red.withAlpha(25),
        'iconColor': Colors.red,
      },
      {
        'title': 'Bán hàng #002',
        'time': '08:45 AM',
        'amount': '+1.200.000đ',
        'isIncome': true,
        'icon': Icons.shopping_bag,
        'color': Colors.green.withAlpha(25),
        'iconColor': Colors.green,
      },
      {
        'title': 'Chi phí điện nước',
        'time': '08:00 AM',
        'amount': '-200.000đ',
        'isIncome': false,
        'icon': Icons.receipt_long,
        'color': Colors.red.withAlpha(25),
        'iconColor': Colors.red,
      },
      {
        'title': 'Bán hàng #003',
        'time': 'Hôm qua',
        'amount': '+750.000đ',
        'isIncome': true,
        'icon': Icons.shopping_bag,
        'color': Colors.green.withAlpha(25),
        'iconColor': Colors.green,
      },
      {
        'title': 'Chi phí thuê mặt bằng',
        'time': 'Hôm qua',
        'amount': '-2.000.000đ',
        'isIncome': false,
        'icon': Icons.home,
        'color': Colors.red.withAlpha(25),
        'iconColor': Colors.red,
      },
    ];

    // Filter transactions based on selected filter
    final filteredTransactions =
        allTransactions.where((tx) {
          if (_selectedFilter == 'all') return true;
          if (_selectedFilter == 'income') return tx['isIncome'] == true;
          if (_selectedFilter == 'expense') return tx['isIncome'] == false;
          return true;
        }).toList();

    return filteredTransactions.map((tx) => _buildTransactionItem(tx)).toList();
  }

  Widget _buildTransactionItem(Map<String, dynamic> transaction) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: transaction['color'] as Color,
              shape: BoxShape.circle,
            ),
            child: Icon(
              transaction['icon'] as IconData,
              color: transaction['iconColor'] as Color,
              size: 24.sp,
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction['title'] as String,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  transaction['time'] as String,
                  style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                ),
              ],
            ),
          ),
          Text(
            transaction['amount'] as String,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color:
                  (transaction['isIncome'] as bool) ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
    );
  }
}
