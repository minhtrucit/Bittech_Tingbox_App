import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'receipt_preview_event.dart';
import 'receipt_preview_state.dart';
import '../../../services/print_service.dart';

class ReceiptPreviewBloc
    extends Bloc<ReceiptPreviewEvent, ReceiptPreviewState> {
  final PrintService _printService = PrintService();

  ReceiptPreviewBloc() : super(ReceiptPreviewInitial()) {
    on<FetchReceiptPreviewPdfEvent>(_onFetchReceiptPreviewPdf);
  }

  Future<void> _onFetchReceiptPreviewPdf(
    FetchReceiptPreviewPdfEvent event,
    Emitter<ReceiptPreviewState> emit,
  ) async {
    emit(ReceiptPreviewLoading());
    try {
      final receiptData = _printService.formatOrderData(
        event.order,
        event.config,
      );

      final prefix = dotenv.get('AGENT_ID_PREFIX', fallback: 'BITTECH_USER_');
      final targetAgentId =
          event.config?.id != null ? '$prefix${event.config!.id}' : '';

      final pdfFile = await _printService.fetchReceiptPreviewPdf(
        targetAgentId: targetAgentId,
        receiptData: receiptData,
      );
      emit(ReceiptPreviewSuccess(pdfFile: pdfFile));
    } catch (e) {
      emit(ReceiptPreviewFailure(message: e.toString()));
    }
  }
}
