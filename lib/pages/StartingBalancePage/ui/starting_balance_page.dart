import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:ting_box/utils/currency_input_formatter.dart';
import '../../../ting_box.dart';

class StartingBalancePage extends StatefulWidget {
  const StartingBalancePage({super.key});

  @override
  State<StartingBalancePage> createState() => _StartingBalancePageState();
}

class _StartingBalancePageState extends State<StartingBalancePage> {
  final TextEditingController _amountController = TextEditingController();
  final DateTime _currentDate = DateTime.now();
  String? formattedDate;
  String _selectedType = 'cash'; // 'cash' or 'bank'
  bool _hasError = false;

  double _cashBalance = 1250000; // Sample data
  double _bankBalance = 0;
  double lastTotalBalance = 1250000;

  @override
  void initState() {
    super.initState();
    formattedDate = DateFormat('EEEE, dd MMMM yyyy').format(_currentDate);
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _saveStartingBalance() {
    final amountText = _amountController.text.replaceAll(',', '');
    final amount = double.tryParse(amountText);

    if (amount == null || amount <= 0) {
      setState(() {
        _hasError = true;
      });
      return;
    }

    // Create fund entry data
    final fundEntry = {
      "name": "Sổ ngày ${DateFormat('dd/MM/yyyy').format(_currentDate)}",
      "date": DateFormat('yyyy-MM-dd').format(_currentDate),
      "openingAmount": amount,
      "configId": 1,
      "type": _selectedType == 'cash' ? 'cash' : 'bank',
    };

    // TODO: Send to backend API
    debugPrint('Fund Entry: $fundEntry');

    setState(() {
      _hasError = false;
      if (_selectedType == 'cash') {
        _cashBalance = amount;
      } else {
        _bankBalance = amount;
      }
      _amountController.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Đã thêm sổ quỹ ${_selectedType == 'cash' ? 'tiền mặt' : 'tài khoản'} thành công',
        ),
        backgroundColor: Colors.green,
      ),
    );
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
        title: const TitleAppbarText(title: 'Nhập Quỹ Đầu Kỳ'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Center(
                child: Text(
                  formattedDate ?? 'N/A',
                  style: TextStyle(fontSize: 14.sp, color: Colors.grey),
                ),
              ),
              SizedBox(height: 24.h),

              // Balance Summary Card
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withAlpha(25),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Số dư cuối ngày hôm qua',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      lastTotalBalance.formatMoney(),
                      style: TextStyle(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                    SizedBox(height: 16.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tiền mặt',
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: Colors.grey[600],
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              _cashBalance.formatMoney(),
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Tài khoản',
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: Colors.grey[600],
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              _bankBalance.formatMoney(),
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24.h),

              // Type Selection
              Text(
                'Loại',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 12.h),
              Row(
                children: [
                  Expanded(
                    child: _buildTypeButton(
                      label: 'Tiền mặt',
                      icon: Icons.money,
                      type: 'cash',
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: _buildTypeButton(
                      label: 'Tài khoản',
                      icon: Icons.account_balance_wallet,
                      type: 'bank',
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24.h),

              // Amount Input
              Text(
                'Số dư',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 12.h),
              _buildAmountField(),
              SizedBox(height: 16.h),

              // Add Button
              SizedBox(
                width: double.infinity,
                height: 50.h,
                child: OutlinedButton(
                  onPressed: _saveStartingBalance,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.primaryBlue, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  child: Text(
                    'Thêm',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeButton({
    required String label,
    required IconData icon,
    required String type,
  }) {
    final isSelected = _selectedType == type;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedType = type;
          _hasError = false;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16.h),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryBlue : Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isSelected ? AppColors.primaryBlue : Colors.grey[300]!,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey[600],
              size: 20.sp,
            ),
            SizedBox(width: 8.w),
            Text(
              label,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: _hasError ? Colors.red : Colors.transparent,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _amountController,
        keyboardType: TextInputType.number,
        style: TextStyle(fontSize: 16.sp, color: Colors.black),
        inputFormatters: [CurrencyInputFormatter()],
        onChanged: (value) {
          if (_hasError && value.isNotEmpty) {
            setState(() {
              _hasError = false;
            });
          }
        },
        decoration: InputDecoration(
          hintText: 'Nhập số dư',
          hintStyle: TextStyle(fontSize: 16.sp, color: Colors.grey[400]),
          suffixIcon: Icon(
            Icons.attach_money,
            color: _hasError ? Colors.red : Colors.grey[400],
            size: 24.sp,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: BorderSide.none,
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: 24.w,
            vertical: 16.h,
          ),
        ),
      ),
    );
  }
}
