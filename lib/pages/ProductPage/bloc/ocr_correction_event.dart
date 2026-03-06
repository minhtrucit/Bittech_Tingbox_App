sealed class OcrCorrectionEvent {}

class SubmitOcrCorrectionEvent extends OcrCorrectionEvent {
  final String documentId;
  final Map<String, dynamic> correctedData;

  SubmitOcrCorrectionEvent({
    required this.documentId,
    required this.correctedData,
  });
}
