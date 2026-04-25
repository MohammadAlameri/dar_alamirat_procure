import 'package:equatable/equatable.dart';
import '../../../auth/domain/entities/profile.dart';
import '../../../management/domain/entities/branch.dart';
import '../../../management/domain/entities/user_structure_assignment.dart';
import '../../../purchase_request/domain/entities/purchase_request.dart';
import '../../../expense_request/domain/entities/expense_request.dart';

abstract class DashboardState extends Equatable {
  const DashboardState();

  @override
  List<Object?> get props => [];
}

class DashboardInitial extends DashboardState {}

class DashboardLoading extends DashboardState {}

class DashboardLoaded extends DashboardState {
  final Profile profile;
  final List<UserStructureAssignment> userAssignments;
  final Branch? selectedBranch;
  final List<PurchaseRequest> purchaseRequests;
  final List<ExpenseRequest> expenseRequests;
  final int totalCount;
  final int pendingCount;
  final int approvedCount;
  final int rejectedCount;

  const DashboardLoaded({
    required this.profile,
    required this.userAssignments,
    this.selectedBranch,
    required this.purchaseRequests,
    required this.expenseRequests,
    required this.totalCount,
    required this.pendingCount,
    required this.approvedCount,
    required this.rejectedCount,
  });

  @override
  List<Object?> get props => [
        profile,
        userAssignments,
        selectedBranch,
        purchaseRequests,
        expenseRequests,
        totalCount,
        pendingCount,
        approvedCount,
        rejectedCount,
      ];

  DashboardLoaded copyWith({
    Profile? profile,
    List<UserStructureAssignment>? userAssignments,
    Branch? selectedBranch,
    List<PurchaseRequest>? purchaseRequests,
    List<ExpenseRequest>? expenseRequests,
    int? totalCount,
    int? pendingCount,
    int? approvedCount,
    int? rejectedCount,
  }) {
    return DashboardLoaded(
      profile: profile ?? this.profile,
      userAssignments: userAssignments ?? this.userAssignments,
      selectedBranch: selectedBranch ?? this.selectedBranch,
      purchaseRequests: purchaseRequests ?? this.purchaseRequests,
      expenseRequests: expenseRequests ?? this.expenseRequests,
      totalCount: totalCount ?? this.totalCount,
      pendingCount: pendingCount ?? this.pendingCount,
      approvedCount: approvedCount ?? this.approvedCount,
      rejectedCount: rejectedCount ?? this.rejectedCount,
    );
  }
}

class DashboardError extends DashboardState {
  final String message;
  const DashboardError(this.message);

  @override
  List<Object?> get props => [message];
}
