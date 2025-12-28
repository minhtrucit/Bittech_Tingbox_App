import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:ting_box/services/printer_service.dart';
import 'package:ting_box/extension/date_time_extension.dart';
import 'package:ting_box/config/app_config.dart';
import 'receipt_preview_event.dart';
import 'receipt_preview_state.dart';

class ReceiptPreviewBloc
    extends Bloc<ReceiptPreviewEvent, ReceiptPreviewState> {
  final PrinterService printerService;

  ReceiptPreviewBloc({required this.printerService})
    : super(ReceiptPreviewInitial()) {
    on<FetchReceiptPreviewPdfEvent>(_onFetchReceiptPreviewPdf);
  }

  Future<void> _onFetchReceiptPreviewPdf(
    FetchReceiptPreviewPdfEvent event,
    Emitter<ReceiptPreviewState> emit,
  ) async {
    emit(ReceiptPreviewLoading());

    try {
      debugPrint(
        '🚀 [ReceiptPreviewBloc] Target URL: ${AppConfig.printerAgentUrl}',
      );
      debugPrint('📄 [ReceiptPreviewBloc] Fetching receipt preview PDF...');

      // Tạo receiptData từ order và config
      final receiptData = _formatReceiptData(event.order, event.config);

      debugPrint('📤 [ReceiptPreviewBloc] Receipt data: $receiptData');

      // Gọi service để lấy PDF file
      final pdfFile = await printerService.fetchReceiptPreviewPdf(receiptData);

      debugPrint('✅ [ReceiptPreviewBloc] PDF file created: ${pdfFile.path}');

      emit(ReceiptPreviewSuccess(pdfFile: pdfFile));
    } catch (e, stackTrace) {
      debugPrint('❌ [ReceiptPreviewBloc] Error fetching PDF: $e');
      debugPrint('🛠 Stacktrace: $stackTrace');

      emit(ReceiptPreviewFailure(message: e.toString()));
    }
  }

  Map<String, String> _formatReceiptData(order, config) {
    final headerBuffer = StringBuffer();
    final productsBuffer = StringBuffer();
    final footerBuffer = StringBuffer();

    final unitName = config?.unitName ?? 'TÊN CỬA HÀNG';
    final address = config?.address ?? '';
    final phone = config?.phone ?? '';
    final date = order.createdAt?.toString().toReadableDateTime() ?? '';

    // --- HEADER: Thông tin cửa hàng + Tên hóa đơn ---
    headerBuffer.writeln(unitName.toUpperCase());
    if (address.isNotEmpty) headerBuffer.writeln(address);
    if (phone.isNotEmpty) headerBuffer.writeln('DT: $phone');
    headerBuffer.writeln('--------------------------------');
    headerBuffer.writeln('       Hóa đơn bán hàng');
    headerBuffer.writeln('--------------------------------');

    // --- PRODUCTS (BODY): Thông tin đơn hàng + Danh sách sản phẩm + Tổng tiền ---
    productsBuffer.writeln('Mã đơn: #${order.code}-${order.id}');
    productsBuffer.writeln('Ngày: $date');
    if (order.customerName.isNotEmpty) {
      productsBuffer.writeln('Khách hàng: ${order.customerName}');
    }
    productsBuffer.writeln('--------------------------------');

    for (var item in order.items) {
      final itemName = item.product?.name ?? 'Sản phẩm #${item.productId}';
      productsBuffer.writeln(itemName);
      final qtyPrice = '${item.quantity} x ${_formatMoney(item.unitPrice)}';
      final total = _formatMoney(item.unitPrice * item.quantity);
      final line = _justifyText(qtyPrice, total, 32);
      productsBuffer.writeln(line);
    }

    productsBuffer.writeln('--------------------------------');
    productsBuffer.writeln(
      _justifyText('Tạm tính:', _formatMoney(order.subtotal ?? 0), 32),
    );
    if (order.vat > 0) {
      final vatAmount = (order.subtotal ?? 0) * order.vat / 100;
      productsBuffer.writeln(
        _justifyText(
          'VAT (${order.vat.toInt()}%):',
          _formatMoney(vatAmount),
          32,
        ),
      );
    }
    if (order.discount > 0) {
      productsBuffer.writeln(
        _justifyText('Giảm giá:', _formatMoney(order.discount), 32),
      );
    }
    productsBuffer.writeln('================================');
    productsBuffer.writeln(
      _justifyText('Tổng cộng:', _formatMoney(order.totalAmount ?? 0), 32),
    );
    productsBuffer.writeln('--------------------------------');
    productsBuffer.writeln(
      _justifyText('Đã thanh toán:', _formatMoney(order.paidAmount), 32),
    );

    final remaining = (order.totalAmount ?? 0) - order.paidAmount;
    if (remaining > 0) {
      productsBuffer.writeln(
        _justifyText('Còn lại:', _formatMoney(remaining), 32),
      );
    } else if (remaining < 0) {
      productsBuffer.writeln(
        _justifyText('Tiền thừa:', _formatMoney(remaining.abs()), 32),
      );
    }

    // --- FOOTER: Cảm ơn + Chào tạm biệt ---
    footerBuffer.writeln('\nCảm ơn quý khách!');
    footerBuffer.writeln('Hẹn gặp lại\n\n\n');

    return {
      'header': headerBuffer.toString(),
      'products': productsBuffer.toString(),
      'footer': footerBuffer.toString(),
    };
  }

  String _justifyText(String left, String right, int width) {
    final spaces = width - left.length - right.length;
    if (spaces <= 0) return '$left $right';
    return left + (' ' * spaces) + right;
  }

  String _formatMoney(num amount) {
    return amount
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }
}
