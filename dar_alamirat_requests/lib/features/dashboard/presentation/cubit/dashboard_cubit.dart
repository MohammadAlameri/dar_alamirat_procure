import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/repositories/dashboard_repository.dart';
import 'dashboard_state.dart';
import '../../../auth/domain/entities/profile.dart';
import '../../../management/domain/entities/branch.dart';
import '../../../management/domain/entities/user_structure_assignment.dart';
import '../../../purchase_request/domain/entities/purchase_request.dart';
import '../../../expense_request/domain/entities/expense_request.dart';

class DashboardCubit extends Cubit<DashboardState> {
  final DashboardRepository repository;

  DashboardCubit(this.repository) : super(DashboardInitial());

  Future<void> loadDashboard({String? branchId}) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      emit(const DashboardError('User not logged in'));
      return;
    }

    emit(DashboardLoading());

    final profileResult = await repository.getProfile(user.id);
    
    await profileResult.fold(
      (failure) async => emit(DashboardError(failure.message)),
      (profile) async {
        final assignmentsResult = await repository.getUserAssignments(user.id, profile.role);
        
        await assignmentsResult.fold(
          (failure) async => emit(DashboardError(failure.message)),
          (assignments) async {
            // For dashboard context, we still look for "Branches" to filter requests
            // or we just take any node that can act as a context.
            // If the user is assigned to a Branch, we use it.
            // If they are assigned to a Department/Division/Unit, they might not have a "selectedBranch" yet.
            
            if (assignments.isEmpty) {
              emit(const DashboardError('Account access restricted: No assignments found.'));
              return;
            }

            Branch? selectedBranch;
            if (branchId != null) {
              // Try to find if this branchId is in user assignments (if they are assigned directly to branches)
              for (var a in assignments) {
                if (a.assignedNode is Branch && a.assignedNode!.id == branchId) {
                  selectedBranch = a.assignedNode as Branch;
                  break;
                }
              }
            }
            
            if (selectedBranch == null) {
              // Pick the first Branch found in assignments
              for (var a in assignments) {
                if (a.assignedNode is Branch) {
                  selectedBranch = a.assignedNode as Branch;
                  break;
                }
              }
            }

            await fetchDashboardData(
              profile: profile,
              userAssignments: assignments,
              selectedBranch: selectedBranch,
            );
          },
        );
      },
    );
  }

  Future<void> changeBranch(Branch branch) async {
    if (state is DashboardLoaded) {
      final currentState = state as DashboardLoaded;
      if (currentState.selectedBranch?.id == branch.id) return;

      await fetchDashboardData(
        profile: currentState.profile,
        userAssignments: currentState.userAssignments,
        selectedBranch: branch,
      );
    }
  }

  Future<void> fetchDashboardData({
    required Profile profile,
    required List<UserStructureAssignment> userAssignments,
    Branch? selectedBranch,
  }) async {
    final branchId = selectedBranch?.id;
    final userId = profile.role == UserRole.employee ? profile.id : null;

    final purchaseResult = await repository.getPurchaseRequests(
      branchId: branchId,
      userId: userId,
    );

    final expenseResult = await repository.getExpenseRequests(
      branchId: branchId,
      userId: userId,
    );

    purchaseResult.fold(
      (failure) => emit(DashboardError(failure.message)),
      (purchases) {
        expenseResult.fold(
          (failure) => emit(DashboardError(failure.message)),
          (expenses) {
            final stats = _calculateStats(purchases, expenses);
            
            emit(DashboardLoaded(
              profile: profile,
              userAssignments: userAssignments,
              selectedBranch: selectedBranch,
              purchaseRequests: purchases,
              expenseRequests: expenses,
              totalCount: stats['total']!,
              pendingCount: stats['pending']!,
              approvedCount: stats['approved']!,
              rejectedCount: stats['rejected']!,
            ));
          },
        );
      },
    );
  }

  Map<String, int> _calculateStats(List<PurchaseRequest> purchases, List<ExpenseRequest> expenses) {
    int totalCount = purchases.length + expenses.length;

    final pendingPR = purchases
        .where((r) => [
              'pending',
              'manager_approved',
              'it_approved',
              'finance_approved',
              'purchased',
            ].contains(r.status))
        .length;

    final pendingExp = expenses
        .where((e) =>
            !['completed', 'paid', 'received'].contains(e.status) &&
            !e.status.toLowerCase().contains('rejected'))
        .length;

    int pendingCount = pendingPR + pendingExp;

    int approvedCount = purchases.where((r) => r.status == 'completed').length +
        expenses.where((e) => e.status == 'completed').length;

    int rejectedCount = purchases.where((r) => r.status.toLowerCase().contains('rejected')).length +
        expenses.where((e) => e.status.toLowerCase().contains('rejected')).length;

    return {
      'total': totalCount,
      'pending': pendingCount,
      'approved': approvedCount,
      'rejected': rejectedCount,
    };
  }
}
