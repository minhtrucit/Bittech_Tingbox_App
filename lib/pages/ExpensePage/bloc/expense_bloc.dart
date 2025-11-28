import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../services/statistics_services.dart';

part 'expense_event.dart';
part 'expense_state.dart';

class ExpenseBloc extends Bloc<ExpenseEvent, ExpenseState> {
  final StatisticServices statisticServices;

  ExpenseBloc({required this.statisticServices}) : super(ExpenseInitial()) {
    on<CreatePaymentEvent>(_onCreatePayment);
  }

  Future<void> _onCreatePayment(
    CreatePaymentEvent event,
    Emitter<ExpenseState> emit,
  ) async {
    emit(ExpenseLoading());
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(event.date);

      // 1. Get Cashbook ID
      final cashbookId = await statisticServices.getCashBookIdByDate(dateStr);

      // 2. Create Payment
      final paymentData = {
        "cashbookId": cashbookId,
        "date": dateStr,
        "subject": event.subject,
        "amount": event.amount,
        "type": event.type,
        if (event.note != null && event.note!.isNotEmpty)
          "note": event.note,
      };

      final result = await statisticServices.createPayment(data: paymentData);

      if (result['status'] == 'success') {
        emit(ExpenseSuccess(result['message']));
      } else {
        emit(ExpenseFailure(result['message']));
      }
    } catch (e) {
      emit(ExpenseFailure(e.toString()));
    }
  }
}
