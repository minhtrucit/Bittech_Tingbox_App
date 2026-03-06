import 'package:intl/intl.dart';

extension NumberFormatExtension on num {
  String get comma => NumberFormat('#,###', 'en_US').format(this);

  // Format với dấu chấm (250.000)
  String get dot => NumberFormat('#,###', 'vi_VN').format(this);
}

extension DoubleFormatExtension on double {
  String formatMoney() {
    return '${NumberFormat("#,###", "vi_VN").format(this)}đ';
  }
}

String formatMoney(double value) {
  return NumberFormat("#,###", "vi_VN").format(value);
}
