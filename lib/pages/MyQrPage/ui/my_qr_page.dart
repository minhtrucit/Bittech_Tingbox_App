import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';

import '../../../models/user.dart';

class MyQrPage extends StatefulWidget {
  final User user;

  const MyQrPage({super.key, required this.user});

  @override
  State<MyQrPage> createState() => _MyQrPageState();
}

class _MyQrPageState extends State<MyQrPage> {
  final GlobalKey _qrRepaintBoundaryKey = GlobalKey();

  Color get _backgroundColor => const Color(0xFF102820); // Deep Dark Green
  Color get _cardColor =>
      const Color(0xFF1C3A2F); // Slightly lighter green for card
  Color get _accentColor => const Color(0xFF00FF90); // Bright Neon Green

  Future<void> _saveQr() async {
    try {
      if (!await Gal.hasAccess()) {
        await Gal.requestAccess();
      }
      final file = await _capturePng();
      if (file != null) {
        await Gal.putImage(file.path);
        _showSnackBar('Đã lưu ảnh thành công!');
      }
    } catch (e) {
      _showSnackBar('Lỗi khi lưu ảnh: $e');
    }
  }

  Future<void> _copyContent() async {
    final qrData = widget.user.qrCode ?? widget.user.id.toString();
    await Clipboard.setData(ClipboardData(text: qrData));
    _showSnackBar('Đã sao chép nội dung mã QR');
  }

  Future<File?> _capturePng() async {
    try {
      RenderRepaintBoundary? boundary =
          _qrRepaintBoundaryKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) return null;

      // Upscale for better quality
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      final tempDir = await getTemporaryDirectory();
      final file =
          await File('${tempDir.path}/my_qr_${widget.user.id}.png').create();
      await file.writeAsBytes(pngBytes);

      return file;
    } catch (e) {
      debugPrint("Error capturing PNG: $e");
      return null;
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    // If user.qrCode is null, we can default to ID or empty.
    // The screenshot shows a QR code.
    debugPrint("widget.user.qrCode: ${widget.user.qrCode}");

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Mã QR của tôi",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.settings, color: _accentColor),
            onPressed: () {
              // Maybe navigate to settings or show config?
              // Keeping it visual for now as per screenshot layout
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              RepaintBoundary(
                key: _qrRepaintBoundaryKey,
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    vertical: 32.h,
                    horizontal: 24.w,
                  ),
                  decoration: BoxDecoration(
                    color: _cardColor,
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.05),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Avatar
                      Container(
                        padding: EdgeInsets.all(3.w),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: _accentColor, width: 2),
                        ),
                        child: CircleAvatar(
                          radius: 36.r,
                          backgroundColor: Colors.grey.shade800,
                          backgroundImage:
                              widget.user.avatar != null
                                  ? NetworkImage(widget.user.avatar!)
                                  : null,
                          child:
                              widget.user.avatar == null
                                  ? Text(
                                    widget.user.userName.isNotEmpty
                                        ? widget.user.userName[0]
                                        : "U",
                                    style: TextStyle(
                                      fontSize: 24.sp,
                                      color: Colors.white,
                                    ),
                                  )
                                  : null,
                        ),
                      ),

                      // Company Name
                      Text(
                        widget
                            .user
                            .userName, // Assuming this is the shop/company name
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      // ID
                      Text(
                        "ID: ${widget.user.id}",
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 14.sp,
                        ),
                      ),

                      // QR Code Box
                      Container(
                        padding: EdgeInsets.all(16.w),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                        child:
                            (widget.user.qrCode != null &&
                                    widget.user.qrCode!.isNotEmpty)
                                ? Image.network(
                                  widget.user.qrCode!,
                                  width: 200.w,
                                  height: 200.w,
                                  fit: BoxFit.contain,
                                  errorBuilder:
                                      (_, __, ___) => Icon(
                                        Icons.qr_code,
                                        size: 200.w,
                                        color: Colors.grey,
                                      ),
                                )
                                : _buildErrorQr(),
                      ),

                      // Helper text
                      Text(
                        "Quét mã để kết nối hoặc thanh toán\nnhanh chóng",
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 14.sp,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildActionButton(
                    icon: Icons.share_rounded,
                    label: "Chia sẻ",
                    onTap: () {},
                  ),
                  _buildActionButton(
                    icon: Icons.download_rounded,
                    label: "Lưu ảnh",
                    onTap: _saveQr,
                  ),
                  _buildActionButton(
                    icon: Icons.copy_rounded,
                    label: "Sao chép",
                    onTap: _copyContent,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorQr() {
    return Container(
      width: 200.w,
      height: 200.h,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.broken_image_outlined, color: Colors.grey, size: 48.w),
          SizedBox(height: 8.h),
          Text(
            "Chưa có mã QR",
            style: TextStyle(color: Colors.grey, fontSize: 12.sp),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(50),
          child: Container(
            width: 56.w,
            height: 56.w,
            decoration: BoxDecoration(
              color: const Color(0xFF2C4A3E), // Lighter than bg
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: _accentColor, size: 24.w),
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
