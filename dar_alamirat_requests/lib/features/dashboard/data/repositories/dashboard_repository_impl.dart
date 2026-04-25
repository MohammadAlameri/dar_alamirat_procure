import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/error/failures.dart';
import '../../../auth/data/models/profile_model.dart';
import '../../../auth/domain/entities/profile.dart';
import '../../../management/data/models/branch_model.dart';
import '../../../management/data/models/user_structure_assignment_model.dart';
import '../../../management/domain/entities/user_structure_assignment.dart';
import '../../../purchase_request/data/models/purchase_request_model.dart';
import '../../../purchase_request/domain/entities/purchase_request.dart';
import '../../../expense_request/data/models/expense_request_model.dart';
import '../../../expense_request/domain/entities/expense_request.dart';
import '../../domain/repositories/dashboard_repository.dart';

import '../../../../core/network/network_info.dart';
import 'dart:io';

class DashboardRepositoryImpl implements DashboardRepository {
  final SupabaseClient supabase;
  final NetworkInfo networkInfo;

  DashboardRepositoryImpl(this.supabase, this.networkInfo);

  @override
  Future<Either<Failure, Profile>> getProfile(String userId) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure('No internet connection'));
    try {
      final data = await supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();
      return Right(ProfileModel.fromJson(data));
    } on SocketException {
      return const Left(NetworkFailure('Network Error'));
    } catch (e) {
      if (e.toString().contains('SocketException') || e.toString().contains('Failed host lookup')) {
        return const Left(NetworkFailure('Network Error'));
      }
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<UserStructureAssignment>>> getUserAssignments(String userId, UserRole role) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure('No internet connection'));
    try {
      final isManager = role == UserRole.manager ||
          role == UserRole.generalManager ||
          role == UserRole.finance ||
          role == UserRole.itProcurement ||
          role == UserRole.admin;

      if (isManager) {
        final data = await supabase.from('branches').select('*').eq('is_active', true).order('name');
        final allBranches = (data as List).map((e) => BranchModel.fromJson(e)).toList();
        return Right(allBranches
            .map((b) => UserStructureAssignmentModel(
                  id: '',
                  userId: userId,
                  branchId: b.id,
                  accessLevel: 'full',
                  assignedNode: b,
                ))
            .toList());
      } else {
        // Query the new user_structure_assignments table
        // We join with branches, departments, divisions, and units to get the assigned node details
        final data = await supabase
            .from('user_structure_assignments')
            .select('*, departments(*), branches(*), divisions(*), units(*)')
            .eq('user_id', userId);
        
        final assignments = (data as List).map((e) => UserStructureAssignmentModel.fromJson(e)).toList();
        return Right(assignments);
      }
    } on SocketException {
      return const Left(NetworkFailure('Network Error'));
    } catch (e) {
      if (e.toString().contains('SocketException') || e.toString().contains('Failed host lookup')) {
        return const Left(NetworkFailure('Network Error'));
      }
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<PurchaseRequest>>> getPurchaseRequests({String? branchId, String? userId, String? status, String? dateFrom, String? dateTo}) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure('No internet connection'));
    try {
      var query = supabase.from('purchase_requests').select(
            '*, profiles:created_by(id, full_name_en, full_name_ar, email, role, manager_id)',
          );

      if (branchId != null) query = query.eq('branch_id', branchId);
      if (userId != null) query = query.eq('created_by', userId);
      if (status != null) query = query.eq('status', status);
      if (dateFrom != null) query = query.gte('created_at', dateFrom);
      if (dateTo != null) query = query.lte('created_at', dateTo);

      final data = await query.order('created_at', ascending: false);
      final purchases = (data as List).map((e) => PurchaseRequestModel.fromJson(e)).toList();
      return Right(purchases);
    } on SocketException {
      return const Left(NetworkFailure('Network Error'));
    } catch (e) {
      if (e.toString().contains('SocketException') || e.toString().contains('Failed host lookup')) {
        return const Left(NetworkFailure('Network Error'));
      }
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ExpenseRequest>>> getExpenseRequests({String? branchId, String? userId, String? status, String? dateFrom, String? dateTo}) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure('No internet connection'));
    try {
      var query = supabase.from('expense_requests').select(
            '*, profiles:employee_id(id, full_name_en, full_name_ar, email, role, manager_id)',
          );

      if (branchId != null) query = query.eq('branch_id', branchId);
      if (userId != null) query = query.eq('employee_id', userId);
      if (status != null) query = query.eq('status', status);
      if (dateFrom != null) query = query.gte('created_at', dateFrom);
      if (dateTo != null) query = query.lte('created_at', dateTo);

      final data = await query.order('created_at', ascending: false);
      final expenses = (data as List).map((e) => ExpenseRequestModel.fromJson(e)).toList();
      return Right(expenses);
    } on SocketException {
      return const Left(NetworkFailure('Network Error'));
    } catch (e) {
      if (e.toString().contains('SocketException') || e.toString().contains('Failed host lookup')) {
        return const Left(NetworkFailure('Network Error'));
      }
      return Left(ServerFailure(e.toString()));
    }
  }
}
