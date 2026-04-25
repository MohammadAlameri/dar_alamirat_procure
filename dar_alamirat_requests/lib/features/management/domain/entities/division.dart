import 'structure_node.dart';

class Division extends StructureNode {
  final String? branchId;

  Division({
    required super.id,
    required super.name,
    this.branchId,
    super.nameAr,
    super.description,
    super.phone,
    super.managerId,
    super.createdAt,
    super.updatedAt,
  });
}
