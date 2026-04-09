import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/repositories/dashboard_repository.dart';
import 'dashboard_state.dart';
import '../../../auth/domain/entities/profile.dart';
import '../../../management/domain/entities/branch.dart';
import '../../../purchase_request/domain/entities/purchase_request.dart';
import '../../../expense_request/domain/entities/expense_request.dart';

class DashboardCubit extends Cubit<DashboardState> {
  final DashboardRepository repository;

  DashboardCubit(this.repository) : super(DashboardInitial());

  Future<void> loadDashboard() async {
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
        final branchesResult = await repository.getUserBranches(user.id, profile.role);
        
        await branchesResult.fold(
          (failure) async => emit(DashboardError(failure.message)),
          (branches) async {
            Branch? initialBranch;
            if (branches.isNotEmpty) {
              final fullBranch = branches.where((b) => b.accessLevel == 'full').firstOrNull;
              initialBranch = fullBranch?.branch ?? branches.first.branch;
            }

            await fetchDashboardData(
              profile: profile,
              userBranches: branches,
              selectedBranch: initialBranch,
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
        userBranches: currentState.userBranches,
        selectedBranch: branch,
      );
    }
  }

  Future<void> fetchDashboardData({
    required Profile profile,
    required List<UserBranch> userBranches,
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
              userBranches: userBranches,
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
