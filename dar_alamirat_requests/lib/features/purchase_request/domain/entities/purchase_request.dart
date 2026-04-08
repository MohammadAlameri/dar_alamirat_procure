import '../../../auth/domain/entities/profile.dart';

class PurchaseRequest {
  final String id;
  final String subject;
  final String? justification;
  final String status;
  final double totalAmount;
  final String? createdBy;
  final DateTime createdAt;
  final String? branchId;
  final Profile? profile; // For 'profiles:created_by' join

  PurchaseRequest({
    required this.id,
    required this.subject,
    this.justification,
    required this.status,
    this.totalAmount = 0.0,
    this.createdBy,
    required this.createdAt,
    this.branchId,
    this.profile,
  });

  String get type => 'procure';
}
