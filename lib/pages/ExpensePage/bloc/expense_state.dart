part of 'expense_bloc.dart';

abstract class ExpenseState {}

class ExpenseInitial extends ExpenseState {}

class ExpenseLoading extends ExpenseState {}

class ExpenseSuccess extends ExpenseState {
  final String message;
  ExpenseSuccess(this.message);
}

class ExpenseFailure extends ExpenseState {
  final String message;
  ExpenseFailure(this.message);
}
