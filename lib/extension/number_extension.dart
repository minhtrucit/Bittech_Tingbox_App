import 'package:intl/intl.dart';

extension NumberFormatExtension on num {
  String get comma => NumberFormat('#,###').format(this);
}

extension DoubleFormatExtension on double {
  String formatMoney() {
    return '${NumberFormat("#,###.##").format(this)}đ';
  }
}

String formatMoney(double value) {
  return NumberFormat("#,###.##").format(value);
}
