import '../../../models/cash_book.dart';

sealed class CashBookState {}

final class CashBookInitial extends CashBookState {}

final class CashBookLoading extends CashBookState {}

final class CashBookCreateSuccess extends CashBookState {
  final CashBook cashBook;
  final String message;

  CashBookCreateSuccess({required this.cashBook, required this.message});
}

final class CashBookFailure extends CashBookState {
  final String message;

  CashBookFailure({required this.message});
}
