import 'package:intl/intl.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
    emit(StatisticsLoading());
    try {
      final statistic = await statisticServices.getStatisticByDateRange(
        startDate: event.startDate,
        endDate: event.endDate,
        configId: event.configId,
      );
      emit(StatisticsLoaded(statistic: statistic));
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
