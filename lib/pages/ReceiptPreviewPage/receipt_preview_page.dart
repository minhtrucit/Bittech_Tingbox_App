import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../ting_box.dart';
import 'bloc/receipt_preview_bloc.dart';
import 'bloc/receipt_preview_event.dart';
import 'bloc/receipt_preview_state.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';

class ReceiptPreviewPage extends StatelessWidget {
  final Order order;
  final ConfigModel? config;

  const ReceiptPreviewPage({super.key, required this.order, this.config});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create:
          (context) => ReceiptPreviewBloc(printerService: PrinterService())
            ..add(FetchReceiptPreviewPdfEvent(order: order, config: config)),
      child: AppScaffold(
        hasSafeArea: false,
        backgroundColor: Colors.grey[200],
        appBar: AppAppBar(title: TitleAppbarText(title: 'Xem trước hóa đơn')),
        body: SafeArea(
          child: BlocBuilder<ReceiptPreviewBloc, ReceiptPreviewState>(
            builder: (context, state) {
              if (state is ReceiptPreviewLoading) {
                return _buildLoadingView();
              } else if (state is ReceiptPreviewSuccess) {
                return _buildPdfView(state.pdfFile.path);
              } else if (state is ReceiptPreviewFailure) {
                return _buildErrorView(context, state.message);
              }
              return _buildLoadingView();
            },
          ),
        ),
        bottomNavigationBar: _buildActionButtons(context),
      ),
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: AppColors.primaryBlue,
            strokeWidth: 2,
          ),
          SizedBox(height: 16.h),
          Text(
            'Đang tạo bản xem trước...',
            style: TextStyle(fontSize: 14.sp, color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }

  Widget _buildPdfView(String pdfPath) {
    return Container(
      margin: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8.r),
        child: PDFView(
          filePath: pdfPath,
          enableSwipe: true,
          swipeHorizontal: false,
          autoSpacing: false,
          pageFling: false,
          pageSnap: true,
          defaultPage: 0,
          fitPolicy: FitPolicy.WIDTH,
          onError: (error) {
            debugPrint('❌ [PDFView] Error: $error');
          },
          onPageError: (page, error) {
            debugPrint('❌ [PDFView] Page $page error: $error');
          },
        ),
      ),
    );
  }

  Widget _buildErrorView(BuildContext context, String errorMessage) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64.sp, color: Colors.red),
            SizedBox(height: 16.h),
            Text(
              'Không thể tạo bản xem trước',
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8.h),
            ElevatedButton.icon(
              onPressed: () {
                context.read<ReceiptPreviewBloc>().add(
                  FetchReceiptPreviewPdfEvent(order: order, config: config),
                );
              },
              icon: Icon(Icons.refresh),
              label: Text('Thử lại'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    if (config?.printMode == PrintMode.none) return const SizedBox.shrink();

    return SafeArea(
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(10),
              blurRadius: 10,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: ElevatedButton.icon(
          onPressed: () => _handlePrint(context),
          icon: Icon(Icons.print),
          label: Text('In hóa đơn'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryBlue,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(vertical: 14.h),
          ),
        ),
      ),
    );
  }

  Future<void> _handlePrint(BuildContext context) async {
    final printerService = PrinterService();

    // Kiểm tra đã kết nối máy in chưa
    // final isConnected = await printerService.isConnected();

    // if (!isConnected) {
    //   // Hiện dialog chọn máy in
    //   if (!context.mounted) return;
    //   final connected = await showDialog<bool>(
    //     context: context,
    //     builder: (context) => PrinterSelectorDialog(),
    //   );

    //   if (connected != true) return;
    // }

    // Hiển thị loading
    if (!context.mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => Material(
            color: Colors.transparent,
            child: Center(
              child: Container(
                padding: EdgeInsets.all(24.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      color: AppColors.primaryBlue,
                      strokeWidth: 2,
                    ),
                    SizedBox(height: 16.h),
                    Text('Đang in hóa đơn...'),
                  ],
                ),
              ),
            ),
          ),
    );

    // In hóa đơn
    try {
      final success = await printerService.printReceipt(order, config: config);

      if (!context.mounted) return;
      Navigator.pop(context); // Đóng loading

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8.w),
                Text('Đã in hóa đơn thành công'),
              ],
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context); // Đóng preview page
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
            onPressed: () => _handlePrint(context),
          ),
        ),
      );
    }
  }
}
