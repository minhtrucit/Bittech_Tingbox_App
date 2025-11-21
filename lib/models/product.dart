
class Product {
  final String id;
  final String name;
  final double price;
  final String url;
  int quantity;
  String? sku;
  String? distributorId;
  String? barcode;
  double? costPrice;
  List<String>? images;
  String? description;
  String? categoryId;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.url,
    this.categoryId,
    this.quantity = 1,
    this.sku,
    this.distributorId,
    this.barcode,
    this.costPrice,
    this.images,
    this.description,
  });

  // Tạo object từ JSON
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'],
      price: (json['price'] ?? 0).toDouble(),
      url: json['url'],
      quantity: json['quantity'] ?? 1,
      sku: json['sku'],
      distributorId: json['distributorId'],
      barcode: json['barcode'],
      costPrice:
          json['costPrice'] != null
              ? (json['costPrice'] as num).toDouble()
              : null,
      images: json['images'] != null ? List<String>.from(json['images']) : null,
      description: json['description'],
      categoryId: json['categoryId'],
    );
  }

  // Chuyển object về JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'url': url,
      'quantity': quantity,
      'sku': sku,
      'distributorId': distributorId,
      'barcode': barcode,
      'costPrice': costPrice,
      'images': images,
      'description': description,
      'categoryId': categoryId,
    };
  }
}
