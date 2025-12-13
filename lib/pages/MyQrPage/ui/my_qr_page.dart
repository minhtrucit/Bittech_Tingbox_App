import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:ting_box/common/components/app_appbar.dart';
import 'package:ting_box/common/components/app_scaffold.dart';
import 'package:ting_box/common/components/title_appbar_text.dart';
import 'package:ting_box/models/config_model.dart';

import '../../../models/user.dart';

class MyQrPage extends StatefulWidget {
  final User user;
  final ConfigModel config;

  const MyQrPage({super.key, required this.user, required this.config});

  @override
  State<MyQrPage> createState() => _MyQrPageState();
}

class _MyQrPageState extends State<MyQrPage> {
  final GlobalKey _qrRepaintBoundaryKey = GlobalKey();

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
    return AppScaffold(
      hasSafeArea: false,
      backgroundColor: const Color(0xFFF8F9FD),
      body: Column(
        children: [
          _buildAppBar(context),
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Column(
                  children: [
                    SizedBox(height: 24.h),

                    // Main QR Card
                    RepaintBoundary(
                      key: _qrRepaintBoundaryKey,
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24.r),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFE0E5EC),
                              blurRadius: 24,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            SizedBox(height: 32.h),
                            // Avatar
                            Container(
                              padding: EdgeInsets.all(4.w),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFFE8F1FF),
                                  width: 1,
                                ),
                              ),
                              child: CircleAvatar(
                                radius: 40.r,
                                backgroundColor: Colors.grey.shade100,
                                backgroundImage:
                                    widget.user.avatar != null
                                        ? NetworkImage(widget.user.avatar!)
                                        : null,
                                child:
                                    widget.user.avatar == null
                                        ? Icon(
                                          Icons.person,
                                          size: 40.sp,
                                          color: Colors.grey,
                                        )
                                        : null,
                              ),
                            ),
                            SizedBox(height: 16.h),
                            // Name
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16.w),
                              child: Text(
                                widget.config.unitName ?? widget.user.userName,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: const Color(0xFF1A1A1A),
                                  fontSize: 20.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            SizedBox(height: 32.h),

                            // QR Code Container
                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: const Color(0xFFE0E0E0),
                                  width: 1,
                                  style:
                                      BorderStyle
                                          .none, // Using dashed logic if possible or just container
                                ),
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Custom dashed border visual (optional, simplifying to Container)
                                  Container(
                                    margin: EdgeInsets.symmetric(
                                      horizontal: 32.w,
                                    ),
                                    padding: EdgeInsets.all(24.w),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFAFAFA),
                                      borderRadius: BorderRadius.circular(24.r),
                                      border: Border.all(
                                        color: const Color(0xFFEEEEEE),
                                      ),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12.r),
                                      child:
                                          (widget.user.qrCode != null &&
                                                  widget
                                                      .user
                                                      .qrCode!
                                                      .isNotEmpty)
                                              ? Image.network(
                                                widget.user.qrCode!,
                                                width: 200.w,
                                                height: 200.w,
                                                fit: BoxFit.cover,
                                                errorBuilder:
                                                    (_, __, ___) =>
                                                        _buildErrorQr(),
                                              )
                                              : _buildErrorQr(),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            SizedBox(height: 24.h),
                            Text(
                              "Quét mã để thanh toán",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: const Color(0xFF666666),
                                fontSize: 14.sp,
                                height: 1.5,
                              ),
                            ),
                            SizedBox(height: 32.h),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: 40.h),

                    // Actions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildActionButton(
                          icon: Icons.share_outlined,
                          label: "Chia sẻ",
                          onTap: () {
                            // Share logic
                          },
                        ),
                        _buildMainActionButton(
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
                    SizedBox(height: 20.h),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return AppAppBar(title: TitleAppbarText(title: 'Mã QR của tôi'));
  }

  Widget _buildErrorQr() {
    return Container(
      width: 200.w,
      height: 200.w,
      color: Colors.white,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.qr_code, size: 60.w, color: Colors.grey.shade300),
          SizedBox(height: 8.h),
          Text(
            "No QRCode",
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
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: 56.w,
            height: 56.w,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.black87, size: 24.w),
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          label,
          style: TextStyle(
            color: const Color(0xFF666666),
            fontSize: 12.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildMainActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: 56.w,
            height: 56.w,
            decoration: BoxDecoration(
              color: const Color(0xFF2979FF),
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2979FF).withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 24.w),
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          label,
          style: TextStyle(
            color: const Color(0xFF2979FF),
            fontSize: 12.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
