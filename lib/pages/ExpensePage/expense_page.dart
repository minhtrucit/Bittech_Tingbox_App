import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../ting_box.dart';
import 'widgets/expense_amount_field.dart';
import 'widgets/expense_date_picker.dart';
import 'widgets/expense_type_selector.dart';
import 'widgets/expense_note_field.dart';

class ExpensePage extends StatefulWidget {
  const ExpensePage({super.key});

  @override
  State<ExpensePage> createState() => _ExpensePageState();
}

class _ExpensePageState extends State<ExpensePage> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String _selectedType = 'cash';
  bool _hasError = false;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _saveExpense() {
    final amountText = _amountController.text.replaceAll(',', '');
    final amount = double.tryParse(amountText);

    if (amount == null || amount <= 0) {
      setState(() {
        _hasError = true;
      });
      return;
    }

    // Create expense entry data
    final expenseEntry = {
      "amount": amount,
      "date": DateFormat('yyyy-MM-dd').format(_selectedDate),
      "type": _selectedType,
      "note": _noteController.text.trim(),
      "configId": 1,
    };

    // TODO: Send to backend API
    debugPrint('Expense Entry: $expenseEntry');

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã lưu chi phí thành công'),
        backgroundColor: Colors.green,
      ),
    );

    // Clear form
    setState(() {
      _amountController.clear();
      _noteController.clear();
      _selectedDate = DateTime.now();
      _hasError = false;
    });
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
        title: const TitleAppbarText(title: 'Nhập Chi phí'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Amount Field
                    ExpenseAmountField(
                      controller: _amountController,
                      hasError: _hasError,
                      onChanged: (value) {
                        if (_hasError && value.isNotEmpty) {
                          setState(() {
                            _hasError = false;
                          });
                        }
                      },
                    ),
                    SizedBox(height: 24.h),

                    // Date Picker
                    ExpenseDatePicker(
                      selectedDate: _selectedDate,
                      onDateChanged: (date) {
                        setState(() {
                          _selectedDate = date;
                        });
                      },
                    ),
                    SizedBox(height: 24.h),

                    // Type Selector
                    ExpenseTypeSelector(
                      selectedType: _selectedType,
                      onTypeChanged: (type) {
                        setState(() {
                          _selectedType = type;
                        });
                      },
                    ),
                    SizedBox(height: 24.h),

                    // Note Field
                    ExpenseNoteField(controller: _noteController),
                  ],
                ),
              ),
            ),

            // Save Button
            Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(10),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                height: 56.h,
                child: ElevatedButton(
                  onPressed: _saveExpense,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Lưu Chi phí',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
