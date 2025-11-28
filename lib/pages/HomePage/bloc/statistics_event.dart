
abstract class StatisticsEvent {}

class GetStatisticsEvent extends StatisticsEvent {
  final String startDate;
  final String endDate;
  final int configId;

  GetStatisticsEvent({
    required this.startDate,
    required this.endDate,
    required this.configId,
  });
}
