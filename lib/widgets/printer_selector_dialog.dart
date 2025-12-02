import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../ting_box.dart';

class PrinterSelectorDialog extends StatefulWidget {
  const PrinterSelectorDialog({super.key});

  @override
  State<PrinterSelectorDialog> createState() => _PrinterSelectorDialogState();
}

class _PrinterSelectorDialogState extends State<PrinterSelectorDialog> {
  final PrinterService _printerService = PrinterService();
  List<MockBluetoothDevice> _devices = [];
  bool _isScanning = false;
  bool _isConnecting = false;
  String? _connectingAddress;

  @override
  void initState() {
    super.initState();
    _scanDevices();
  }

  Future<void> _scanDevices() async {
    setState(() {
      _isScanning = true;
    });

    try {
      final devices = await _printerService.scanDevices();
      setState(() {
        _devices = devices;
        _isScanning = false;
      });
    } catch (e) {
      setState(() {
        _isScanning = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi quét thiết bị: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _connectDevice(MockBluetoothDevice device) async {
    setState(() {
      _isConnecting = true;
      _connectingAddress = device.address;
    });

    try {
      final success = await _printerService.connectPrinter(
        device.address,
        device.name,
      );

      if (success) {
        if (mounted) {
          Navigator.pop(context, true); // Trả về true khi kết nối thành công
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Đã kết nối với ${device.name}'),
                ],
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception('Không thể kết nối');
      }
    } catch (e) {
      setState(() {
        _isConnecting = false;
        _connectingAddress = null;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi kết nối: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      child: Container(
        constraints: BoxConstraints(maxHeight: 500.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16.r),
                  topRight: Radius.circular(16.r),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.print, color: Colors.white),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      'Chọn máy in',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context, false),
                  ),
                ],
              ),
            ),

            // Body
            Flexible(
              child:
                  _isScanning
                      ? _buildScanningState()
                      : _devices.isEmpty
                      ? _buildEmptyState()
                      : _buildDeviceList(),
            ),

            // Footer
            Padding(
              padding: EdgeInsets.all(16.w),
              child: OutlinedButton.icon(
                onPressed: _isScanning ? null : _scanDevices,
                icon: Icon(Icons.refresh, color: AppColors.primaryBlue),
                label: Text(
                  'Quét lại',
                  style: TextStyle(color: AppColors.primaryBlue),
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: Size(double.infinity, 48.h),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScanningState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppColors.primaryBlue),
            SizedBox(height: 16.h),
            Text('Đang quét máy in...', style: TextStyle(fontSize: 14.sp)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.print_disabled, size: 64, color: Colors.grey),
            SizedBox(height: 16.h),
            Text(
              'Không tìm thấy máy in',
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8.h),
            Text(
              'Vui lòng bật Bluetooth và máy in',
              style: TextStyle(fontSize: 14.sp, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceList() {
    return ListView.separated(
      shrinkWrap: true,
      padding: EdgeInsets.symmetric(vertical: 8.h),
      itemCount: _devices.length,
      separatorBuilder: (context, index) => Divider(height: 1),
      itemBuilder: (context, index) {
        final device = _devices[index];
        final isConnecting =
            _isConnecting && _connectingAddress == device.address;

        return ListTile(
          leading: Icon(Icons.print, color: AppColors.primaryBlue),
          title: Text(
            device.name,
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15.sp),
          ),
          subtitle: Text(
            device.address,
            style: TextStyle(fontSize: 12.sp, color: Colors.grey),
          ),
          trailing:
              isConnecting
                  ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primaryBlue,
                    ),
                  )
                  : Icon(Icons.chevron_right),
          onTap: isConnecting ? null : () => _connectDevice(device),
        );
      },
    );
  }
}
