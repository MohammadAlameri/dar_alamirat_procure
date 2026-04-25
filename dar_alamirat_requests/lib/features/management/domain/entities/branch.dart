import 'structure_node.dart';

class Branch extends StructureNode {
  final String? code;
  final String? address;
  final bool isActive;
  final String? departmentId;

  Branch({
    required super.id,
    required super.name,
    super.nameAr,
    super.description,
    super.phone,
    super.managerId,
    this.code,
    this.address,
    this.isActive = true,
    this.departmentId,
    super.createdAt,
    super.updatedAt,
  });
}
