import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ting_box/common/components/app_appbar.dart';
import 'package:ting_box/common/components/app_scaffold.dart';
import 'package:ting_box/common/components/title_appbar_text.dart';
import '../../services/print_service.dart';
import '../../common/app_colors.dart';
import '../ConfigPage/bloc/config_bloc.dart';
import '../ConfigPage/bloc/config_state.dart';

class PrintPage extends StatefulWidget {
  const PrintPage({super.key});

  @override
  State<PrintPage> createState() => _PrintPageState();
}

class _PrintPageState extends State<PrintPage> {
  final PrintService _printService = PrintService();

  // Controllers
  final TextEditingController _targetAgentController = TextEditingController(
    text: 'USER_01',
  );
  final TextEditingController _headerController = TextEditingController(
    text: 'BITTECH TINGBOX\n123 Street, City',
  );
  final TextEditingController _productsController = TextEditingController(
    text: 'Product A x 1: 100,000\nProduct B x 2: 200,000',
  );
  final TextEditingController _footerController = TextEditingController(
    text: 'Thank you for your purchase!',
  );

  bool _isScanning = false;
  bool _isPrinting = false;
  List<String> _availablePrinters = [];
  String? _selectedPrinter;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await _printService.getSavedSettings();
    if (!mounted) return;
    final configState = context.read<ConfigBloc>().state;

    String? agentId = settings['agentId'];
    String? apiKey;

    if (configState is ConfigLoaded) {
      final config = configState.config;
      agentId ??= 'BITTECH_USER_${config.id}';
      apiKey = config.sepayApiKey;
    }

