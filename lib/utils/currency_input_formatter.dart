import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// TextInputFormatter để format số tiền với dấu phẩy
/// Ví dụ: 1000 -> 1,000 | 1000000 -> 1,000,000
class CurrencyInputFormatter extends TextInputFormatter {
  final NumberFormat _formatter = NumberFormat('#,###', 'en_US');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Nếu text rỗng, return ngay
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Loại bỏ tất cả dấu phẩy để lấy số thuần
    String newText = newValue.text.replaceAll(',', '');

    // Kiểm tra xem có phải số hợp lệ không
    if (newText.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Parse thành số
    int? value = int.tryParse(newText);
    if (value == null) {
      // Nếu không parse được, giữ nguyên giá trị cũ
      return oldValue;
    }

    // Format số với dấu phẩy
    String formattedText = _formatter.format(value);

    // Tính toán vị trí cursor mới
    int selectionIndex = formattedText.length;

    // Nếu user đang nhập ở giữa, giữ nguyên vị trí tương đối
    if (newValue.selection.baseOffset < newValue.text.length) {
      // Đếm số ký tự số trước cursor
      int digitsBeforeCursor =
          newValue.text
              .substring(0, newValue.selection.baseOffset)
              .replaceAll(',', '')
              .length;

      // Tìm vị trí tương ứng trong text đã format
      int currentDigits = 0;
      for (int i = 0; i < formattedText.length; i++) {
        if (formattedText[i] != ',') {
          currentDigits++;
        }
        if (currentDigits == digitsBeforeCursor) {
          selectionIndex = i + 1;
          break;
        }
      }
    }

    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: selectionIndex),
    );
  }

  /// Helper method để parse giá trị từ formatted text
  static double? parseValue(String formattedText) {
    if (formattedText.isEmpty) return null;
    String cleanText = formattedText.replaceAll(',', '');
    return double.tryParse(cleanText);
  }

  /// Helper method để format giá trị thành text
  static String formatValue(double value) {
    final formatter = NumberFormat('#,###', 'en_US');
    return formatter.format(value.toInt());
  }
}
