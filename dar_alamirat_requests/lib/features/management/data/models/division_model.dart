import '../../domain/entities/division.dart';

class DivisionModel extends Division {
  DivisionModel({
    required super.id,
    required super.name,
    super.branchId,
    super.nameAr,
    super.description,
    super.phone,
    super.managerId,
    super.createdAt,
    super.updatedAt,
  });

  factory DivisionModel.fromJson(Map<String, dynamic> json) {
    return DivisionModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      branchId: json['branch_id'],
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
      'branch_id': branchId,
      'name_ar': nameAr,
      'description': description,
      'phone': phone,
      'manager_id': managerId,
    };
  }
}
