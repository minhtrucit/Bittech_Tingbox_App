import 'package:flutter/foundation.dart';

import 'order.dart';

class StatisticOrder {
  final List<Order> recentOrders;
  final Revenue revenue;
  final OrdersByPaymentMethod ordersByPaymentMethod;
  final OrdersByPaymentStatus ordersByPaymentStatus;

  StatisticOrder({
    required this.recentOrders,
    required this.revenue,
    required this.ordersByPaymentMethod,
    required this.ordersByPaymentStatus,
  });

  factory StatisticOrder.fromJson(Map<String, dynamic> json) {
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

    OrdersByPaymentMethod parsedOrdersByPaymentMethod;
    try {
      parsedOrdersByPaymentMethod = OrdersByPaymentMethod.fromJson(
        json['ordersByPaymentMethod'],
      );
    } catch (e) {
      debugPrint('Error parsing "ordersByPaymentMethod": $e');
      rethrow;
    }

    OrdersByPaymentStatus parsedOrdersByPaymentStatus;
    try {
      parsedOrdersByPaymentStatus = OrdersByPaymentStatus.fromJson(
        json['ordersByPaymentStatus'],
      );
    } catch (e) {
      debugPrint('Error parsing "ordersByPaymentStatus": $e');
      rethrow;
    }

    return StatisticOrder(
      recentOrders: parsedOrders,
      revenue: parsedRevenue,
      ordersByPaymentMethod: parsedOrdersByPaymentMethod,
      ordersByPaymentStatus: parsedOrdersByPaymentStatus,
    );
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

class OrdersByPaymentMethod {
  final List<OrdersByPaymentMethodItem> items;

  OrdersByPaymentMethod({required this.items});

  factory OrdersByPaymentMethod.fromJson(List<dynamic> list) {
    return OrdersByPaymentMethod(
      items: list.map((e) => OrdersByPaymentMethodItem.fromJson(e)).toList(),
    );
  }
}

class OrdersByPaymentMethodItem {
  final String paymentMethod;
  final int count;
  final int paymentMethodValue;
  final double totalAmount;

  OrdersByPaymentMethodItem({
    required this.paymentMethod,
    required this.count,
    required this.paymentMethodValue,
    required this.totalAmount,
  });

  factory OrdersByPaymentMethodItem.fromJson(Map<String, dynamic> json) {
  return OrdersByPaymentMethodItem(
    paymentMethod: json['paymentMethod']?.toString() ?? '',
    count: json['count'] is int ? json['count'] : int.tryParse(json['count'].toString()) ?? 0,
    paymentMethodValue: json['paymentMethodValue'] is int
        ? json['paymentMethodValue']
        : int.tryParse(json['paymentMethodValue'].toString()) ?? 0,
    totalAmount: (json['totalAmount'] is num)
        ? (json['totalAmount'] as num).toDouble()
        : double.tryParse(json['totalAmount'].toString()) ?? 0.0,
  );
}


  Map<String, dynamic> toJson() {
    return {
      'paymentMethod': paymentMethod,
      'count': count,
      'paymentMethodValue': paymentMethodValue,
      'totalAmount': totalAmount,
    };
  }
}

class OrdersByPaymentStatus {
  final List<OrdersByPaymentStatusItem> items;

  OrdersByPaymentStatus({required this.items});

  factory OrdersByPaymentStatus.fromJson(List<dynamic> list) {
    return OrdersByPaymentStatus(
      items: list.map((e) => OrdersByPaymentStatusItem.fromJson(e)).toList(),
    );
  }
}

class OrdersByPaymentStatusItem {
  final String paymentStatus;
  final int count;
  final int paymentStatusValue;
  final double totalAmount;

  OrdersByPaymentStatusItem({
    required this.paymentStatus,
    required this.count,
    required this.paymentStatusValue,
    required this.totalAmount,
  });

  factory OrdersByPaymentStatusItem.fromJson(Map<String, dynamic> json) {
    return OrdersByPaymentStatusItem(
      paymentStatus: json['paymentStatus']?.toString() ?? '',
      count: json['count'] is int ? json['count'] : int.tryParse(json['count'].toString()) ?? 0,
      paymentStatusValue: json['paymentStatusValue'] is int
          ? json['paymentStatusValue']
          : int.tryParse(json['paymentStatusValue'].toString()) ?? 0,
      totalAmount: (json['totalAmount'] is num)
          ? (json['totalAmount'] as num).toDouble()
          : double.tryParse(json['totalAmount'].toString()) ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'paymentStatus': paymentStatus,
      'count': count,
      'paymentStatusValue': paymentStatusValue,
      'totalAmount': totalAmount,
    };
  }
}
