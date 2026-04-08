import '../../domain/entities/branch.dart';

class BranchModel extends Branch {
  BranchModel({
    required super.id,
    required super.name,
    super.nameAr,
    super.code,
    super.address,
    super.phone,
    super.isActive,
  });

  factory BranchModel.fromJson(Map<String, dynamic> json) {
    return BranchModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      nameAr: json['name_ar'],
      code: json['code'],
      address: json['address'],
      phone: json['phone'],
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'name_ar': nameAr,
      'code': code,
      'address': address,
      'phone': phone,
      'is_active': isActive,
    };
  }
}

class UserBranchModel extends UserBranch {
  UserBranchModel({
    required super.id,
    required super.userId,
    required super.branchId,
    required super.accessLevel,
    super.branch,
  });

  factory UserBranchModel.fromJson(Map<String, dynamic> json) {
    return UserBranchModel(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      branchId: json['branch_id'] ?? '',
      accessLevel: json['access_level'] ?? 'view',
      branch: json['branches'] != null ? BranchModel.fromJson(json['branches']) : null,
    );
  }
}
