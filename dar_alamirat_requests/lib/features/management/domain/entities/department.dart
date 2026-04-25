import 'structure_node.dart';

class Department extends StructureNode {
  Department({
    required super.id,
    required super.name,
    super.nameAr,
    super.description,
    super.phone,
    super.managerId,
    super.createdAt,
    super.updatedAt,
  });
}
