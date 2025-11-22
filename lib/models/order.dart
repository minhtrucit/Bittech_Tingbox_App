// order_model.dart

class Order {
  final int userId;
  final int distributorId;
  final String customerName;
  final String customerPhone;
  final String customerEmail;
  final String shippingAddress;
  final int discount;
  final String paymentMethod;
  final String? note;
  final List<OrderItem> items;

  Order({
    required this.userId,
    required this.distributorId,
    required this.customerName,
    required this.customerPhone,
    required this.customerEmail,
    required this.shippingAddress,
     this.discount = 0,
    required this.paymentMethod,
     this.note,
    required this.items,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      userId: json['userId'],
      distributorId: json['distributorId'],
      customerName: json['customerName'],
      customerPhone: json['customerPhone'],
      customerEmail: json['customerEmail'],
      shippingAddress: json['shippingAddress'],
      discount: json['discount'],
      paymentMethod: json['paymentMethod'],
      note: json['note'],
      items: (json['items'] as List)
          .map((item) => OrderItem.fromJson(item))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'distributorId': distributorId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'customerEmail': customerEmail,
      'shippingAddress': shippingAddress,
      'discount': discount,
      'paymentMethod': paymentMethod,
      'note': note,
      'items': items.map((e) => e.toJson()).toList(),
    };
  }
}

class OrderItem {
  final int productId;
  final int quantity;
  final int unitPrice;

  OrderItem({
    required this.productId,
    required this.quantity,
    required this.unitPrice,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      productId: json['productId'],
      quantity: json['quantity'],
      unitPrice: json['unitPrice'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'quantity': quantity,
      'unitPrice': unitPrice,
    };
  }
}
