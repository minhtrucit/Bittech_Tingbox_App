class Bank {
  final int id;
  final String name;
  final String code;
  final String shortName;
  final String logo;

  Bank({
    required this.id,
    required this.name,
    required this.code,
    required this.shortName,
    required this.logo,
  });

  factory Bank.fromJson(Map<String, dynamic> json) {
    return Bank(
      id: json['id'],
      name: json['name'],
      code: json['code'],
      shortName: json['shortName'],
      logo: json['logo'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'shortName': shortName,
      'logo': logo,
    };
  }
}