import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../auth/domain/entities/profile.dart';
import '../../../purchase_request/data/models/purchase_request_model.dart';
import '../../../purchase_request/data/models/request_item_model.dart';
import '../../../expense_request/data/models/expense_request_model.dart';

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
            .select('*, profiles:employee_id(*), approvals_log(*, profiles:user_id(*))')
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
      await _client.from(table).update(updates).eq('id', requestId);

      // 4. Log approval
      await _client.from('approvals_log').insert({
        'request_id': requestId,
        'user_id': currentUser.id,
        'action': action,
        'comments': comments,
      });

      emit(RequestDetailsActionSuccess(message: 'requestProcessedSuccessfully'));
      // Reload details
      await loadDetails(requestId, type);
    } catch (e) {
      emit(RequestDetailsError(message: e.toString()));
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
