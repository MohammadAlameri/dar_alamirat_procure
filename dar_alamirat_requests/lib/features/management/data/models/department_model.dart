import '../../domain/entities/department.dart';

class DepartmentModel extends Department {
  DepartmentModel({
    required super.id,
    required super.name,
    super.nameAr,
    super.description,
    super.phone,
    super.managerId,
    super.createdAt,
    super.updatedAt,
  });

  factory DepartmentModel.fromJson(Map<String, dynamic> json) {
    return DepartmentModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
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
      'name_ar': nameAr,
      'description': description,
      'phone': phone,
      'manager_id': managerId,
    };
  }
}
