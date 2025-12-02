import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../models/order.dart';
import '../models/config_model.dart';
import '../services/printer_service.dart';
import '../pages/ReceiptPreviewPage/receipt_preview_page.dart';
import '../widgets/printer_selector_dialog.dart';
import '../utils/dialog_utils.dart';

class PrintHelper {
  static final PrinterService _printerService = PrinterService();

  /// In hóa đơn theo config
  /// - Demo mode: Luôn mở Preview
  /// - Production mode + Auto: In trực tiếp
  /// - Production mode + Manual: Hỏi trước
  static Future<void> printReceipt(
    BuildContext context, {
    required Order order,
    ConfigModel? config,
  }) async {
    // Demo mode: Luôn mở preview
    if (AppConfig.isDemoMode) {
      await _openPreview(context, order, config);
      return;
    }

    // Production mode
    final printMode = config?.printMode ?? 'manual';

    if (printMode == 'auto') {
      // Auto: In trực tiếp
      await _printDirectly(context, order, config);
    } else {
      // Manual: Hỏi trước
      final shouldPrint = await DialogUtils.showConfirmDialog(
        context: context,
        firstActionText: 'In',
        secondActionText: 'Hủy',
        title: 'In hóa đơn?',
        message: 'Bạn có muốn in hóa đơn cho đơn hàng này không?',
        onFirstAction: () {
          _printDirectly(context, order, config);
        },
        onSecondAction: () {
          Navigator.pop(context);
        },
      );

      if (shouldPrint == true) {
        if (!context.mounted) return;
        await _printDirectly(context, order, config);
      }
    }
  }

  /// Mở preview page
  static Future<void> _openPreview(
    BuildContext context,
    Order order,
    ConfigModel? config,
  ) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReceiptPreviewPage(order: order, config: config),
      ),
    );
  }

  /// In trực tiếp (không preview)
  static Future<void> _printDirectly(
    BuildContext context,
    Order order,
    ConfigModel? config,
  ) async {
    // Kiểm tra đã kết nối máy in chưa
    final isConnected = await _printerService.isConnected();

    if (!isConnected) {
      // Hiện dialog chọn máy in
      if (!context.mounted) return;
      final connected = await showDialog<bool>(
        context: context,
        builder: (context) => PrinterSelectorDialog(),
      );

      if (connected != true) return;
    }

    // Hiển thị loading
    if (!context.mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => Center(
            child: Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Đang in hóa đơn...'),
                ],
              ),
            ),
          ),
    );

    // In hóa đơn
    try {
      final success = await _printerService.printReceipt(order, config: config);

      if (!context.mounted) return;
      Navigator.pop(context); // Đóng loading

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Đã in hóa đơn thành công'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        throw Exception('In thất bại');
      }
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context); // Đóng loading

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi in hóa đơn: $e'),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: 'Thử lại',
            textColor: Colors.white,
            onPressed: () => _printDirectly(context, order, config),
          ),
        ),
      );
    }
  }

  /// Mở preview từ Order Detail (nút in thủ công)
  static Future<void> openPreviewFromDetail(
    BuildContext context, {
    required Order order,
    ConfigModel? config,
  }) async {
    await _openPreview(context, order, config);
  }
}
