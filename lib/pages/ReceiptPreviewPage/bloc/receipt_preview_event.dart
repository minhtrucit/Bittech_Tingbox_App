import '../../../models/order.dart';
import '../../../models/config_model.dart';

sealed class ReceiptPreviewEvent {}

final class FetchReceiptPreviewPdfEvent extends ReceiptPreviewEvent {
  final Order order;
  final ConfigModel? config;

  FetchReceiptPreviewPdfEvent({required this.order, this.config});
}
