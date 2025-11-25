// order_model.dart
import 'package:ting_box/models/payment_info.dart';
import 'package:ting_box/models/product.dart';

double parseDouble(dynamic value, String fieldName) {
  try {
    if (value is String) return double.parse(value);
    if (value is num) return value.toDouble();
    print('Warning: unexpected type for $fieldName -> $value');
    return 0;
  } catch (e) {
    print('Error parsing $fieldName: $value -> $e');
    return 0;
  }
}

int parseInt(dynamic value, String fieldName) {
  try {
    if (value is String) return int.parse(value);
    if (value is num) return value.toInt();
    print('Warning: unexpected type for $fieldName -> $value');
    return 0;
  } catch (e) {
    print('Error parsing $fieldName: $value -> $e');
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
  final String paymentMethod;
  String? paymentStatus;
  final String? note;
  final List<OrderItem> items;
  final PaymentInfo? paymentInfo;
  final double? totalAmount;
  final String? createdAt;

  Order({
    this.id,
    required this.userId,
    required this.distributorId,
    this.code,
    required this.customerName,
    required this.customerPhone,
    required this.customerEmail,
    this.paymentStatus,
    required this.shippingAddress,
    this.discount = 0,
    this.totalAmount,
    required this.paymentMethod,
    this.note,
    required this.items,
    this.paymentInfo,
    this.createdAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    int id = parseInt(json['id'], 'id');
    int userId = parseInt(json['userId'], 'userId');
    int distributorId = parseInt(json['distributorId'], 'distributorId');
    String code = json['code'] ?? '';
    double discount = parseDouble(json['discount'], 'discount');
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
    String? paymentStatus = json['paymentStatus'] ?? '';

    List<OrderItem> items = [];
    try {
      items =
          (json['items'] as List).map((item) {
            try {
              return OrderItem.fromJson(item);
            } catch (e) {
              print('Error parsing an OrderItem: $e \nData: $item');
              rethrow;
            }
          }).toList();
    } catch (e) {
      print('Error parsing "items": $e');
    }

    PaymentInfo? paymentInfo;
    try {
      if (json['paymentInfo'] != null) {
        paymentInfo = PaymentInfo.fromJson(json['paymentInfo']);
      }
    } catch (e) {
      print('Error parsing "paymentInfo": $e');
    }

    return Order(
      code: code,
      id: id,
      userId: userId,
      distributorId: distributorId,
      customerName: customerName,
      customerPhone: customerPhone,
      customerEmail: customerEmail,
      shippingAddress: shippingAddress,
      discount: discount,
      totalAmount: totalAmount,
      paymentMethod: paymentMethod,
      paymentStatus: paymentStatus,
      note: note,
      items: items,
      paymentInfo: paymentInfo,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'code': code,
      'distributorId': distributorId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'customerEmail': customerEmail,
      'shippingAddress': shippingAddress,
      'discount': discount,
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentStatus,
      'note': note,
      'items': items.map((e) => e.toJson()).toList(),
      'totalAmount': totalAmount,
      'createdAt': createdAt,
      'id': id,
    };
  }
}

class OrderItem {
  final int productId;
  final int quantity;
  final double unitPrice;
  final Product? product; // Optional product details

  OrderItem({
    required this.productId,
    required this.quantity,
    required this.unitPrice,
    this.product,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    int productId = parseInt(json['productId'], 'productId');
    int quantity = parseInt(json['quantity'], 'quantity');
    double unitPrice = parseDouble(json['unitPrice'], 'unitPrice');

    // Parse product if available in response
    Product? product;
    if (json['product'] != null) {
      try {
        product = Product.fromJson(json['product']);
      } catch (e) {
        print('Error parsing product in OrderItem: $e');
      }
    }

    return OrderItem(
      productId: productId,
      quantity: quantity,
      unitPrice: unitPrice,
      product: product,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'quantity': quantity,
      'unitPrice': unitPrice,
      if (product != null) 'product': product!.toJson(),
    };
  }
}
