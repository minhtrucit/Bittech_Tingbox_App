part of 'expense_bloc.dart';

abstract class ExpenseEvent {}

class CreatePaymentEvent extends ExpenseEvent {
  final double amount;
  final DateTime date;
  final int type; // 0 or 1
  final String subject;
  final String? note;

  CreatePaymentEvent({
    required this.amount,
    required this.date,
    required this.type,
    required this.subject,
    this.note,
  });
}
