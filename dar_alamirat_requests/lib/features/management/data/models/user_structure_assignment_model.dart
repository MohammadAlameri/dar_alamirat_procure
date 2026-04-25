import 'package:dar_alamirat_requests/features/auth/data/models/profile_model.dart';
import '../../domain/entities/user_structure_assignment.dart';
import 'department_model.dart';
import 'branch_model.dart';
import 'division_model.dart';
import 'unit_model.dart';

class UserStructureAssignmentModel extends UserStructureAssignment {
  UserStructureAssignmentModel({
    required super.id,
    required super.userId,
    super.departmentId,
    super.branchId,
    super.divisionId,
    super.unitId,
    required super.accessLevel,
    super.profile,
    super.assignedNode,
  });

  factory UserStructureAssignmentModel.fromJson(Map<String, dynamic> json) {
    return UserStructureAssignmentModel(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      departmentId: json['department_id'],
      branchId: json['branch_id'],
      divisionId: json['division_id'],
      unitId: json['unit_id'],
      accessLevel: json['access_level'] ?? 'view',
      profile: json['profiles'] != null ? ProfileModel.fromJson(json['profiles']) : null,
      assignedNode: _parseNode(json),
    );
  }

  static dynamic _parseNode(Map<String, dynamic> json) {
    if (json['departments'] != null) return DepartmentModel.fromJson(json['departments']);
    if (json['branches'] != null) return BranchModel.fromJson(json['branches']);
    if (json['divisions'] != null) return DivisionModel.fromJson(json['divisions']);
    if (json['units'] != null) return UnitModel.fromJson(json['units']);
    return null;
  }
}
