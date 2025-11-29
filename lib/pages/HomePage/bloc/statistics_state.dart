import '../../../models/statistic.dart';

abstract class StatisticsState {}

class StatisticsInitial extends StatisticsState {}

class StatisticsLoading extends StatisticsState {}

class StatisticsLoaded extends StatisticsState {
  final Statistic statistic;

  StatisticsLoaded({required this.statistic});
}

class StatisticsError extends StatisticsState {
  final String message;

  StatisticsError({required this.message});
}

class ReceiptCreatedSuccess extends StatisticsState {
  final String message;
  ReceiptCreatedSuccess({required this.message});
}

class ReceiptCreatedFailure extends StatisticsState {
  final String message;
  ReceiptCreatedFailure({required this.message});
}