    if (mounted) {
      setState(() {
        if (agentId != null) {
          _targetAgentController.text = agentId;
        }
        _selectedPrinter = settings['printerName'];
      });
      // Initialize with unitName and sepayApiKey credentials
      _printService.init(agentId: _targetAgentController.text, apiKey: apiKey);
    }
  }

  @override
  void dispose() {
    _targetAgentController.dispose();
    _headerController.dispose();
    _productsController.dispose();
    _footerController.dispose();
    super.dispose();
  }

  void _showSnackBar(
    String message, {
    bool isError = false,
    bool isSuccess = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError
                  ? Icons.error_outline
                  : (isSuccess
                      ? Icons.check_circle_outline
                      : Icons.info_outline),
              color: Colors.white,
            ),
            SizedBox(width: 12.w),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor:
            isError
                ? Colors.redAccent
                : (isSuccess ? Colors.green : AppColors.primaryBlue),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.r),
        ),
        margin: EdgeInsets.all(16.w),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _scanPrinters() async {
    setState(() {
      _isScanning = true;
    });

    try {
      final printers = await _printService.getPrinters(
        _targetAgentController.text,
      );
      if (mounted) {
        setState(() {
          _availablePrinters = printers;
          if (printers.isNotEmpty && _selectedPrinter == null) {
            _selectedPrinter = printers.first;
          }
          _isScanning = false;
        });
        _showPrinterSelection();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isScanning = false);
        _showSnackBar(e.toString(), isError: true);
      }
    }
  }

  Future<void> _handlePrint() async {
    if (_selectedPrinter == null) {
      _showSnackBar('Hãy chọn máy in trước', isError: true);
      return;
    }

    setState(() => _isPrinting = true);
    _showSnackBar('Đang gửi lệnh in...');

    try {
      final result = await _printService.sendPrint(
        targetAgentId: _targetAgentController.text,
        printerName: _selectedPrinter!,
        printData: {
          'header': _headerController.text,
          'products': _productsController.text,
          'footer': _footerController.text,
        },
      );

      if (mounted) {
        setState(() => _isPrinting = false);
        if (result['success'] == true) {
          _showSnackBar('In thành công!', isSuccess: true);
        } else {
          _showSnackBar(
            'Error: ${result['error'] ?? 'Có lỗi khi in'}',
            isError: true,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isPrinting = false);
        _showSnackBar(e.toString(), isError: true);
      }
    }
  }

  void _showPrinterSelection() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
            ),
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 32.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Chọn máy in',
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                SizedBox(height: 20.h),
                if (_availablePrinters.isEmpty)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 40.h),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.print_disabled,
                            size: 48.w,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 12.h),
                          Text(
                            'Không tìm thấy máy in',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: _availablePrinters.length,
                      separatorBuilder:
                          (_, __) =>
                              Divider(height: 1.h, color: Colors.grey[100]),
                      itemBuilder: (context, index) {
                        final printer = _availablePrinters[index];
                        final isSelected = _selectedPrinter == printer;
                        return ListTile(
                          contentPadding: EdgeInsets.symmetric(
                            vertical: 4.h,
                            horizontal: 8.w,
                          ),
                          leading: Container(
                            padding: EdgeInsets.all(8.w),
                            decoration: BoxDecoration(
                              color:
                                  isSelected
                                      ? AppColors.primaryBlue.withValues(
                                        alpha: 0.1,
                                      )
                                      : Colors.grey[50],
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.print,
                              color:
                                  isSelected
                                      ? AppColors.primaryBlue
                                      : Colors.grey,
                            ),
                          ),
                          title: Text(
                            printer,
                            style: TextStyle(
                              fontWeight:
                                  isSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                              color:
                                  isSelected
                                      ? AppColors.primaryBlue
                                      : Colors.black87,
                            ),
                          ),
                          trailing:
                              isSelected
                                  ? Icon(
                                    Icons.check_circle,
                                    color: AppColors.primaryBlue,
                                  )
                                  : null,
                          onTap: () async {
                            final printer = _availablePrinters[index];
                            setState(() => _selectedPrinter = printer);
                            await _printService.savePrinterSettings(
                              _targetAgentController.text,
                              printer,
                            );
                            if (context.mounted) Navigator.pop(context);
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      backgroundColor: AppColors.bgLightGrey,
      hasSafeArea: false,
      appBar: AppAppBar(
        centerTitle: false,
        title: TitleAppbarText(title: 'Kết nối máy in'),
        actions: [_buildConnectionStatus(), SizedBox(width: 16.w)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.all(20.w),
          child: Column(
            children: [
              _buildAgentConfigurationCard(),
              SizedBox(height: 20.h),
              _buildPrintFormDataCard(),
              SizedBox(height: 32.h),
              _buildMainActionButton(),
              SizedBox(
                height:
                    MediaQuery.of(context).systemGestureInsets.bottom > 32
                        ? MediaQuery.of(context).systemGestureInsets.bottom +
                            20.h
                        : 20.h,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConnectionStatus() {
    return ValueListenableBuilder<bool>(
      valueListenable: _printService.isConnected,
      builder: (context, connected, _) {
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
          decoration: BoxDecoration(
            color:
                connected
                    ? Colors.green.withValues(alpha: 0.1)
                    : Colors.red.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8.w,
                height: 8.w,
                decoration: BoxDecoration(
                  color: connected ? Colors.green : Colors.red,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (connected ? Colors.green : Colors.red).withValues(
                        alpha: 0.4,
                      ),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              Text(
                connected ? 'CONNECTED' : 'OFFLINE',
                style: TextStyle(
                  color: connected ? Colors.green[700] : Colors.red[700],
                  fontSize: 10.sp,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAgentConfigurationCard() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  Icons.settings_remote,
                  color: AppColors.primaryBlue,
                  size: 20.w,
                ),
              ),
              SizedBox(width: 12.w),
              Text(
                'Cài đặt máy in',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          _buildTextField(
            label: 'Mã khách hàng',
            controller: _targetAgentController,
            hint: 'Example: USER_01',
            icon: Icons.alternate_email,
          ),
          // Todo bổ sung api key để config 
          SizedBox(height: 20.h),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap:
                      _availablePrinters.isNotEmpty
                          ? _showPrinterSelection
                          : null,
                  child: Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.print, size: 18.w, color: Colors.grey[600]),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Text(
                            _selectedPrinter ?? 'Select Printer',
                            style: TextStyle(
                              color:
                                  _selectedPrinter == null
                                      ? Colors.grey
                                      : Colors.black87,
                              fontSize: 14.sp,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Icon(Icons.arrow_drop_down, color: Colors.grey[400]),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              _buildScanButton(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScanButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _isScanning ? null : _scanPrinters,
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          height: 54.h,
          width: 54.h,
          decoration: BoxDecoration(
            color: AppColors.primaryBlue,
            borderRadius: BorderRadius.circular(12.r),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryBlue.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child:
              _isScanning
                  ? Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.w),
                      child: const CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                  )
                  : Icon(Icons.sync, color: Colors.white, size: 24.w),
        ),
      ),
    );
  }

  Widget _buildPrintFormDataCard() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  Icons.description_outlined,
                  color: Colors.orange,
                  size: 20.w,
                ),
              ),
              SizedBox(width: 12.w),
              Text(
                'Hóa đơn mẫu',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          _buildTextField(
            label: 'Tiêu đề',
            controller: _headerController,
            hint: 'Tên cửa hàng, Địa chỉ...',
            maxLines: 2,
          ),
          SizedBox(height: 16.h),
          _buildTextField(
            label: 'Sản phẩm / Nội dung',
            controller: _productsController,
            hint: 'Items list...',
            maxLines: 4,
          ),
          SizedBox(height: 16.h),
          _buildTextField(
            label: 'Chữ ký',
            controller: _footerController,
            hint: 'Cám ơn bạn đã mua hàng...',
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildMainActionButton() {
    return Container(
      width: double.infinity,
      height: 60.h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.r),
        gradient: LinearGradient(
          colors: [AppColors.primaryBlue, const Color(0xFF1565C0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isPrinting ? null : _handlePrint,
          borderRadius: BorderRadius.circular(16.r),
          child: Center(
            child:
                _isPrinting
                    ? SizedBox(
                      width: 24.w,
                      height: 24.w,
                      child: const CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                    : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.print_outlined,
                          color: Colors.white,
                          size: 22.w,
                        ),
                        SizedBox(width: 12.w),
                        Text(
                          'Gửi lệnh in',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    String? hint,
    int maxLines = 1,
    IconData? icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 4.w, bottom: 8.h),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13.sp,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: TextStyle(fontSize: 14.sp),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13.sp),
            prefixIcon:
                icon != null
                    ? Icon(icon, size: 18.w, color: Colors.grey[400])
                    : null,
            filled: true,
            fillColor: Colors.grey[50],
            contentPadding: EdgeInsets.all(16.w),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: Colors.grey[200]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: Colors.grey[200]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: const BorderSide(
                color: AppColors.primaryBlue,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
