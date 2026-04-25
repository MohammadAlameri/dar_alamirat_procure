abstract class StructureNode {
  final String id;
  final String name;
  final String? nameAr;
  final String? description;
  final String? phone;
  final String? managerId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  StructureNode({
    required this.id,
    required this.name,
    this.nameAr,
    this.description,
    this.phone,
    this.managerId,
    this.createdAt,
    this.updatedAt,
  });

  String get displayName => nameAr ?? name;
}
