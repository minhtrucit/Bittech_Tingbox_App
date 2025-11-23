import 'package:intl/intl.dart';

extension DateTimeFormatter on String {
  /// Chuyển chuỗi ISO8601 sang "HH:mm:ss dd-MM-yyyy"
  String toReadableDateTime() {
    try {
      final dateTime = DateTime.parse(this).toLocal(); // convert về local
      final formatter = DateFormat('HH:mm:ss dd-MM-yyyy');
      return formatter.format(dateTime);
    } catch (e) {
      print('Error formatting date: $e');
      return this; // trả về nguyên chuỗi nếu parse lỗi
    }
  }
}
