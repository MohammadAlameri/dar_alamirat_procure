import '../../../auth/domain/entities/profile.dart';
import '../../../purchase_request/domain/entities/request_item.dart';

class ExpenseRequest {
  final String id;
  final String subject;
  final String statement;
  final double amount;
  final String status;
  final String highestApprovalLevel;
  final String employeeId;
  final DateTime createdAt;
  final String? branchId;
  final Profile? profile; 
  final List<ApprovalLog> logs;

  ExpenseRequest({
    required this.id,
    required this.subject,
    required this.statement,
    required this.amount,
    required this.status,
    required this.highestApprovalLevel,
    required this.employeeId,
    required this.createdAt,
    this.branchId,
    this.profile,
    this.logs = const [],
  });

  String get type => 'expense';

  ExpenseRequest copyWith({
    String? status,
    List<ApprovalLog>? logs,
  }) {
    return ExpenseRequest(
      id: id,
      subject: subject,
      statement: statement,
      amount: amount,
      status: status ?? this.status,
      highestApprovalLevel: highestApprovalLevel,
      employeeId: employeeId,
      createdAt: createdAt,
      branchId: branchId,
      profile: profile,
      logs: logs ?? this.logs,
    );
  }
}
