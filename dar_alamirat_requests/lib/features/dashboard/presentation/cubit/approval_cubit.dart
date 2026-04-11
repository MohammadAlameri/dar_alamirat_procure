import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../auth/domain/entities/profile.dart';
import '../../../purchase_request/domain/entities/purchase_request.dart';
import '../../../purchase_request/data/models/purchase_request_model.dart';
import '../../../expense_request/domain/entities/expense_request.dart';
import '../../../expense_request/data/models/expense_request_model.dart';

// Events
abstract class ApprovalEvent {}

class LoadApprovals extends ApprovalEvent {
  final Profile profile;
  final String? branchId;

  LoadApprovals({
    required this.profile,
    this.branchId,
  });
}

// States
abstract class ApprovalState {}

class ApprovalInitial extends ApprovalState {}

class ApprovalLoading extends ApprovalState {}

class ApprovalLoaded extends ApprovalState {
  final List<dynamic> pendingRequests;

  ApprovalLoaded({required this.pendingRequests});
}

class ApprovalError extends ApprovalState {
  final String message;

  ApprovalError({required this.message});
}

// Cubit
class ApprovalCubit extends Cubit<ApprovalState> {
  final _client = Supabase.instance.client;

  ApprovalCubit() : super(ApprovalInitial());

  Future<void> loadApprovals({
    required Profile profile,
    String? branchId,
  }) async {
    if (isClosed) return;
    emit(ApprovalLoading());
    try {
      final role = profile.role;
      final userId = profile.id;

      // 1. Fetch Purchase Requests
      var purchaseQuery = _client
          .from('purchase_requests')
          .select('*, profiles:created_by(id, full_name, email, role, manager_id)');

      if (branchId != null) {
        purchaseQuery = purchaseQuery.eq('branch_id', branchId);
      }

      final purchaseData = await purchaseQuery.order('created_at', ascending: false);
      final allPurchases = (purchaseData as List).map((e) => PurchaseRequestModel.fromJson(e)).toList();

      // Filter pending purchases by role
      List<PurchaseRequest> pendingPurchases = [];
      if (role == UserRole.manager) {
        pendingPurchases = allPurchases.where((r) => r.status == 'pending' || r.status == 'rejected_by_manager').toList();
      } else if (role == UserRole.itProcurement) {
        pendingPurchases = allPurchases.where((r) => ['manager_approved', 'finance_approved', 'received_by_staff', 'rejected_by_it', 'rejected_by_it_purchase'].contains(r.status)).toList();
      } else if (role == UserRole.finance) {
        pendingPurchases = allPurchases.where((r) => r.status == 'it_approved' || r.status == 'rejected_by_finance').toList();
      } else if (role == UserRole.employee) {
        pendingPurchases = allPurchases.where((r) => r.createdBy == userId && (r.status == 'purchased' || r.status == 'rejected_by_staff')).toList();
      } else if (role == UserRole.admin) {
        pendingPurchases = allPurchases;
      }

      // 2. Fetch Expense Requests
      var expenseQuery = _client
          .from('expense_requests')
          .select('*, profiles:employee_id(id, full_name, email, role, manager_id)');

      if (branchId != null) {
        expenseQuery = expenseQuery.eq('branch_id', branchId);
      }

      final expenseData = await expenseQuery.order('created_at', ascending: false);
      final allExpenses = (expenseData as List).map((e) => ExpenseRequestModel.fromJson(e)).toList();

      // Filter pending expenses by role
      List<ExpenseRequest> pendingExpenses = [];
      if (role == UserRole.manager) {
        pendingExpenses = allExpenses.where((e) => e.status == 'pending' || e.status == 'rejected_by_manager').toList();
      } else if (role == UserRole.finance) {
        pendingExpenses = allExpenses.where((e) => ['finance', 'general_manager'].contains(e.highestApprovalLevel) && (e.status == 'manager_approved' || e.status == 'rejected_by_finance')).toList();
      } else if (role == UserRole.generalManager) {
        pendingExpenses = allExpenses.where((e) => e.highestApprovalLevel == 'general_manager' && (e.status == 'finance_approved' || e.status == 'rejected_by_gm')).toList();
      } else if (role == UserRole.accountant) {
        pendingExpenses = allExpenses.where((e) {
          if (['paid', 'completed', 'received'].contains(e.status)) return false;
          if (e.highestApprovalLevel == 'manager' && e.status == 'manager_approved') return true;
          if (e.highestApprovalLevel == 'finance' && e.status == 'finance_approved') return true;
          if (e.highestApprovalLevel == 'general_manager' && e.status == 'gm_approved') return true;
          return false;
        }).toList();
      } else if (role == UserRole.admin) {
        pendingExpenses = allExpenses;
      }

      final pendingRequests = <dynamic>[...pendingPurchases, ...pendingExpenses];
      pendingRequests.sort((a, b) {
        final dateA = a is PurchaseRequest ? a.createdAt : (a as ExpenseRequest).createdAt;
        final dateB = b is PurchaseRequest ? b.createdAt : (b as ExpenseRequest).createdAt;
        return dateB.compareTo(dateA);
      });

      if (!isClosed) {
        emit(ApprovalLoaded(pendingRequests: pendingRequests));
      }
    } catch (e) {
      if (!isClosed) {
        emit(ApprovalError(message: e.toString()));
      }
    }
  }
}
