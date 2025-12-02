import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import '../../../ting_box.dart';

class ReportPage extends StatefulWidget {
  const ReportPage({super.key});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage>
    with AutomaticKeepAliveClientMixin {
  Statistic? statistic;
  bool isLoading = false;
  String _configId = '';
  DateTimeRange? _selectedDateRange;
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadConfigIdAndFetchData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isLoadingMore) return;

    // Check if scrolled beyond bottom (pull up to load)
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent + 50) {
      _loadMore();
    }
  }

  void _loadMore() {
    if (statistic?.pagination == null ||
        !statistic!.pagination!.hasNextPage ||
        _isLoadingMore) {
      return;
    }

    setState(() {
      _isLoadingMore = true;
    });

    final nextPage = statistic!.pagination!.page + 1;

    if (_selectedDateRange != null) {
      _fetchStatisticsByDateRange(
        _selectedDateRange!.start,
        _selectedDateRange!.end,
        page: nextPage,
      );
    }
  }

  Future<void> _loadConfigIdAndFetchData() async {
    _configId = await UserRepository.getConfigId() ?? '';
    // Fetch statistics for current month by default
    _fetchMonthlyStatistics();
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd-MM-yyyy').format(date);
  }

  String _formatDateForApi(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  void _fetchStatisticsByDateRange(
    DateTime startDate,
    DateTime endDate, {
    int page = 1,
  }) {
    if (!mounted) return;

    debugPrint("startDate (UI): ${_formatDate(startDate)}");
    debugPrint("startDate (API): ${_formatDateForApi(startDate)}");
    debugPrint("endDate: ${_formatDate(endDate)}");

    final configId = int.tryParse(_configId) ?? 0;
    if (configId > 0) {
      context.read<StatisticsBloc>().add(
        GetStatisticsEvent(
          startDate: _formatDateForApi(startDate),
          endDate: _formatDateForApi(endDate),
          configId: configId,
          page: page,
        ),
      );
      setState(() {
        _isLoadingMore = page > 1;
      });
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
      });
      _fetchStatisticsByDateRange(picked.start, picked.end, page: 1);
    }
  }

  void _fetchMonthlyStatistics() {
    if (!mounted) return;

    final now = DateTime.now();
    // Get first day of current month
    final startDate = DateTime(now.year, now.month, 1);
    // Get current day of current month
    final endDate = now;

    setState(() {
      _selectedDateRange = DateTimeRange(start: startDate, end: endDate);
    });

    _fetchStatisticsByDateRange(startDate, endDate, page: 1);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return BlocListener<StatisticsBloc, StatisticsState>(
      listenWhen: (prev, curr) {
        // Ignore loading if we already have data to prevent skeleton flicker
        if (statistic != null && curr is StatisticsLoading) return false;

        return curr is StatisticsLoaded ||
            curr is StatisticsLoading ||
            curr is StatisticsError;
      },
      listener: (context, state) {
        if (state is StatisticsLoading) {
          setState(() => isLoading = true);
        }

        if (state is StatisticsLoaded) {
          setState(() {
            isLoading = false;
            _isLoadingMore = false;
            statistic = state.statistic;
          });
        }

        if (state is StatisticsError) {
          setState(() {
            isLoading = false;
            _isLoadingMore = false;
          });
        }
      },
      child: AppScaffold(
        hasSafeArea: false,
        backgroundColor: Color(0xFFF4F7FC),
        appBar: AppAppBar(
          title: TitleAppbarText(title: "Quản Lý Thu Chi"),
          actions: [
            IconButton(
              icon: const Icon(
                Icons.calendar_today_outlined,
                color: Colors.black,
              ),
              onPressed: _showDateRangePicker,
            ),
          ],
        ),
        body: Builder(
          builder: (context) {
            if (isLoading && statistic == null) {
              return const ReportPageSkeleton();
            }

            if (statistic != null) {
              return SafeArea(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  physics: BouncingScrollPhysics(),
                  padding: EdgeInsets.all(16.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildRevenueSection(statistic!),
                      SizedBox(height: 20.h),
                      _buildExpenseSection(statistic!),
                      SizedBox(height: 20.h),
                      _buildRecentTransactionsSection(statistic!),
                    ],
                  ),
                ),
              );
            }

            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Không có dữ liệu"),
                  SizedBox(height: 16.h),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      _fetchMonthlyStatistics();
                    },
                    child: const Text(
                      "Tải lại",
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // -------------------------------
  // SECTION: Tổng Thu
  // -------------------------------
  Widget _buildRevenueSection(Statistic statistic) {
    final revenue = statistic.revenue;
    final incomeSources = statistic.incomeSources;

    // Calculate cash and bank from income sources
    double cashAmount = 0;
    double bankAmount = 0;

    for (var source in incomeSources.sources) {
      if (source.type == 'cash') {
        cashAmount += source.amount;
      } else if (source.type == 'bank') {
        bankAmount += source.amount;
      }
    }

    final totalIn = revenue.totalIn;

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                "Tổng Thu",
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
              ),
              Spacer(),
              Text(
                "${_formatDate(_selectedDateRange?.start ?? statistic.startDate)} - ${_formatDate(_selectedDateRange?.end ?? statistic.endDate)}",
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            "${formatMoney(totalIn)}đ",
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          SizedBox(height: 16.h),
          _buildIconRow(Icons.money, "Tiền mặt", formatMoney(cashAmount)),
          SizedBox(height: 12.h),
          _buildIconRow(
            Icons.account_balance,
            "Chuyển khoản",
            formatMoney(bankAmount),
          ),
          SizedBox(height: 12.h),
          Divider(color: Colors.grey[300], thickness: 1),
          SizedBox(height: 12.h),
          _buildIconRow(
            Icons.warning_amber_rounded,
            "Công nợ tháng trước",
            formatMoney(statistic.debt.previousMonth),
            iconColor: Colors.orange,
          ),
          SizedBox(height: 12.h),
          _buildIconRow(
            Icons.error_outline,
            "Công nợ hiện tại",
            formatMoney(statistic.debt.current),
            iconColor: statistic.debt.current > 0 ? Colors.red : Colors.green,
          ),
        ],
      ),
    );
  }

  // Một hàng nhỏ có icon + label + số tiền
  Widget _buildIconRow(
    IconData icon,
    String title,
    String value, {
    Color? iconColor,
  }) {
    return Row(
      children: [
        Icon(icon, color: iconColor ?? Colors.green, size: 20),
        SizedBox(width: 8.w),
        Expanded(child: Text(title)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }

  // -------------------------------
  // SECTION: Tổng Chi
  // -------------------------------
  Widget _buildExpenseSection(Statistic statistic) {
    final expenseSources = statistic.expenseSources;

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                "Tổng Chi",
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
              ),
              Spacer(),
              Text(
                "${_formatDate(_selectedDateRange?.start ?? statistic.startDate)} - ${_formatDate(_selectedDateRange?.end ?? statistic.endDate)}",
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            "${formatMoney(expenseSources.total)}đ",
            style: TextStyle(
              fontSize: 20.sp,
              color: Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16.h),
          _buildIconRow(
            Icons.money,
            "Tiền mặt",
            formatMoney(
              expenseSources.sources
                  .firstWhere((element) => element.type == "cash")
                  .amount,
            ),
          ),
          SizedBox(height: 12.h),
          _buildIconRow(
            Icons.account_balance,
            "Chuyển khoản",
            formatMoney(
              expenseSources.sources
                  .firstWhere((element) => element.type == "bank")
                  .amount,
            ),
          ),
          SizedBox(height: 16.h),

          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.grey, size: 16),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  "Chi tiết các khoản chi được hiển thị trong danh sách giao dịch bên dưới",
                  style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // -------------------------------
  // SECTION: Giao Dịch Gần Đây
  // -------------------------------
  Widget _buildRecentTransactionsSection(Statistic statistic) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Giao dịch",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 12.h),

        // Danh sách giao dịch gần đây
        if (statistic.transactions.isEmpty)
          Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 20.h),
              child: Text(
                "Không có giao dịch nào",
                style: TextStyle(color: Colors.grey),
              ),
            ),
          )
        else
          ...statistic.transactions.map(_buildTransactionItem),

        // Load more indicator
        if (_isLoadingMore)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 16.h),
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTransactionItem(StatisticTransaction transaction) {
    final isIncome = transaction.type == 'receipt';
    final color = isIncome ? Colors.green : Colors.red;

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6),
        ],
      ),
      child: Row(
        children: [
          // Icon
          Icon(
            isIncome ? Icons.arrow_downward : Icons.arrow_upward,
            color: color,
            size: 22,
          ),
          SizedBox(width: 12.w),

          // Thông tin giao dịch
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Subject
                Text(
                  transaction.subject ?? 'Không có tiêu đề',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15.sp,
                  ),
                ),
                SizedBox(height: 4.h),

                // Type
                Text(
                  transaction.type ?? '',
                  style: TextStyle(fontSize: 13.sp, color: Colors.blueGrey),
                ),

                SizedBox(height: 4.h),

                // Thời gian
                Text(
                  '${transaction.date ?? ''}',
                  style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                ),
              ],
            ),
          ),

          // Amount
          Text(
            (transaction.amount ?? 0).formatMoney(),
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
