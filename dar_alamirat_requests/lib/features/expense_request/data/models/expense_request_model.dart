import '../../domain/entities/expense_request.dart';
import '../../../auth/data/models/profile_model.dart';
import '../../../purchase_request/data/models/request_item_model.dart';

class ExpenseRequestModel extends ExpenseRequest {
  ExpenseRequestModel({
    required super.id,
    required super.subject,
    required super.statement,
    required super.amount,
    required super.status,
    required super.highestApprovalLevel,
    required super.employeeId,
    required super.createdAt,
    super.branchId,
    super.profile,
    super.logs,
  });

  factory ExpenseRequestModel.fromJson(Map<String, dynamic> json) {
    return ExpenseRequestModel(
      id: json['id'] ?? '',
      subject: json['subject'] ?? '',
      statement: json['description'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      status: json['status'] ?? 'pending',
      highestApprovalLevel: json['highest_approval_level'] ?? 'manager',
      employeeId: json['employee_id'] ?? '',
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      branchId: json['branch_id'],
      profile: json['profiles'] != null ? ProfileModel.fromJson(json['profiles']) : null,
      logs: json['approvals_log'] != null
          ? (json['approvals_log'] as List).map((e) => ApprovalLogModel.fromJson(e)).toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'subject': subject,
      'statement': statement,
      'amount': amount,
      'status': status,
      'highest_approval_level': highestApprovalLevel,
    };
  }
}
