import '../../domain/entities/unit.dart';

class UnitModel extends Unit {
  UnitModel({
    required super.id,
    required super.name,
    super.divisionId,
    super.nameAr,
    super.description,
    super.phone,
    super.managerId,
    super.createdAt,
    super.updatedAt,
  });

  factory UnitModel.fromJson(Map<String, dynamic> json) {
    return UnitModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      divisionId: json['division_id'],
      nameAr: json['name_ar'],
      description: json['description'],
      phone: json['phone'],
      managerId: json['manager_id'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'division_id': divisionId,
      'name_ar': nameAr,
      'description': description,
      'phone': phone,
      'manager_id': managerId,
    };
  }
}
