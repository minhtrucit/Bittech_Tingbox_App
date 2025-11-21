class Distributor {
  final String id;
  final String name;
  final String code;
  final String? address;
  final String? phone;
  final String? email;
  final String? website;
  final bool? isActive;
  final String? createdAt;
  final String? updatedAt;

  Distributor({
    required this.id,
    required this.name,
    required this.code,
    this.address,
    this.phone,
    this.email,
    this.website,
    this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  factory Distributor.fromJson(Map<String, dynamic> json) {
    return Distributor(
      id: json['id'].toString(),
      name: json['name'],
      code: json['code'],
      address: json['address'],
      phone: json['phone'],
      email: json['email'],
      website: json['website'],
      isActive: json['isActive'],
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'address': address,
      'phone': phone,
      'email': email,
      'website': website,
      'isActive': isActive,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}