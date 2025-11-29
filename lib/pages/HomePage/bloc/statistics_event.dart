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

class CreateReceiptEvent extends StatisticsEvent {
  final double amount;
  final DateTime date;
  final int type; // 0: Bank, 1: Cash (or vice versa, check logic)
  final String subject;
  final String note;

  CreateReceiptEvent({
    required this.amount,
    required this.date,
    required this.type,
    required this.subject,
    required this.note,
  });
}
