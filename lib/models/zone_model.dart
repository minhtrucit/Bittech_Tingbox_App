import 'table_model.dart';

class ZoneModel {
  final int id;
  final int configId;
  final String name;
  final String? description;
  final bool isActive;
  final List<TableModel>? tables;

  ZoneModel({
    required this.id,
    required this.configId,
    required this.name,
    this.description,
    this.isActive = true,
    this.tables,
  });

  factory ZoneModel.fromJson(Map<String, dynamic> json) {
    return ZoneModel(
      id: json['id'],
      configId: json['configId'],
      name: json['name'],
      description: json['description'],
      isActive: json['isActive'] ?? true,
      tables: json['tables'] != null
          ? (json['tables'] as List).map((i) => TableModel.fromJson(i)).toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'configId': configId,
      'name': name,
      'description': description,
      'isActive': isActive,
      'tables': tables?.map((i) => i.toJson()).toList(),
    };
  }

  ZoneModel copyWith({
    int? id,
    int? configId,
    String? name,
    String? description,
    bool? isActive,
    List<TableModel>? tables,
  }) {
    return ZoneModel(
      id: id ?? this.id,
      configId: configId ?? this.configId,
      name: name ?? this.name,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
      tables: tables ?? this.tables,
    );
  }
}
