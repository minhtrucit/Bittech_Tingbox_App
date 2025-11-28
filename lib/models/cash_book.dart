class CashBook {
  final int? id;
  final String name;
  final String date;
  final double openingAmount;
  final int configId;
  final String type;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  CashBook({
    this.id,
    required this.name,
    required this.date,
    required this.openingAmount,
    required this.configId,
    required this.type,
    this.createdAt,
    this.updatedAt,
  });

  factory CashBook.fromJson(Map<String, dynamic> json) {
    return CashBook(
      id: json['id'] as int?,
      name: json['name'] as String,
      date: json['date'] as String,
      openingAmount: (json['openingAmount'] as num).toDouble(),
      configId: json['configId'] as int,
      type: json['type'] as String,
      createdAt:
          json['createdAt'] != null
              ? DateTime.parse(json['createdAt'] as String)
              : null,
      updatedAt:
          json['updatedAt'] != null
              ? DateTime.parse(json['updatedAt'] as String)
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'date': date,
      'openingAmount': openingAmount,
      'configId': configId,
      'type': type,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }

  CashBook copyWith({
    int? id,
    String? name,
    String? date,
    double? openingAmount,
    int? configId,
    String? type,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CashBook(
      id: id ?? this.id,
      name: name ?? this.name,
      date: date ?? this.date,
      openingAmount: openingAmount ?? this.openingAmount,
      configId: configId ?? this.configId,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
