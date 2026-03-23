class Menu {
  final String? documentId;
  final String? businessName;
  final String? businessInfo;
  final List<MenuItem> menuItems;

  Menu({
    this.documentId,
    this.businessName,
    this.businessInfo,
    required this.menuItems,
  });

  factory Menu.fromJson(Map<String, dynamic> json, {String? documentId}) {
    return Menu(
      documentId: documentId ?? json['document_id'],
      businessName: json['business_name'],
      businessInfo: json['business_info'],
      menuItems:
          json['menu_items'] != null
              ? (json['menu_items'] as List)
                  .map((e) => MenuItem.fromJson(e))
                  .toList()
              : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'business_name': businessName,
      'business_info': businessInfo,
      'menu_items': menuItems.map((e) => e.toJson()).toList(),
    };
  }
}

class MenuItem {
  final String? category;
  final String? name;
  final double price;
  final String? thumbnailUrl;
  final String? description;

  MenuItem({
    this.category,
    this.name,
    required this.price,
    this.thumbnailUrl,
    this.description,
  });

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    // Xử lý giá tiền: Backend trả về Optional[str]
    double parsePrice(dynamic p) {
      if (p == null) return 0.0;
      if (p is num) return p.toDouble();
      if (p is String) {
        // Xóa dấu chấm/dấu phẩy phân cách hàng nghìn (ví dụ "90.000" -> "90000")
        String cleanPrice = p.replaceAll('.', '').replaceAll(',', '');
        return double.tryParse(cleanPrice) ?? 0.0;
      }
      return 0.0;
    }

    return MenuItem(
      category: json['category'],
      name: json['name'],
      price: parsePrice(json['price']),
      thumbnailUrl: json['thumbnail_url'],
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category': category,
      'name': name,
      'price': price,
      'thumbnail_url': thumbnailUrl,
      'description': description,
    };
  }
}
