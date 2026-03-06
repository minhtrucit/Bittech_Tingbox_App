import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// TextInputFormatter để format số tiền với dấu chấm phân cách hàng nghìn (Vietnamese style)
/// Ví dụ: 1000 -> 1.000 | 1000000 -> 1.000.000
class CurrencyInputFormatter extends TextInputFormatter {
  final NumberFormat _formatter = NumberFormat('#,###', 'vi_VN');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Loại bỏ tất cả dấu chấm để lấy số thuần
    String newText = newValue.text.replaceAll('.', '');

    if (newText.isEmpty) {
      return newValue.copyWith(text: '');
    }

    int? value = int.tryParse(newText);
    if (value == null) {
      return oldValue;
    }

    // Format số với dấu chấm
    String formattedText = _formatter.format(value);

    int selectionIndex = formattedText.length;

    if (newValue.selection.baseOffset < newValue.text.length) {
      int digitsBeforeCursor =
          newValue.text
              .substring(0, newValue.selection.baseOffset)
              .replaceAll('.', '')
              .length;

      int currentDigits = 0;
      for (int i = 0; i < formattedText.length; i++) {
        if (formattedText[i] != '.') {
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
    String cleanText = formattedText.replaceAll('.', '');
    return double.tryParse(cleanText);
  }

  /// Helper method để format giá trị thành text
  static String formatValue(double value) {
    final formatter = NumberFormat('#,###', 'vi_VN');
    return formatter.format(value.toInt());
  }
}
