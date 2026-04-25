import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../auth/domain/entities/profile.dart';
import '../../../management/domain/entities/user_structure_assignment.dart';
import '../../../purchase_request/domain/entities/purchase_request.dart';
import '../../../expense_request/domain/entities/expense_request.dart';

abstract class DashboardRepository {
  Future<Either<Failure, Profile>> getProfile(String userId);
  Future<Either<Failure, List<UserStructureAssignment>>> getUserAssignments(String userId, UserRole role);
  Future<Either<Failure, List<PurchaseRequest>>> getPurchaseRequests({String? branchId, String? userId, String? status, String? dateFrom, String? dateTo});
  Future<Either<Failure, List<ExpenseRequest>>> getExpenseRequests({String? branchId, String? userId, String? status, String? dateFrom, String? dateTo});
}
