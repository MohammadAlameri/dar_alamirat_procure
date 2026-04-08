import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../auth/domain/entities/profile.dart';
import '../../domain/entities/purchase_request.dart';
import '../../data/repositories/purchase_request_repository.dart';

// Events
abstract class PurchaseRequestEvent {}

class LoadPurchaseRequests extends PurchaseRequestEvent {
  final Profile profile;
  final String? branchId;
  final String status;

  LoadPurchaseRequests({
    required this.profile,
    this.branchId,
    this.status = 'all',
  });
}

class CreatePurchaseRequest extends PurchaseRequestEvent {
  final String subject;
  final String description;
  final String branchId;
  final String createdBy;
  final double totalAmount;
  final List<Map<String, dynamic>> items;

  CreatePurchaseRequest({
    required this.subject,
    required this.description,
    required this.branchId,
    required this.createdBy,
    required this.totalAmount,
    required this.items,
  });
}

class UpdatePurchaseRequestStatus extends PurchaseRequestEvent {
  final String id;
  final String status;

  UpdatePurchaseRequestStatus({
    required this.id,
    required this.status,
  });
}

// States
abstract class PurchaseRequestState {}

class PurchaseRequestInitial extends PurchaseRequestState {}

class PurchaseRequestLoading extends PurchaseRequestState {}

class PurchaseRequestLoaded extends PurchaseRequestState {
  final List<PurchaseRequest> requests;

  PurchaseRequestLoaded({required this.requests});
}

class PurchaseRequestError extends PurchaseRequestState {
  final String message;

  PurchaseRequestError({required this.message});
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
  }) async {
    try {
      await _repository.createRequest(
        subject: subject,
        description: description,
        branchId: branchId,
        createdBy: createdBy,
        totalAmount: totalAmount,
        items: items,
      );
      // Just reload - the page will handle proper parameters
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
      // Reload will be triggered from the page
    } catch (e) {
      emit(PurchaseRequestError(message: e.toString()));
    }
  }
}
