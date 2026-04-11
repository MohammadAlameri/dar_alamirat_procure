import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../auth/domain/entities/profile.dart';
import '../../domain/entities/purchase_request.dart';
import '../../domain/repositories/purchase_request_repository.dart';

// States
abstract class PurchaseRequestState extends Equatable {
  const PurchaseRequestState();
  @override
  List<Object?> get props => [];
}

class PurchaseRequestInitial extends PurchaseRequestState {}

class PurchaseRequestLoading extends PurchaseRequestState {}

class PurchaseRequestLoaded extends PurchaseRequestState {
  final List<PurchaseRequest> requests;
  const PurchaseRequestLoaded({required this.requests});
  @override
  List<Object?> get props => [requests];
}

class PurchaseRequestError extends PurchaseRequestState {
  final String message;
  const PurchaseRequestError({required this.message});
  @override
  List<Object?> get props => [message];
}

// Cubit
class PurchaseRequestCubit extends Cubit<PurchaseRequestState> {
  final PurchaseRequestRepository _repository;

  PurchaseRequestCubit(this._repository) : super(PurchaseRequestInitial());

  Future<void> loadRequests({
    required Profile profile,
    String? branchId,
    String status = 'all',
  }) async {
    if (isClosed) return;
    emit(PurchaseRequestLoading());
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
        emit(PurchaseRequestLoaded(requests: requests));
      }
    } catch (e) {
      if (!isClosed) {
        emit(PurchaseRequestError(message: e.toString()));
      }
    }
  }

  Future<void> createRequest({
    required String subject,
    required String description,
    required String branchId,
    required String createdBy,
    required double totalAmount,
    required List<Map<String, dynamic>> items,
    String? employeeName,
    String? jobTitle,
  }) async {
    try {
      await _repository.createRequest(
        subject: subject,
        description: description,
        branchId: branchId,
        createdBy: createdBy,
        totalAmount: totalAmount,
        items: items,
        employeeName: employeeName,
        jobTitle: jobTitle,
      );
    } catch (e) {
      emit(PurchaseRequestError(message: e.toString()));
    }
  }

  Future<void> updateStatus({
    required String id,
    required String status,
  }) async {
    try {
      await _repository.updateStatus(id: id, status: status);
    } catch (e) {
      emit(PurchaseRequestError(message: e.toString()));
    }
  }
}
