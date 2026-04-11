import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/error/failures.dart';
import '../../../auth/data/models/profile_model.dart';
import '../../../auth/domain/entities/profile.dart';
import '../../../management/data/models/branch_model.dart';
import '../../../management/data/models/user_branch_model.dart';
import '../../../management/domain/entities/user_branch.dart';
import '../../../purchase_request/data/models/purchase_request_model.dart';
import '../../../purchase_request/domain/entities/purchase_request.dart';
import '../../../expense_request/data/models/expense_request_model.dart';
import '../../../expense_request/domain/entities/expense_request.dart';
import '../../domain/repositories/dashboard_repository.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  final SupabaseClient supabase;

  DashboardRepositoryImpl(this.supabase);

  @override
  Future<Either<Failure, Profile>> getProfile(String userId) async {
    try {
      final data = await supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();
      return Right(ProfileModel.fromJson(data));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<UserBranch>>> getUserBranches(String userId, UserRole role) async {
    try {
      final isManager = role == UserRole.manager ||
          role == UserRole.general_manager ||
          role == UserRole.finance ||
          role == UserRole.it_procurement ||
          role == UserRole.admin;

      if (isManager) {
        final data = await supabase.from('branches').select('*').order('name');
        final allBranches = (data as List).map((e) => BranchModel.fromJson(e)).toList();
        return Right(allBranches
            .map((b) => UserBranchModel(
                  id: '',
                  userId: userId,
                  branchId: b.id,
                  accessLevel: 'full',
                  branch: b,
                ))
            .toList());
      } else {
        final data = await supabase
            .from('user_branches')
            .select('*, branches(*)')
            .eq('user_id', userId);
        final branches = (data as List).map((e) => UserBranchModel.fromJson(e)).toList();
        return Right(branches);
      }
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<PurchaseRequest>>> getPurchaseRequests({String? branchId, String? userId, String? status, String? dateFrom, String? dateTo}) async {
    try {
      var query = supabase.from('purchase_requests').select(
            '*, profiles:created_by(id, full_name, email, role, manager_id)',
          );

      if (branchId != null) query = query.eq('branch_id', branchId);
      if (userId != null) query = query.eq('created_by', userId);
      if (status != null) query = query.eq('status', status);
      if (dateFrom != null) query = query.gte('created_at', dateFrom);
      if (dateTo != null) query = query.lte('created_at', dateTo);

      final data = await query.order('created_at', ascending: false);
      final purchases = (data as List).map((e) => PurchaseRequestModel.fromJson(e)).toList();
      return Right(purchases);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ExpenseRequest>>> getExpenseRequests({String? branchId, String? userId, String? status, String? dateFrom, String? dateTo}) async {
    try {
      var query = supabase.from('expense_requests').select(
            '*, profiles:employee_id(id, full_name, email, role, manager_id)',
          );

      if (branchId != null) query = query.eq('branch_id', branchId);
      if (userId != null) query = query.eq('employee_id', userId);
      if (status != null) query = query.eq('status', status);
      if (dateFrom != null) query = query.gte('created_at', dateFrom);
      if (dateTo != null) query = query.lte('created_at', dateTo);

      final data = await query.order('created_at', ascending: false);
      final expenses = (data as List).map((e) => ExpenseRequestModel.fromJson(e)).toList();
      return Right(expenses);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
