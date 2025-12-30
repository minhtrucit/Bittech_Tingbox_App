import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:ting_box/common/components/app_appbar.dart';
import 'package:ting_box/ting_box.dart';
import '../../models/order.dart';
import '../../services/print_service.dart';
import '../../common/app_colors.dart';
import '../ConfigPage/bloc/config_bloc.dart';
import '../ConfigPage/bloc/config_state.dart';
import 'bloc/receipt_preview_bloc.dart';
import 'bloc/receipt_preview_event.dart';
import 'bloc/receipt_preview_state.dart';

class ReceiptPreviewPage extends StatefulWidget {
  final Order order;

  const ReceiptPreviewPage({super.key, required this.order});

  @override
  State<ReceiptPreviewPage> createState() => _ReceiptPreviewPageState();
}

class _ReceiptPreviewPageState extends State<ReceiptPreviewPage> {
  final PrintService _printService = PrintService();
  List<String> _availablePrinters = [];
  String? _selectedPrinter;
  bool _isLoadingPrinters = false;

  @override
  void initState() {
    super.initState();
    _loadPrinters();
  }

  Future<void> _loadPrinters() async {
    final configState = context.read<ConfigBloc>().state;
    if (configState is! ConfigLoaded) return;

    final prefix = dotenv.get('AGENT_ID_PREFIX');
    final agentId =
        configState.config.id != null
            ? '$prefix${configState.config.id}'
            : null;
    final apiKey = configState.config.sepayApiKey;
    if (agentId == null) return;

    setState(() => _isLoadingPrinters = true);
    try {
      await _printService.init(agentId: agentId, apiKey: apiKey);
      final printers = await _printService.getPrinters(agentId);
      final settings = await _printService.getSavedSettings();

      if (mounted) {
        setState(() {
          _availablePrinters = printers;
          _selectedPrinter =
              settings['printerName'] ??
              (printers.isNotEmpty ? printers.first : null);
          _isLoadingPrinters = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingPrinters = false);
      }
    }
  }

  Future<void> _handlePrint() async {
    if (_selectedPrinter == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Vui lòng chọn máy in')));
      return;
    }

    final configState = context.read<ConfigBloc>().state;
    final config = configState is ConfigLoaded ? configState.config : null;
    final prefix = dotenv.get('AGENT_ID_PREFIX');
    final agentId = config?.id != null ? '$prefix${config!.id}' : null;

    if (agentId == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => const Center(
            child: CircularProgressIndicator(color: AppColors.primaryBlue),
          ),
    );

    try {
      final printData = _printService.formatOrderData(widget.order, config);
      final result = await _printService.sendPrint(
        targetAgentId: agentId,
        printerName: _selectedPrinter!,
        printData: printData,
      );
      if (mounted) {
        Navigator.pop(context); // Close loading

        if (result['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã gửi lệnh in thành công'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi: ${result['error'] ?? 'Không rõ lý do'}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final configState = context.read<ConfigBloc>().state;
        final config = configState is ConfigLoaded ? configState.config : null;
        return ReceiptPreviewBloc()..add(
          FetchReceiptPreviewPdfEvent(order: widget.order, config: config),
        );
      },
      child: AppScaffold(
        hasSafeArea: false,
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppAppBar(
          title: TitleAppbarText(title: 'Xem trước hóa đơn'),
          backgroundColor: Colors.white,
          elevation: 0,
          actions: [
            ValueListenableBuilder<bool>(
              valueListenable: _printService.isConnected,
              builder: (context, connected, _) {
                return Container(
                  margin: EdgeInsets.only(right: 8.w),
                  width: 12.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: connected ? Colors.green : Colors.red,
                    boxShadow: [
                      BoxShadow(
                        color: (connected ? Colors.green : Colors.red)
                            .withValues(alpha: .4),
                        blurRadius: 4,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                );
              },
            ),
            _isLoadingPrinters
                ? const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                )
                : PopupMenuButton<String>(
                  icon: const Icon(
                    Icons.print_outlined,
                    color: AppColors.primaryBlue,
                  ),
                  onSelected: (value) {
                    setState(() => _selectedPrinter = value);
                    final configState = context.read<ConfigBloc>().state;
                    if (configState is ConfigLoaded &&
                        configState.config.unitName != null) {
                      _printService.savePrinterSettings(
                        configState.config.unitName!,
                        value,
                      );
                    }
                  },
                  itemBuilder:
                      (context) =>
                          _availablePrinters
                              .map(
                                (p) => PopupMenuItem(
                                  value: p,
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.check,
                                        color:
                                            _selectedPrinter == p
                                                ? Colors.green
                                                : Colors.transparent,
                                      ),
                                      SizedBox(width: 8.w),
                                      Text(p),
                                    ],
                                  ),
                                ),
                              )
                              .toList(),
                ),
            SizedBox(width: 12.w),
          ],
        ),
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(20.w),
            child: Center(
              child: Container(
                constraints: BoxConstraints(maxWidth: 400.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: BlocBuilder<ReceiptPreviewBloc, ReceiptPreviewState>(
                  builder: (context, state) {
                    if (state is ReceiptPreviewLoading) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primaryBlue,
                        ),
                      );
                    } else if (state is ReceiptPreviewSuccess) {
                      return PDFView(filePath: state.pdfFile.path);
                    } else if (state is ReceiptPreviewFailure) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: Colors.red,
                              size: 48,
                            ),
                            SizedBox(height: 16.h),
                            Text(
                              'Lỗi khi tải preview',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.red[700]),
                            ),
                            SizedBox(height: 16.h),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryBlue,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                              ),
                              onPressed: () {
                                final configState =
                                    context.read<ConfigBloc>().state;
                                final config =
                                    configState is ConfigLoaded
                                        ? configState.config
                                        : null;
                                context.read<ReceiptPreviewBloc>().add(
                                  FetchReceiptPreviewPdfEvent(
                                    order: widget.order,
                                    config: config,
                                  ),
                                );
                              },
                              child: const Text(
                                'Thử lại',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return const Center(child: Text('Vui lòng chờ...'));
                  },
                ),
              ),
            ),
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_selectedPrinter != null)
                  Padding(
                    padding: EdgeInsets.only(bottom: 8.h),
                    child: Text(
                      'Máy in: $_selectedPrinter',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                SizedBox(
                  width: double.infinity,
                  height: 50.h,
                  child: ElevatedButton(
                    onPressed: _handlePrint,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    child: Text(
                      'XÁC NHẬN IN',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
