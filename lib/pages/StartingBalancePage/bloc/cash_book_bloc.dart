import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ting_box/models/cash_book.dart';
import 'package:ting_box/services/statistics_services.dart';
import 'cash_book_event.dart';
import 'cash_book_state.dart';

class CashBookBloc extends Bloc<CashBookEvent, CashBookState> {
  final StatisticServices statisticServices;

  CashBookBloc({required this.statisticServices}) : super(CashBookInitial()) {
    on<CreateCashBookEvent>(_onCreateCashBook);
  }

  Future<void> _onCreateCashBook(
    CreateCashBookEvent event,
    Emitter<CashBookState> emit,
  ) async {
    emit(CashBookLoading());
    try {
      int? configBankAccountId;
      if (event.type == 'bank_transfer') {
        final configBankAccountIdResponse = await statisticServices
            .getConfigBankAccountId(configId: event.configId);
        configBankAccountId = configBankAccountIdResponse['id'];
      }

      final data = {
        'name': event.name,
        'date': event.date,
        'openingAmount': event.openingAmount,
        'configId': event.configId,
        'type': event.type,
        'configBankAccountId': configBankAccountId,
      };

      final result = await statisticServices.createCashBook(data: data);

      if (result['status'] == 'success') {
        CashBook cashBook;
        if (result['data'] != null) {
          try {
            final responseData = result['data'];
            if (responseData is Map<String, dynamic>) {
              cashBook = CashBook.fromJson(responseData);
            } else {
              // If data is not in expected format, create from event data
              cashBook = CashBook(
                name: event.name,
                date: event.date,
                openingAmount: event.openingAmount,
                configId: event.configId,
                type: event.type,
              );
            }
          } catch (e) {
            debugPrint('Error parsing cash book: $e');
            cashBook = CashBook(
              name: event.name,
              date: event.date,
              openingAmount: event.openingAmount,
              configId: event.configId,
              type: event.type,
            );
          }
        } else {
          cashBook = CashBook(
            name: event.name,
            date: event.date,
            openingAmount: event.openingAmount,
            configId: event.configId,
            type: event.type,
          );
        }

        emit(
          CashBookCreateSuccess(
            cashBook: cashBook,
            message: result['message'] ?? 'Tạo sổ quỹ thành công',
          ),
        );
      } else if (result['status'] == 'error') {
        emit(
          CashBookFailure(message: result['message'] ?? 'Tạo sổ quỹ thất bại'),
        );
      }
    } catch (e) {
      debugPrint('Error creating cash book: $e');
      emit(CashBookFailure(message: 'Đã xảy ra lỗi: ${e.toString()}'));
    }
  }
}
