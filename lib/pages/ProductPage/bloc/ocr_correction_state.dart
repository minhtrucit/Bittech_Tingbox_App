sealed class OcrCorrectionState {}

class OcrCorrectionInitial extends OcrCorrectionState {}

class OcrCorrectionLoading extends OcrCorrectionState {}

class OcrCorrectionSuccess extends OcrCorrectionState {
  final String message;
  OcrCorrectionSuccess(this.message);
}

class OcrCorrectionFailure extends OcrCorrectionState {
  final String message;
  OcrCorrectionFailure(this.message);
}
