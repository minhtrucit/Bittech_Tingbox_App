// order_model.dart
import 'package:flutter/foundation.dart';
import 'package:ting_box/models/payment_info.dart';
import 'package:ting_box/models/product.dart';
import 'package:ting_box/models/statistic.dart';

double parseDouble(dynamic value, String fieldName) {
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

int parseInt(dynamic value, String fieldName) {
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

class Order {
  int? id;
  String? code;
  final int userId;
  final int distributorId;
  final String customerName;
  final String customerPhone;
  final String customerEmail;
  final String shippingAddress;
  final double discount;
  final double vat;
  double? subtotal;
  double paidAmount;
  final String paymentMethod;
  String? paymentStatus;
  final String? note;
  final int? tableId;
  final String? tableName; // Display name of table
  final String? orderType; // 'retail' or 'dinning'
  final bool? isTemp;
  final List<OrderItem> items;
  final PaymentInfo? paymentInfo;
  final double? totalAmount;
  final String? createdAt;
  final String? updatedAt;

  Order({
    this.id,
    required this.userId,
    required this.distributorId,
    this.tableId,
    this.tableName,
    this.orderType,
    this.isTemp,
    this.code,
    required this.customerName,
    required this.customerPhone,
    required this.customerEmail,
    this.subtotal,
    this.paymentStatus,
    required this.shippingAddress,
    this.discount = 0,
    this.vat = 0,
    this.paidAmount = 0,
    this.totalAmount,
    required this.paymentMethod,
    this.note,
    required this.items,
    this.paymentInfo,
    this.createdAt,
    this.updatedAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    int id = parseInt(json['id'], 'id');
    int? tableId = json['tableId'] != null ? parseInt(json['tableId'], 'tableId') : null;
    int userId = parseInt(json['userId'], 'userId');
    double subtotal = parseDouble(json['subtotal'], 'subtotal');
    int distributorId = parseInt(json['distributorId'], 'distributorId');
    String code = json['code'] ?? '';
    double discount = parseDouble(json['discount'], 'discount');
    double vat = parseDouble(json['vat'], 'vat');
    double paidAmount = parseDouble(json['paidAmount'], 'paidAmount');
    double totalAmount = parseDouble(
      json['totalAmount'] ?? json['amount'],
      'totalAmount',
    );

    String customerName = json['customerName'] ?? '';
    String customerPhone = json['customerPhone'] ?? '';
    String customerEmail = json['customerEmail'] ?? '';
    String shippingAddress = json['shippingAddress'] ?? '';
    String paymentMethod = json['paymentMethod'] ?? '';
    String? note = json['note'];
    String? createdAt = json['createdAt'];
    String? updatedAt = json['updatedAt'] ?? json['updated_at'];
    String? paymentStatus = json['paymentStatus'] ?? '';
    String? tableName = json['tableName'] ?? json['table_name'];
    String? orderType = json['orderType'] ?? json['order_type'];
    bool? isTemp = json['isTemp'];
    if (json['isTemp'] is int) {
      isTemp = json['isTemp'] == 1;
    }

    List<OrderItem> items = [];
    try {
      items =
          (json['items'] as List).map((item) {
            try {
              return OrderItem.fromJson(item);
            } catch (e) {
              debugPrint('Error parsing an OrderItem: $e \nData: $item');
              rethrow;
            }
          }).toList();
    } catch (e) {
      debugPrint('Error parsing "items": $e');
    }

    PaymentInfo? paymentInfo;
    try {
      if (json['paymentInfo'] != null) {
        paymentInfo = PaymentInfo.fromJson(json['paymentInfo']);
      }
    } catch (e) {
      debugPrint('Error parsing "paymentInfo": $e');
    }

    return Order(
      code: code,
      id: id,
      userId: userId,
      distributorId: distributorId,
      tableId: tableId,
      tableName: tableName,
      orderType: orderType,
      isTemp: isTemp,
      customerName: customerName,
      customerPhone: customerPhone,
      customerEmail: customerEmail,
      shippingAddress: shippingAddress,
      discount: discount,
      vat: vat,
      paidAmount: paidAmount,
      totalAmount: totalAmount,
      paymentMethod: paymentMethod,
      paymentStatus: paymentStatus,
      subtotal: subtotal,
      note: note,
      items: items,
      paymentInfo: paymentInfo,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'code': code,
      'tableId': tableId,
      'distributorId': distributorId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'customerEmail': customerEmail,
      'shippingAddress': shippingAddress,
      'discount': discount,
      'vat': vat,
      'paidAmount': paidAmount,
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentStatus,
      'note': note,
      'tableName': tableName,
      'orderType': orderType,
      'isTemp': isTemp,
      'items': items.map((e) => e.toJson()).toList(),
      'totalAmount': totalAmount,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'subtotal': subtotal,
      'id': id,
    };
  }
}

class OrderItem {
  final int productId;
  final int quantity;
  final double unitPrice;
  final String? note;
  final bool isVoided;
  final String? voidReason;
  final String? voidAt;
  final String? status;
  final Product? product; // Optional product details

  OrderItem({
    required this.productId,
    required this.quantity,
    required this.unitPrice,
    this.note,
    this.isVoided = false,
    this.voidReason,
    this.voidAt,
    this.status,
    this.product,
  });

  OrderItem copyWith({
    int? productId,
    int? quantity,
    double? unitPrice,
    String? note,
    bool? isVoided,
    String? voidReason,
    String? voidAt,
    String? status,
    Product? product,
  }) {
    return OrderItem(
      productId: productId ?? this.productId,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      note: note ?? this.note,
      isVoided: isVoided ?? this.isVoided,
      voidReason: voidReason ?? this.voidReason,
      voidAt: voidAt ?? this.voidAt,
      status: status ?? this.status,
      product: product ?? this.product,
    );
  }

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    int productId = parseInt(json['productId'], 'productId');
    int quantity = parseInt(json['quantity'], 'quantity');
    double unitPrice = parseDouble(json['unitPrice'], 'unitPrice');
    String? note = json['note'];
    bool isVoided = json['isVoided'] ?? json['is_voided'] ?? false;
    String? voidReason = json['voidReason'] ?? json['void_reason'];
    String? voidAt = json['voidAt'] ?? json['void_at'];
    String? status = json['status'];

    // Parse product if available in response
    Product? product;
    if (json['product'] != null) {
      try {
        product = Product.fromJson(json['product']);
      } catch (e) {
        debugPrint('Error parsing product in OrderItem: $e');
      }
    }

    return OrderItem(
      productId: productId,
      quantity: quantity,
      unitPrice: unitPrice,
      note: note,
      isVoided: isVoided,
      voidReason: voidReason,
      voidAt: voidAt,
      status: status,
      product: product,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'note': note,
      'isVoided': isVoided,
      'voidReason': voidReason,
      'voidAt': voidAt,
      'status': status,
      if (product != null) 'product': product!.toJson(),
    };
  }
}

class OrderListResponse {
  final List<Order> orders;
  final Pagination? pagination;

  OrderListResponse({required this.orders, this.pagination});

  factory OrderListResponse.fromJson(Map<String, dynamic> json) {
    List<Order> orders = [];
    if (json['data'] != null) {
      orders = (json['data'] as List).map((e) => Order.fromJson(e)).toList();
    }

    Pagination? pagination;
    if (json['pagination'] != null) {
      pagination = Pagination.fromJson(json['pagination']);
    }

    return OrderListResponse(orders: orders, pagination: pagination);
  }
}
