import '../../domain/entities/purchase_request.dart';
import '../../../auth/data/models/profile_model.dart';
import 'request_item_model.dart';

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
    super.items,
    super.logs,
    super.suggestedSuppliers,
    super.budgetLineItem,
    super.commitmentNumber,
    super.amountInWords,
    super.budgetStatus,
    super.staffAcceptanceStatus,
    super.staffRejectionReason,
    super.staffReceivingDate,
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
      items: json['request_items'] != null
          ? (json['request_items'] as List).map((e) => RequestItemModel.fromJson(e)).toList()
          : [],
      logs: json['approvals_log'] != null
          ? (json['approvals_log'] as List).map((e) => ApprovalLogModel.fromJson(e)).toList()
          : [],
      suggestedSuppliers: json['suggested_suppliers'],
      budgetLineItem: json['budget_line_item'],
      commitmentNumber: json['commitment_number'],
      amountInWords: json['amount_in_words'],
      budgetStatus: json['budget_status'],
      staffAcceptanceStatus: json['staff_acceptance_status'],
      staffRejectionReason: json['staff_rejection_reason'],
      staffReceivingDate: json['staff_receiving_date'] != null
          ? DateTime.parse(json['staff_receiving_date'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'subject': subject,
      'justification': justification,
      'status': status,
      'total_amount': totalAmount,
      'suggested_suppliers': suggestedSuppliers,
      'budget_line_item': budgetLineItem,
      'commitment_number': commitmentNumber,
      'amount_in_words': amountInWords,
      'budget_status': budgetStatus,
      'staff_acceptance_status': staffAcceptanceStatus,
      'staff_rejection_reason': staffRejectionReason,
      'staff_receiving_date': staffReceivingDate?.toIso8601String(),
    };
  }
}
