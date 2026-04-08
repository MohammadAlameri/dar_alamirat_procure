import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../auth/domain/entities/profile.dart';
import '../../domain/entities/expense_request.dart';
import '../../data/repositories/expense_request_repository.dart';

// Events
abstract class ExpenseRequestEvent {}

class LoadExpenseRequests extends ExpenseRequestEvent {
  final Profile profile;
  final String? branchId;
  final String status;

  LoadExpenseRequests({
    required this.profile,
    this.branchId,
    this.status = 'all',
  });
}

class CreateExpenseRequest extends ExpenseRequestEvent {
  final String subject;
  final String description;
  final String branchId;
  final String employeeId;
  final double amount;
  final String highestApprovalLevel;

  CreateExpenseRequest({
    required this.subject,
    required this.description,
    required this.branchId,
    required this.employeeId,
    required this.amount,
    required this.highestApprovalLevel,
  });
}

class UpdateExpenseRequestStatus extends ExpenseRequestEvent {
  final String id;
  final String status;

  UpdateExpenseRequestStatus({
    required this.id,
    required this.status,
  });
}

// States
abstract class ExpenseRequestState {}

class ExpenseRequestInitial extends ExpenseRequestState {}

class ExpenseRequestLoading extends ExpenseRequestState {}

class ExpenseRequestLoaded extends ExpenseRequestState {
  final List<ExpenseRequest> requests;

  ExpenseRequestLoaded({required this.requests});
}

class ExpenseRequestError extends ExpenseRequestState {
  final String message;

  ExpenseRequestError({required this.message});
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
      // Reload with current filters
      loadRequests(
        profile: Profile(id: employeeId, fullName: '', email: '', role: UserRole.employee),
        branchId: branchId,
      );
    } catch (e) {
      emit(ExpenseRequestError(message: e.toString()));
    }
  }

  Future<void> updateStatus({
    required String id,
    required String status,
  }) async {
    try {
      await _repository.updateStatus(id: id, status: status);
      // Reload will be triggered from the page
    } catch (e) {
      emit(ExpenseRequestError(message: e.toString()));
    }
  }
}
