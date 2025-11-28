import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../services/statistics_services.dart';
import 'statistics_event.dart';
import 'statistics_state.dart';

class StatisticsBloc extends Bloc<StatisticsEvent, StatisticsState> {
  final StatisticServices statisticServices;

  StatisticsBloc({required this.statisticServices})
    : super(StatisticsInitial()) {
    on<GetStatisticsEvent>(_onGetStatistics);
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
}
