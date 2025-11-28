import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ting_box/pages/HomePage/widgets/quick_action_buttons.dart';
import 'package:ting_box/pages/HomePage/widgets/report_filter_bar.dart';
import 'package:ting_box/pages/HomePage/widgets/revenue_pie_chart.dart';
import 'package:ting_box/pages/HomePage/widgets/revenue_summary_card.dart';
import 'package:ting_box/pages/HomePage/widgets/transaction_list.dart';

import '../../ting_box.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _selectedFilter = 'Hôm nay';

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      hasSafeArea: false,
      backgroundColor: AppColors.bgLightGrey,
      appBar: AppAppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        centerTitle: true,
        title: TitleAppbarText(title: 'Thống kê'),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.calendar_today_outlined,
              color: Colors.black,
            ),
            onPressed: () {
              // Show date picker
              showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: const ColorScheme.light(
                        primary: AppColors.primaryBlue,
                        onPrimary: Colors.white,
                        onSurface: Colors.black,
                      ),
                    ),
                    child: child!,
                  );
                },
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ReportFilterBar(
                selectedFilter: _selectedFilter,
                onFilterChanged: (filter) {
                  setState(() {
                    _selectedFilter = filter;
                  });
                },
              ),
              SizedBox(height: 20.h),
              const RevenueSummaryCard(),
              SizedBox(height: 20.h),
              const QuickActionButtons(),
              SizedBox(height: 24.h),
              Text(
                'Nguồn Thu',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 16.h),
              const RevenuePieChart(),
              SizedBox(height: 24.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Giao Dịch',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  AppTextButton(
                    onPressed: () {},
                    label: const Text('Xem tất cả'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primaryBlue,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              const TransactionList(),
            ],
          ),
        ),
      ),
    );
  }
}
