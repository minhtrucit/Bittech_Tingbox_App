import 'package:flutter/foundation.dart';

import 'order.dart';

class Statistic {
  final List<Order> recentOrders;
  final Revenue revenue;

  Statistic({required this.recentOrders, required this.revenue});

  factory Statistic.fromJson(Map<String, dynamic> json) {
    List<Order> parsedOrders = [];

    try {
      parsedOrders =
          (json['recentOrders'] as List).map((item) {
            try {
              return Order.fromJson(item);
            } catch (e) {
              debugPrint('Error parsing an Order: $e \nData: $item');
              rethrow;
            }
          }).toList();
    } catch (e) {
      debugPrint('Error parsing "recentOrders": $e');
    }

    Revenue parsedRevenue;
    try {
      parsedRevenue = Revenue.fromJson(json['revenue']);
    } catch (e) {
      debugPrint('Error parsing "revenue": $e');
      rethrow;
    }

    return Statistic(recentOrders: parsedOrders, revenue: parsedRevenue);
  }
}

class Revenue {
  final RevenueItem total;
  final RevenueItem cash;
  final RevenueItem bankTransfer;

  Revenue({
    required this.total,
    required this.cash,
    required this.bankTransfer,
  });

  factory Revenue.fromJson(Map<String, dynamic> json) {
    RevenueItem parseItem(Map<String, dynamic> itemJson, String name) {
      try {
        return RevenueItem.fromJson(itemJson);
      } catch (e) {
        debugPrint('Error parsing RevenueItem "$name": $e \nData: $itemJson');
        rethrow;
      }
    }

    return Revenue(
      total: parseItem(json['total'], 'total'),
      cash: parseItem(json['cash'], 'cash'),
      bankTransfer: parseItem(json['bankTransfer'], 'bankTransfer'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total': total.toJson(),
      'cash': cash.toJson(),
      'bankTransfer': bankTransfer.toJson(),
    };
  }
}

class RevenueItem {
  final double amount;
  final int count;

  RevenueItem({required this.amount, required this.count});

  factory RevenueItem.fromJson(Map<String, dynamic> json) {
    double parseAmount(dynamic value, String fieldName) {
      try {
        if (value is String) return double.parse(value);
        if (value is num) return value.toDouble();
        debugPrint('Warning: unexpected type for $fieldName -> $value');
        return 0;
      } catch (e) {
        debugPrint('Error parsing $fieldName: $value -> $e');
        return 0;
      }
    }

    int parseCount(dynamic value, String fieldName) {
      try {
        if (value is String) return int.parse(value);
        if (value is num) return value.toInt();
        debugPrint('Warning: unexpected type for $fieldName -> $value');
        return 0;
      } catch (e) {
        debugPrint('Error parsing $fieldName: $value -> $e');
        return 0;
      }
    }

    return RevenueItem(
      amount: parseAmount(json['amount'], 'amount'),
      count: parseCount(json['count'], 'count'),
    );
  }

  Map<String, dynamic> toJson() {
    return {'amount': amount, 'count': count};
  }
}
