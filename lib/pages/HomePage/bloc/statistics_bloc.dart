import 'package:intl/intl.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../models/statistic.dart';
import '../../../services/statistics_services.dart';
import 'statistics_event.dart';
import 'statistics_state.dart';

class StatisticsBloc extends Bloc<StatisticsEvent, StatisticsState> {
  final StatisticServices statisticServices;

  StatisticsBloc({required this.statisticServices})
    : super(StatisticsInitial()) {
    on<GetStatisticsEvent>(_onGetStatistics);
    on<CreateReceiptEvent>(_onCreateReceipt);
  }

  Future<void> _onGetStatistics(
    GetStatisticsEvent event,
    Emitter<StatisticsState> emit,
  ) async {
    final currentState = state;
    if (event.page == 1) {
      emit(StatisticsLoading());
    }

    try {
      final statistic = await statisticServices.getStatisticByDateRange(
        startDate: event.startDate,
        endDate: event.endDate,
        configId: event.configId,
        page: event.page,
      );

      if (event.page > 1 && currentState is StatisticsLoaded) {
        final currentTransactions = currentState.statistic.transactions;
        final newTransactions = statistic.transactions;

        // Tạo Statistic mới với danh sách transaction đã merge
        // Lưu ý: Các thông tin tổng hợp (revenue, debt...) lấy từ response mới nhất
        // hoặc giữ nguyên tùy vào logic backend. Ở đây ta lấy từ response mới nhất.
        final mergedStatistic = Statistic(
          startDate: statistic.startDate,
          endDate: statistic.endDate,
          debt: statistic.debt,
          revenue: statistic.revenue,
          incomeSources: statistic.incomeSources,
          expenseSources: statistic.expenseSources,
          transactions: [...currentTransactions, ...newTransactions],
          pagination: statistic.pagination,
        );

        emit(StatisticsLoaded(statistic: mergedStatistic));
      } else {
        emit(StatisticsLoaded(statistic: statistic));
      }
    } catch (e) {
      emit(StatisticsError(message: e.toString()));
    }
  }

  Future<void> _onCreateReceipt(
    CreateReceiptEvent event,
    Emitter<StatisticsState> emit,
  ) async {
    emit(StatisticsLoading());
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(event.date);

      // 1. Get Cashbook ID
      final cashbookId = await statisticServices.getCashBookIdByDate(dateStr);

      final data = {
        "cashbookId": cashbookId,
        "amount": event.amount,
        "date": dateStr,
        "type": event.type,
        "subject": event.subject,
        "note": event.note,
      };

      final result = await statisticServices.createReceipt(data: data);

      if (result['status'] == 'success') {
        emit(ReceiptCreatedSuccess(message: result['message']));
      } else {
        emit(ReceiptCreatedFailure(message: result['message']));
      }
    } catch (e) {
      emit(ReceiptCreatedFailure(message: e.toString()));
    }
  }
}
