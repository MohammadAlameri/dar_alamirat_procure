import 'structure_node.dart';

class Unit extends StructureNode {
  final String? divisionId;

  Unit({
    required super.id,
    required super.name,
    this.divisionId,
    super.nameAr,
    super.description,
    super.phone,
    super.managerId,
    super.createdAt,
    super.updatedAt,
  });
}
