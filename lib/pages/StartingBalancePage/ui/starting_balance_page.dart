import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../ting_box.dart';
import '../../ExpensePage/widgets/expense_amount_field.dart';
import '../../ExpensePage/widgets/expense_note_field.dart';
import '../../ExpensePage/widgets/expense_type_selector.dart';

class StartingBalancePage extends StatefulWidget {
  const StartingBalancePage({super.key, required this.configId});

  final int configId;

  @override
  State<StartingBalancePage> createState() => _StartingBalancePageState();
}

class _StartingBalancePageState extends State<StartingBalancePage> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final DateTime _currentDate = DateTime.now();
  String _selectedType = 'cash';
  bool _hasError = false;

  @override
  void dispose() {
    _amountController.dispose();
    _subjectController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _saveReceipt(BuildContext context) {
    final amountText = _amountController.text.replaceAll(',', '');
    final amount = double.tryParse(amountText);
    final subject = _subjectController.text.trim();

    if (amount == null || amount <= 0 || subject.isEmpty) {
      setState(() {
        _hasError = true;
      });
      if (subject.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vui lòng nhập nội dung thu'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Map type: 'cash' -> 0, 'bank' -> 1 (Following ExpensePage logic)
    final typeInt = _selectedType == 'cash' ? 0 : 1;

    context.read<StatisticsBloc>().add(
      CreateReceiptEvent(
        amount: amount,
        date: _currentDate,
        type: typeInt,
        subject: subject,
        note: _noteController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<StatisticsBloc, StatisticsState>(
      listener: (context, state) {
        if (state is ReceiptCreatedSuccess) {
          DialogUtils.showAppDialog(
            context: context,
            title: 'Thành công',
            content: state.message,
            firstActionText: 'OK',
            onFirstAction: () {
              Navigator.of(context).pop(); // Close dialog
              setState(() {
                _amountController.clear();
                _subjectController.clear();
                _noteController.clear();
                _selectedType = 'cash';
                _hasError = false;
              });
            },
          );
        } else if (state is ReceiptCreatedFailure) {
          DialogUtils.showAppDialog(
            context: context,
            title: 'Lỗi',
            content: state.message,
            firstActionText: 'OK',
            onFirstAction: () {
              Navigator.of(context).pop();
            },
          );
        }
      },
      child: AppScaffold(
        backgroundColor: AppColors.bgLightGrey,
        hasSafeArea: false,
        appBar: AppAppBar(
          backgroundColor: AppColors.white,
          elevation: 0,
          centerTitle: true,
          title: const TitleAppbarText(title: 'Tạo phiếu thu'),
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
                      // Subject Field
                      Text(
                        'Nội dung',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(
                            color:
                                _hasError && _subjectController.text.isEmpty
                                    ? Colors.red
                                    : Colors.grey[300]!,
                            width: 1.5,
                          ),
                        ),
                        child: TextField(
                          controller: _subjectController,
                          style: TextStyle(
                            fontSize: 16.sp,
                            color: Colors.black,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Nhập nội dung thu...',
                            hintStyle: TextStyle(
                              fontSize: 16.sp,
                              color: Colors.grey[400],
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 20.w,
                              vertical: 16.h,
                            ),
                          ),
                          onChanged: (value) {
                            if (_hasError && value.isNotEmpty) {
                              setState(() {
                                _hasError = false;
                              });
                            }
                          },
                        ),
                      ),
                      SizedBox(height: 24.h),

                      // Amount Field
                      ExpenseAmountField(
                        controller: _amountController,
                        hasError:
                            _hasError &&
                            (_amountController.text.isEmpty ||
                                double.tryParse(
                                      _amountController.text.replaceAll(
                                        ',',
                                        '',
                                      ),
                                    ) ==
                                    null),
                        onChanged: (value) {
                          if (_hasError && value.isNotEmpty) {
                            setState(() {
                              _hasError = false;
                            });
                          }
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
              BlocBuilder<StatisticsBloc, StatisticsState>(
                builder: (context, state) {
                  final isLoading = state is StatisticsLoading;
                  return Container(
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
                        onPressed:
                            isLoading ? null : () => _saveReceipt(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          elevation: 0,
                        ),
                        child:
                            isLoading
                                ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                                : Text(
                                  'Lưu Phiếu Thu',
                                  style: TextStyle(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
