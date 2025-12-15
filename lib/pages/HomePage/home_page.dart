import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:ting_box/pages/HomePage/widgets/quick_action_buttons.dart';
import 'package:ting_box/pages/HomePage/widgets/report_filter_bar.dart';
import 'package:ting_box/pages/HomePage/widgets/revenue_pie_chart.dart';
import 'package:ting_box/pages/HomePage/widgets/revenue_pie_chart_skeleton.dart';
import 'package:ting_box/pages/HomePage/widgets/revenue_summary_card.dart';
import 'package:ting_box/pages/HomePage/widgets/transaction_list.dart';

import '../../ting_box.dart';

import '../ConfigPage/bloc/config_bloc.dart';
import '../ConfigPage/bloc/config_state.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? _selectedFilter = 'Hôm nay';
  DateTimeRange? _selectedDateRange;
  String _configId = '';

  @override
  void initState() {
    super.initState();
    _loadConfigId();
  }

  Future<void> _loadConfigId() async {
    _configId = await UserRepository.getConfigId() ?? '';
    // Initial statistics fetch is now handled by BasePage
  }

  String _formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  void _fetchStatistics({
    required DateTime startDate,
    required DateTime endDate,
  }) {
    if (!mounted) return;

    int configId = int.tryParse(_configId) ?? 0;

    // If configId is not set locally, try to get it from ConfigBloc
    if (configId == 0) {
      final configState = context.read<ConfigBloc>().state;
      if (configState is ConfigLoaded && configState.config.id != null) {
        configId = configState.config.id!;
        _configId = configId.toString();
      }
    }

    if (configId > 0) {
      context.read<StatisticsBloc>().add(
        GetStatisticsEvent(
          startDate: _formatDate(startDate),
          endDate: _formatDate(endDate),
          configId: configId,
        ),
      );
    }
  }

  Future<void> _showDateRangePicker() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _selectedDateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            datePickerTheme: DatePickerThemeData(
              backgroundColor: AppColors.white,
            ),
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

    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
        _selectedFilter = null; // Set to null to deselect all filters
      });
      _fetchStatistics(startDate: picked.start, endDate: picked.end);
    }
  }

  void _handleFilterChanged(String filter) {
    setState(() {
      _selectedFilter = filter;
      _selectedDateRange = null; // Clear custom range when using presets
    });

    final now = DateTime.now();
    DateTime startDate = now;
    DateTime endDate = now;

    if (filter == 'Hôm nay') {
      startDate = now;
      endDate = now;
    } else if (filter == 'Hôm qua') {
      startDate = now.subtract(const Duration(days: 1));
      endDate = now.subtract(const Duration(days: 1));
    } else if (filter == 'Tuần này') {
      // Logic for this week if needed, for now just today or implement later
      // Assuming Monday is start of week
      startDate = now.subtract(Duration(days: now.weekday - 1));
      endDate = now;
    }

    _fetchStatistics(startDate: startDate, endDate: endDate);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ConfigBloc, ConfigState>(
      listener: (context, state) {
        if (state is ConfigLoaded && state.config.id != null) {
          setState(() {
            _configId = state.config.id.toString();
          });
        }
      },
      child: AppScaffold(
        hasSafeArea: false,
        backgroundColor: AppColors.bgLightGrey,
        body: SafeArea(
          child: RefreshIndicator(
            color: AppColors.primaryBlue,
            backgroundColor: AppColors.white,
            onRefresh: () async {
              // Reload statistics based on current filter
              if (_selectedDateRange != null) {
                _fetchStatistics(
                  startDate: _selectedDateRange!.start,
                  endDate: _selectedDateRange!.end,
                );
              } else {
                // Use current filter
                _handleFilterChanged(_selectedFilter ?? 'Hôm nay');
              }
              await Future.delayed(const Duration(milliseconds: 500));
            },
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: ReportFilterBar(
                          selectedFilter: _selectedFilter,
                          onFilterChanged: _handleFilterChanged,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.calendar_today_outlined,
                          color: Colors.black,
                        ),
                        onPressed: _showDateRangePicker,
                      ),
                    ],
                  ),

                  SizedBox(height: 20.h),

                  BlocBuilder<StatisticsBloc, StatisticsState>(
                    builder: (context, state) {
                      if (state is StatisticsLoading) {
                        return const RevenueSummarySkeleton();
                      } else if (state is StatisticsLoaded) {
                        return RevenueSummaryCard(
                          revenue: state.statistic.revenue,
                        );
                      } else if (state is StatisticsError) {
                        return Text('Error: ${state.message}');
                      }
                      return const RevenueSummaryCard();
                    },
                  ),

                  SizedBox(height: 20.h),
                  QuickActionButtons(configId: int.tryParse(_configId) ?? 0),
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
                  BlocBuilder<StatisticsBloc, StatisticsState>(
                    builder: (context, state) {
                      if (state is StatisticsLoading) {
                        return const RevenuePieChartSkeleton();
                      }
                      return RevenuePieChart(
                        incomeSources:
                            state is StatisticsLoaded
                                ? state.statistic.incomeSources
                                : null,
                      );
                    },
                  ),
                  SizedBox(height: 24.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Giao Dịch Gần Đây',
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      AppTextButton(
                        onPressed: () {
                          final state = context.read<StatisticsBloc>().state;
                          List<StatisticTransaction> transactions = [];
                          if (state is StatisticsLoaded) {
                            transactions = state.statistic.transactions;
                          }

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => TransactionsPage(
                                    transactions: transactions,
                                  ),
                            ),
                          );
                        },
                        label: const Text('Xem tất cả'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primaryBlue,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  BlocBuilder<StatisticsBloc, StatisticsState>(
                    builder: (context, state) {
                      return TransactionList(
                        transactions:
                            state is StatisticsLoaded
                                ? state.statistic.transactions
                                : null,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
