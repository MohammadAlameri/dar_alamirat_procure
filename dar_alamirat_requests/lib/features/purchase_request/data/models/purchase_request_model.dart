import '../../domain/entities/purchase_request.dart';
import '../../../auth/data/models/profile_model.dart';

class PurchaseRequestModel extends PurchaseRequest {
  PurchaseRequestModel({
    required super.id,
    required super.subject,
    super.justification,
    required super.status,
    super.totalAmount,
    super.createdBy,
    required super.createdAt,
    super.branchId,
    super.profile,
  });

  factory PurchaseRequestModel.fromJson(Map<String, dynamic> json) {
    return PurchaseRequestModel(
      id: json['id'] ?? '',
      subject: json['subject'] ?? '',
      justification: json['justification'],
      status: json['status'] ?? 'pending',
      totalAmount: (json['total_amount'] ?? 0).toDouble(),
      createdBy: json['created_by'] ?? '',
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      branchId: json['branch_id'],
      profile: json['profiles'] != null ? ProfileModel.fromJson(json['profiles']) : null,
    );
  }
}
