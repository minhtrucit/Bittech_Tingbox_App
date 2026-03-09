import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:ting_box/pages/HomePage/widgets/quick_action_buttons.dart';
import 'package:ting_box/pages/HomePage/widgets/report_filter_bar.dart';
import 'package:ting_box/pages/HomePage/widgets/revenue_pie_chart.dart';
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
  bool _isTable = false;
  BusinessMode _businessMode = BusinessMode.fnb;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    _configId = await UserRepository.getConfigId() ?? '';
    final user = await UserRepository.getUser();
    final configState = context.read<ConfigBloc>().state;
    if (mounted) {
      setState(() {
        _isAdmin = user?.roleId == 1 || user == null;
        _isTable = true; // Forced for FnB testing
        _businessMode = BusinessMode.fnb; // Forced for FnB mode
        if (configState is ConfigLoaded) {
          // If real data exists, we can still use it, but force fnb for now as requested
          _businessMode = BusinessMode.fnb;
        }
      });
    }
  }

  String _formatDateApi(DateTime date) {
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
          startDate: _formatDateApi(startDate),
          endDate: _formatDateApi(endDate),
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
      locale: const Locale('vi', 'VN'),
      helpText: 'CHỌN PHẠM VI NGÀY',
      fieldStartHintText: 'dd/mm/yyyy',
      fieldEndHintText: 'dd/mm/yyyy',
      fieldStartLabelText: 'Ngày bắt đầu',
      fieldEndLabelText: 'Ngày kết thúc',
      switchToCalendarEntryModeIcon: const Icon(
        Icons.calendar_today,
        color: Colors.white,
      ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            datePickerTheme: DatePickerThemeData(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              rangePickerSurfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24.r),
              ),
              headerBackgroundColor: AppColors.primaryBlue,
              headerForegroundColor: Colors.white,
              rangePickerHeaderBackgroundColor: AppColors.primaryBlue,
              rangePickerHeaderForegroundColor: Colors.white,
              rangeSelectionBackgroundColor: AppColors.primaryBlue.withValues(
                alpha: 0.12,
              ),
              dayForegroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) return Colors.white;
                return Colors.black.withValues(alpha: 0.8);
              }),
              todayForegroundColor: WidgetStateProperty.all(
                AppColors.primaryBlue,
              ),
              todayBorder: const BorderSide(
                color: AppColors.primaryBlue,
                width: 1,
              ),
            ),
            colorScheme: ColorScheme.light(
              primary: AppColors.primaryBlue,
              onPrimary: Colors.white,
              onSurface: Colors.black.withValues(alpha: 0.8),
              surface: Colors.white,
            ),

            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primaryBlue,
                textStyle: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            dialogTheme: DialogThemeData(backgroundColor: Colors.white),
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
            _businessMode = state.config.businessMode;
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

                  if (_isAdmin) ...[
                    SizedBox(height: 20.h),
                    BlocBuilder<StatisticsBloc, StatisticsState>(
                      builder: (context, state) {
                        return RevenueSummaryCard(
                          revenue:
                              state is StatisticsLoaded
                                  ? state.statistic.revenue
                                  : null,
                        );
                      },
                    ),
                  ],

                  SizedBox(height: 20.h),
                  QuickActionButtons(
                    configId: int.tryParse(_configId) ?? 0,
                    isTable: _isTable,
                    businessMode: _businessMode,
                    isAdmin: _isAdmin,
                    onRefresh: () {
                      if (_selectedDateRange != null) {
                        _fetchStatistics(
                          startDate: _selectedDateRange!.start,
                          endDate: _selectedDateRange!.end,
                        );
                      } else {
                        _handleFilterChanged(_selectedFilter ?? 'Hôm nay');
                      }
                    },
                  ),

                  if (_isAdmin) ...[
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
                        return RevenuePieChart(
                          incomeSources:
                              state is StatisticsLoaded
                                  ? state.statistic.incomeSources
                                  : null,
                        );
                      },
                    ),
                  ],

                  if (_isAdmin) ...[
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
                            ).then((_) {
                              if (_selectedDateRange != null) {
                                _fetchStatistics(
                                  startDate: _selectedDateRange!.start,
                                  endDate: _selectedDateRange!.end,
                                );
                              } else {
                                _handleFilterChanged(
                                  _selectedFilter ?? 'Hôm nay',
                                );
                              }
                            });
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
