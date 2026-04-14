import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../../../auth/domain/entities/profile.dart';
import '../../../purchase_request/data/models/purchase_request_model.dart';
import '../../../purchase_request/data/models/request_item_model.dart';
import '../../../expense_request/data/models/expense_request_model.dart';
import '../../../../core/services/notification_helper.dart';

abstract class RequestDetailsState {}

class RequestDetailsInitial extends RequestDetailsState {}

class RequestDetailsLoading extends RequestDetailsState {}

class RequestDetailsLoaded extends RequestDetailsState {
  final dynamic request; // PurchaseRequest or ExpenseRequest
  RequestDetailsLoaded({required this.request});
}

class RequestDetailsError extends RequestDetailsState {
  final String message;
  RequestDetailsError({required this.message});
}

class RequestDetailsActionSuccess extends RequestDetailsState {
  final String message;
  RequestDetailsActionSuccess({required this.message});
}

class RequestDetailsCubit extends Cubit<RequestDetailsState> {
  final _client = Supabase.instance.client;

  RequestDetailsCubit() : super(RequestDetailsInitial());

  Future<void> loadDetails(String id, String type) async {
    emit(RequestDetailsLoading());
    try {
      if (type == 'procure') {
        final response = await _client
            .from('purchase_requests')
            .select('*, profiles:created_by(*), request_items(*), approvals_log(*, profiles:user_id(*))')
            .eq('id', id)
            .single();
        
        final request = PurchaseRequestModel.fromJson(response);
        emit(RequestDetailsLoaded(request: request));
      } else {
        final response = await _client
            .from('expense_requests')
            .select('*, profiles:employee_id(*), approvals_log:expense_approvals_log(*, profiles:user_id(*))')
            .eq('id', id)
            .single();
        
        final request = ExpenseRequestModel.fromJson(response);
        emit(RequestDetailsLoaded(request: request));
      }
    } catch (e) {
      emit(RequestDetailsError(message: e.toString()));
    }
  }

  Future<void> performAction({
    required String requestId,
    required String type,
    required String action,
    required String comments,
    required Profile currentUser,
    Map<String, dynamic>? additionalUpdates,
  }) async {
    emit(RequestDetailsLoading());
    try {
      final table = type == 'procure' ? 'purchase_requests' : 'expense_requests';
      
      // 1. Determine new status based on action
      String newStatus = action; // Default to action name if it's the target status
      
      // 2. Prepare updates
      final Map<String, dynamic> updates = {
        'status': newStatus,
        if (additionalUpdates != null) ...additionalUpdates,
      };

      // 3. Update request table
      final response = await _client.from(table).update(updates).eq('id', requestId).select();
      
      if (response == null || (response as List).isEmpty) {
        throw Exception('Failed to update request status. You might not have permission or the request was not found.');
      }

      // 4. Log approval
      final logTable = type == 'procure' ? 'approvals_log' : 'expense_approvals_log';
      await _client.from(logTable).insert({
        'request_id': requestId,
        'user_id': currentUser.id,
        'action': action,
        'comments': comments,
      });

      // 5. Send push notification (fire-and-forget)
      _sendStatusNotification(
        requestId: requestId,
        type: type,
        action: action,
      );

      emit(RequestDetailsActionSuccess(message: 'requestProcessedSuccessfully'));
      // Reload details
      await loadDetails(requestId, type);
    } catch (e) {
      emit(RequestDetailsError(message: e.toString()));
    }
  }

  /// Fire-and-forget notification after status change
  Future<void> _sendStatusNotification({
    required String requestId,
    required String type,
    required String action,
  }) async {
    try {
      if (type == 'procure') {
        // Fetch the purchase request to get details
        final data = await _client
            .from('purchase_requests')
            .select('subject, branch_id, created_by')
            .eq('id', requestId)
            .single();

        NotificationHelper.onPurchaseStatusChanged(
          requestId: requestId,
          newStatus: action,
          subject: data['subject'] ?? '',
          branchId: data['branch_id'] ?? '',
          createdBy: data['created_by'],
        );
      } else {
        // Fetch the expense request to get details
        final data = await _client
            .from('expense_requests')
            .select('subject, branch_id, employee_id, highest_approval_level')
            .eq('id', requestId)
            .single();

        NotificationHelper.onExpenseStatusChanged(
          requestId: requestId,
          newStatus: action,
          subject: data['subject'] ?? '',
          branchId: data['branch_id'] ?? '',
          employeeId: data['employee_id'],
          highestApprovalLevel: data['highest_approval_level'] ?? 'manager',
        );
      }
    } catch (e) {
      debugPrint('[RequestDetailsCubit] Error sending notification: $e');
    }
  }

  Future<void> updatePurchaseItems({
    required String requestId,
    required List<RequestItemModel> items,
    required double totalAmount,
  }) async {
    try {
      // Upsert items
      final itemsJson = items.map((e) => e.toJson()).toList();
      await _client.from('request_items').upsert(itemsJson);
      
      // Update total amount in request
      await _client.from('purchase_requests').update({
        'total_amount': totalAmount,
      }).eq('id', requestId);
      
    } catch (e) {
      emit(RequestDetailsError(message: e.toString()));
    }
  }
}
