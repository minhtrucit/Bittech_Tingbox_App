import 'package:flutter/foundation.dart';

double parseDouble(dynamic value, [String fieldName = '']) {
  if (value == null) return 0;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) {
    try {
      return double.parse(value);
    } catch (e) {
      if (fieldName.isNotEmpty) {
        debugPrint('Error parsing double for $fieldName: $value');
      }
      return 0;
    }
  }
  if (fieldName.isNotEmpty) {
    debugPrint('Warning: unexpected type for $fieldName -> ${value.runtimeType} ($value)');
  }
  return 0;
}

int parseInt(dynamic value, [String fieldName = '']) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) {
    try {
      return int.parse(value);
    } catch (e) {
      if (fieldName.isNotEmpty) {
        debugPrint('Error parsing int for $fieldName: $value');
      }
      return 0;
    }
  }
  if (fieldName.isNotEmpty) {
    debugPrint('Warning: unexpected type for $fieldName -> ${value.runtimeType} ($value)');
  }
  return 0;
}

String parseString(dynamic value, [String defaultValue = '']) {
  if (value == null) return defaultValue;
  return value.toString();
}
