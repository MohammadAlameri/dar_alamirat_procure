import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../auth/domain/entities/profile.dart';
import '../../domain/entities/expense_request.dart';
import '../../domain/repositories/expense_request_repository.dart';
import '../../../../core/services/notification_helper.dart';

// States
abstract class ExpenseRequestState extends Equatable {
  const ExpenseRequestState();
  @override
  List<Object?> get props => [];
}

class ExpenseRequestInitial extends ExpenseRequestState {}

class ExpenseRequestLoading extends ExpenseRequestState {}

class ExpenseRequestLoaded extends ExpenseRequestState {
  final List<ExpenseRequest> requests;
  const ExpenseRequestLoaded({required this.requests});
  @override
  List<Object?> get props => [requests];
}

class ExpenseRequestError extends ExpenseRequestState {
  final String message;
  const ExpenseRequestError({required this.message});
  @override
  List<Object?> get props => [message];
}

// Cubit
class ExpenseRequestCubit extends Cubit<ExpenseRequestState> {
  final ExpenseRequestRepository _repository;

  ExpenseRequestCubit(this._repository) : super(ExpenseRequestInitial());

  Future<void> loadRequests({
    required Profile profile,
    String? branchId,
    String status = 'all',
  }) async {
    if (isClosed) return;
    emit(ExpenseRequestLoading());
    try {
      final role = profile.role;
      final userId = profile.id;

      String? filterUserId;
      if (role == UserRole.employee) {
        filterUserId = userId;
      }

      final requests = await _repository.fetchRequests(
        branchId: branchId,
        userId: filterUserId,
        status: status,
      );

      if (!isClosed) {
        emit(ExpenseRequestLoaded(requests: requests));
      }
    } catch (e) {
      if (!isClosed) {
        emit(ExpenseRequestError(message: e.toString()));
      }
    }
  }

  Future<void> createRequest({
    required String subject,
    required String description,
    required String branchId,
    required String employeeId,
    required double amount,
    required String highestApprovalLevel,
    String? employeeName,
  }) async {
    try {
      await _repository.createRequest(
        subject: subject,
        description: description,
        branchId: branchId,
        employeeId: employeeId,
        amount: amount,
        highestApprovalLevel: highestApprovalLevel,
      );

      // Send notification to managers
      NotificationHelper.onExpenseRequestCreated(
        subject: subject,
        branchId: branchId,
        createdByName: employeeName ?? 'موظف',
      );
    } catch (e) {
      emit(ExpenseRequestError(message: e.toString()));
    }
  }

  Future<void> updateStatus({
    required String id,
    required String status,
    String? subject,
    String? branchId,
    String? employeeId,
    String? highestApprovalLevel,
  }) async {
    try {
      await _repository.updateStatus(id: id, status: status);

      // Send notification about status change
      if (subject != null && branchId != null) {
        NotificationHelper.onExpenseStatusChanged(
          requestId: id,
          newStatus: status,
          subject: subject,
          branchId: branchId,
          employeeId: employeeId,
          highestApprovalLevel: highestApprovalLevel ?? 'manager',
        );
      }
    } catch (e) {
      emit(ExpenseRequestError(message: e.toString()));
    }
  }
}
