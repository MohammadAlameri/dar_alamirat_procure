import '../../../auth/domain/entities/profile.dart';

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
  final Profile? profile; // For joins

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
  });

  String get type => 'expense';
}
