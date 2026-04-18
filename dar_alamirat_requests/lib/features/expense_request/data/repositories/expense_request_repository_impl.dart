import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/expense_request.dart';
import '../../domain/repositories/expense_request_repository.dart';
import '../models/expense_request_model.dart';

class ExpenseRequestRepositoryImpl implements ExpenseRequestRepository {
  final SupabaseClient _client;

  ExpenseRequestRepositoryImpl(this._client);

  @override
  Future<List<ExpenseRequest>> fetchRequests({
    String? branchId,
    String? userId,
    String? status,
  }) async {
    var query = _client
        .from('expense_requests')
        .select('*, profiles:employee_id(id, full_name_en, full_name_ar, email, role, manager_id)');

    if (branchId != null) {
      query = query.eq('branch_id', branchId);
    }

    if (userId != null) {
      query = query.eq('employee_id', userId);
    }

    if (status != null && status != 'all') {
      query = query.eq('status', status);
    }

    final data = await query.order('created_at', ascending: false);
    return (data as List).map((e) => ExpenseRequestModel.fromJson(e)).toList();
  }

  @override
  Future<ExpenseRequest> createRequest({
    required String subject,
    required String description,
    required String branchId,
    required String employeeId,
    required double amount,
    required String highestApprovalLevel,
  }) async {
    final data = await _client.from('expense_requests').insert({
      'subject': subject,
      'statement': description,
      'branch_id': branchId,
      'employee_id': employeeId,
      'amount': amount,
      'highest_approval_level': highestApprovalLevel,
      'status': 'pending',
    }).select().single();

    return ExpenseRequestModel.fromJson(data);
  }

  @override
  Future<ExpenseRequest> updateStatus({
    required String id,
    required String status,
  }) async {
    final data = await _client
        .from('expense_requests')
        .update({'status': status})
        .eq('id', id)
        .select()
        .single();

    return ExpenseRequestModel.fromJson(data);
  }
}
