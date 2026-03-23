import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../services/ocr_correction_service.dart';
import 'ocr_correction_event.dart';
import 'ocr_correction_state.dart';

class OcrCorrectionBloc extends Bloc<OcrCorrectionEvent, OcrCorrectionState> {
  final OcrCorrectionService _correctionService;

  OcrCorrectionBloc({OcrCorrectionService? correctionService})
    : _correctionService = correctionService ?? OcrCorrectionService(),
      super(OcrCorrectionInitial()) {
    on<SubmitOcrCorrectionEvent>(_onSubmitCorrection);
  }

  Future<void> _onSubmitCorrection(
    SubmitOcrCorrectionEvent event,
    Emitter<OcrCorrectionState> emit,
  ) async {
    emit(OcrCorrectionLoading());
    try {
      final response = await _correctionService.submitCorrection(
        documentId: event.documentId,
        correctedData: event.correctedData,
      );

      if (response.statusCode == 200) {
        emit(
          OcrCorrectionSuccess(
            response.data['message'] ?? 'Successfully submitted correction',
          ),
        );
      } else {
        emit(
          OcrCorrectionFailure(
            response.data['message'] ?? 'Failed to submit correction',
          ),
        );
      }
    } catch (e) {
      emit(OcrCorrectionFailure(e.toString()));
    }
  }
}
