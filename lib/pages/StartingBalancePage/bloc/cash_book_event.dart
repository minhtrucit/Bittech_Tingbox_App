sealed class CashBookEvent {}

final class CreateCashBookEvent extends CashBookEvent {
  final String name;
  final String date;
  final double openingAmount;
  final int configId;
  final String type;

  CreateCashBookEvent({
    required this.name,
    required this.date,
    required this.openingAmount,
    required this.configId,
    required this.type,
  });
}
