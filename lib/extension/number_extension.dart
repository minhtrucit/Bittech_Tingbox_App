import 'package:intl/intl.dart';

extension NumberFormatExtension on num {
  String get comma => NumberFormat('#,###').format(this);
}

String formatMoney(double value) {
  return NumberFormat("#,###.##").format(value);
}