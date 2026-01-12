import 'category.dart';
import 'distributor.dart';

class Product {
  final int id;
  final String name;
  final double price;
  String? url;
  int quantity;
  String? sku;
  int? distributorId;
  Distributor? distributor;
  String? barcode;
  double? costPrice;
  List<ProductImage>? images;
  String? description;
  int? categoryId;
  Category? category;
  bool? isActive;
  String? createdAt;
  String? updatedAt;
  bool isEmbedded;
  String embeddingUrl;

  Product({
    required this.id,
    required this.name,
    required this.price,
    this.url,
    this.quantity = 1,
    this.sku,
    this.distributorId,
    this.distributor,
    this.barcode,
    this.costPrice,
    this.images,
    this.description,
    this.categoryId,
    this.category,
    this.isActive,
    this.createdAt,
    this.updatedAt,
    this.isEmbedded = false,
    this.embeddingUrl = "",
  });

  Product copyWith({
    int? id,
    String? name,
    double? price,
    String? url,
    int? quantity,
    String? sku,
    int? distributorId,
    Distributor? distributor,
    String? barcode,
    double? costPrice,
    List<ProductImage>? images,
    String? description,
    int? categoryId,
    Category? category,
    bool? isActive,
    String? createdAt,
    String? updatedAt,
    bool? isEmbedded,
    String? embeddingUrl,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      url: url ?? this.url,
      quantity: quantity ?? this.quantity,
      sku: sku ?? this.sku,
      distributorId: distributorId ?? this.distributorId,
      distributor: distributor ?? this.distributor,
      barcode: barcode ?? this.barcode,
      costPrice: costPrice ?? this.costPrice,
      images: images ?? this.images,
      description: description ?? this.description,
      categoryId: categoryId ?? this.categoryId,
      category: category ?? this.category,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isEmbedded: isEmbedded ?? this.isEmbedded,
      embeddingUrl: embeddingUrl ?? this.embeddingUrl,
    );
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'],
      price: double.tryParse(json['price'].toString()) ?? 0.0,
      url: json['thumbnailUrl'],
      quantity: 1,
      sku: json['sku'],
      distributorId: json['distributorId'],
      distributor:
          json['distributor'] != null
              ? Distributor.fromJson(json['distributor'])
              : null,
      barcode: json['barcode'],
      costPrice:
          json['costPrice'] != null
              ? double.tryParse(json['costPrice'].toString()) ?? 0.0
              : null,
      images:
          json['images'] != null
              ? (json['images'] as List)
                  .map((e) => ProductImage.fromJson(e))
                  .toList()
              : [],
      description: json['description'],
      categoryId: json['categoryId'],
      category:
          json['category'] != null ? Category.fromJson(json['category']) : null,
      isActive: json['isActive'],
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'thumbnailUrl': url,
      'quantity': quantity,
      'sku': sku,
      'distributorId': distributorId,
      'distributor': distributor?.toJson(),
      'barcode': barcode,
      'costPrice': costPrice,
      'images': images?.map((e) => e.toJson()).toList() ?? [],
      'description': description,
      'categoryId': categoryId,
      'category': category?.toJson(),
      'isActive': isActive,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'isEmbedded': isEmbedded,
      'embeddingUrl': embeddingUrl,
    };
  }
}

class ProductImage {
  final String id;
  final String productId;
  final String url;
  final String? alt;
  final bool? isPrimary;
  final int? sortOrder;
  final String? createdAt;
  final String? updatedAt;

  ProductImage({
    required this.id,
    required this.productId,
    required this.url,
    this.alt,
    this.isPrimary,
    this.sortOrder,
    this.createdAt,
    this.updatedAt,
  });

  factory ProductImage.fromJson(Map<String, dynamic> json) {
    return ProductImage(
      id: json['id'].toString(),
      productId: json['productId'].toString(),
      url: json['url'],
      alt: json['alt'],
      isPrimary: json['isPrimary'],
      sortOrder: json['sortOrder'],
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productId': productId,
      'url': url,
      'alt': alt,
      'isPrimary': isPrimary,
      'sortOrder': sortOrder,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}

String getProductImage(dynamic product) {
  // Backend trả thumbnailUrl
  if (product.thumbnailUrl != null &&
      product.thumbnailUrl!.toString().isNotEmpty) {
    return product.thumbnailUrl!;
  }

  // Backend trả images = [url1, url2]
  if (product.images != null && product.images!.isNotEmpty) {
    final first = product.images!.first;

    if (first is String) {
      return first;
    }

    if (first is Map && first['url'] != null) {
      return first['url'];
    }
  }

  // AI model trả trực tiếp field url
  if (product.url != null && product.url.toString().isNotEmpty) {
    return product.url;
  }

  return ""; // fallback khi không có ảnh
}
