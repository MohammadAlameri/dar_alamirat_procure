import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/purchase_request.dart';
import '../models/purchase_request_model.dart';

class PurchaseRequestRepository {
  final _client = Supabase.instance.client;

  Future<List<PurchaseRequest>> fetchRequests({
    String? branchId,
    String? userId,
    String? status,
  }) async {
    var query = _client
        .from('purchase_requests')
        .select('*, profiles:created_by(id, full_name, email, role, manager_id)');

    if (branchId != null) {
      query = query.eq('branch_id', branchId);
    }

    if (userId != null) {
      query = query.eq('created_by', userId);
    }

    if (status != null && status != 'all') {
      query = query.eq('status', status);
    }

    final data = await query.order('created_at', ascending: false);
    return (data as List).map((e) => PurchaseRequestModel.fromJson(e)).toList();
  }

  Future<PurchaseRequest> createRequest({
    required String subject,
    required String description,
    required String branchId,
    required String createdBy,
    required double totalAmount,
    required List<Map<String, dynamic>> items,
  }) async {
    final data = await _client.from('purchase_requests').insert({
      'subject': subject,
      'description': description,
      'branch_id': branchId,
      'created_by': createdBy,
      'total_amount': totalAmount,
      'status': 'pending',
    }).select().single();

    final request = PurchaseRequestModel.fromJson(data);

    // Insert items
    for (var item in items) {
      await _client.from('purchase_request_items').insert({
        'request_id': request.id,
        'product_name': item['product_name'],
        'quantity': item['quantity'],
        'unit_price': item['unit_price'],
        'total_price': item['total_price'],
      });
    }

    return request;
  }

  Future<PurchaseRequest> updateStatus({
    required String id,
    required String status,
  }) async {
    final data = await _client
        .from('purchase_requests')
        .update({'status': status})
        .eq('id', id)
        .select()
        .single();

    return PurchaseRequestModel.fromJson(data);
  }
}
