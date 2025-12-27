import 'dart:io';

sealed class ReceiptPreviewState {}

final class ReceiptPreviewInitial extends ReceiptPreviewState {}

final class ReceiptPreviewLoading extends ReceiptPreviewState {}

final class ReceiptPreviewSuccess extends ReceiptPreviewState {
  final File pdfFile;

  ReceiptPreviewSuccess({required this.pdfFile});
}

final class ReceiptPreviewFailure extends ReceiptPreviewState {
  final String message;

  ReceiptPreviewFailure({required this.message});
}
