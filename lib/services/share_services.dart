import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

/// Service hỗ trợ tính năng chia sẻ (Share) thông tin
/// Thiết kế dạng Static Helper (không cần Singleton) vì không lưu trữ trạng thái.
class ShareService {
  // Private constructor để ngăn chặn khởi tạo
  ShareService._();

  /// Chia sẻ văn bản thuần túy (Text)
  /// [content]: Nội dung cần chia sẻ
  /// [subject]: Tiêu đề (hiển thị trên một số ứng dụng như Email)
  /// [context]: BuildContext để hiển thị vị trí share (dành cho iPad/Tablet)
  static Future<void> shareText({
    required String content,
    String? subject,
    BuildContext? context,
  }) async {
    try {
      // Lấy vị trí render box để hiển thị popover đúng chỗ trên iPad
      final box = context?.findRenderObject() as RenderBox?;

      final result = await SharePlus.instance.share(
        ShareParams(
          text: content,
          subject: subject,
          sharePositionOrigin:
              box != null ? box.localToGlobal(Offset.zero) & box.size : null,
        ),
      );
      if (result.status == ShareResultStatus.success) {
        debugPrint('Thank you for sharing my website!');
      }
    } catch (e) {
      _handleShareError(e);
    }
  }

  /// Hàm tiện ích để format dữ liệu Key-Value thành văn bản đẹp mắt để share
  static Future<void> shareKeyValueData({
    required String title,
    required Map<String, String> data,
    BuildContext? context,
  }) async {
    final StringBuffer buffer = StringBuffer();

    buffer.writeln('📋 $title');
    buffer.writeln('--------------------------');

    data.forEach((key, value) {
      if (value.isNotEmpty) {
        buffer.writeln('$key: $value');
      }
    });

    // Thêm footer nếu cần
    buffer.writeln('--------------------------');
    buffer.writeln('Quét bởi BitTech OCR');

    await shareText(
      content: buffer.toString(),
      subject: title,
      context: context,
    );
  }

  /// Xử lý lỗi tập trung
  static void _handleShareError(dynamic error) {
    debugPrint('❌ ShareService Error: $error');

    // Fallback Logic (Tùy chọn):
    // 1. Log lỗi lên Crashlytics/Sentry
    // 2. Nếu lỗi do "Rớt mạng" (ví dụ khi share URL cần preview), thực tế share native
    //    hoạt động offline với text/file local.
    // 3. Nếu lỗi nghiêm trọng, có thể ném exception ra ngoài để UI xử lý hiển thị dialog lỗi.
  }

  static Future<void> shareImage({
    required List<XFile> files,
    String? subject,
    String? text,
  }) async {
    try {
      final result = await SharePlus.instance.share(
        ShareParams(files: files, text: text, subject: subject),
      );
      if (result.status == ShareResultStatus.success) {
        debugPrint('Thank you for sharing the picture!');
      }
    } catch (e) {
      _handleShareError(e);
    }
  }
}
