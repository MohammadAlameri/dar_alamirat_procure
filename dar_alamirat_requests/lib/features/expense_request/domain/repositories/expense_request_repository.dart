import '../../domain/entities/expense_request.dart';

abstract class ExpenseRequestRepository {
  Future<List<ExpenseRequest>> fetchRequests({
    String? branchId,
    String? userId,
    String? status,
  });

  Future<ExpenseRequest> createRequest({
    required String subject,
    required String description,
    required String branchId,
    required String employeeId,
    required double amount,
    required String highestApprovalLevel,
  });

  Future<ExpenseRequest> updateStatus({
    required String id,
    required String status,
  });
}
