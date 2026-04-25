import 'package:dar_alamirat_requests/features/auth/domain/entities/profile.dart';
import 'structure_node.dart';

class UserStructureAssignment {
  final String id;
  final String userId;
  final String? departmentId;
  final String? branchId;
  final String? divisionId;
  final String? unitId;
  final String accessLevel;
  final Profile? profile;
  final StructureNode? assignedNode;

  UserStructureAssignment({
    required this.id,
    required this.userId,
    this.departmentId,
    this.branchId,
    this.divisionId,
    this.unitId,
    required this.accessLevel,
    this.profile,
    this.assignedNode,
  });
}
