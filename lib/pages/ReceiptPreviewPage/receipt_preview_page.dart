import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/order.dart';
import '../../services/print_service.dart';
import '../../common/app_colors.dart';
import '../../extension/date_time_extension.dart';
import '../../extension/number_extension.dart';
import '../ConfigPage/bloc/config_bloc.dart';
import '../ConfigPage/bloc/config_state.dart';

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

    final agentId =
        configState.config.id != null
            ? 'BITTECH_USER_${configState.config.id}'
            : null;
    final apiKey = configState.config.sepayApiKey;
    if (agentId == null) return;

    setState(() => _isLoadingPrinters = true);
    try {
      // Ensure service is initialized with latest credentials from API
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
    final agentId = config?.id != null ? 'BITTECH_USER_${config!.id}' : null;

    if (agentId == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
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
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          'Xem trước hóa đơn',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          // Connection Status
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
          // Printer Selection Dropdown
          _isLoadingPrinters
              ? const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
              : PopupMenuButton<String>(
                icon: const Icon(
                  Icons.print_outlined,
                  color: AppColors.primaryBlue,
                ),
                onSelected: (value) {
                  setState(() => _selectedPrinter = value);
                  // Optionally save this as default
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
      body: SingleChildScrollView(
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
            child: Column(
              children: [
                _buildReceiptHeader(),
                const Divider(indent: 16, endIndent: 16),
                _buildReceiptItems(),
                _buildDashedLine(),
                _buildReceiptSummary(),
                _buildReceiptFooter(),
              ],
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
    );
  }

  Widget _buildReceiptHeader() {
    final configState = context.read<ConfigBloc>().state;
    final config = configState is ConfigLoaded ? configState.config : null;

    return Padding(
      padding: EdgeInsets.all(20.w),
      child: Column(
        children: [
          Text(
            config?.unitName?.toUpperCase() ?? 'TINGBOX STORE',
            style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          if (config?.phone != null)
            Text('SĐT: ${config!.phone}', style: TextStyle(fontSize: 12.sp)),
          if (config?.address != null)
            Text(
              config!.address!,
              style: TextStyle(fontSize: 12.sp),
              textAlign: TextAlign.center,
            ),
          SizedBox(height: 16.h),
          Text(
            'HÓA ĐƠN THANH TOÁN',
            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w900),
          ),
          SizedBox(height: 8.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Mã đơn: ${widget.order.code ?? widget.order.id}',
                style: TextStyle(fontSize: 12.sp),
              ),
              Text(
                DateTime.now().toIso8601String().toReadableDateTime(),
                style: TextStyle(fontSize: 12.sp),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptItems() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      child: Column(
        children:
            widget.order.items.map((item) {
              return Padding(
                padding: EdgeInsets.only(bottom: 8.h),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(
                        item.product?.name ?? 'Sản phẩm',
                        style: TextStyle(fontSize: 13.sp),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text(
                        'x${item.quantity}',
                        style: TextStyle(fontSize: 13.sp),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        (item.unitPrice * item.quantity).comma,
                        style: TextStyle(fontSize: 13.sp),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
      ),
    );
  }

  Widget _buildReceiptSummary() {
    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'TỔNG CỘNG:',
            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
          ),
          Text(
            widget.order.totalAmount?.comma ?? '0',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryBlue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptFooter() {
    return Padding(
      padding: EdgeInsets.only(bottom: 20.h, left: 16.w, right: 16.w),
      child: Column(
        children: [
          Text(
            'Cảm ơn quý khách!',
            style: TextStyle(fontSize: 13.sp, fontStyle: FontStyle.italic),
          ),
          Text(
            'Hẹn gặp lại!',
            style: TextStyle(fontSize: 13.sp, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  Widget _buildDashedLine() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Row(
        children: List.generate(
          30,
          (index) => Expanded(
            child: Container(
              color: index % 2 == 0 ? Colors.transparent : Colors.grey[300],
              height: 1,
            ),
          ),
        ),
      ),
    );
  }
}
