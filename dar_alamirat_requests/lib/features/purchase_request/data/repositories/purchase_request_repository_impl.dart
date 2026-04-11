import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/purchase_request.dart';
import '../../domain/repositories/purchase_request_repository.dart';
import '../models/purchase_request_model.dart';

class PurchaseRequestRepositoryImpl implements PurchaseRequestRepository {
  final SupabaseClient _client;

  PurchaseRequestRepositoryImpl(this._client);

  @override
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

  @override
  Future<PurchaseRequest> createRequest({
    required String subject,
    required String description,
    required String branchId,
    required String createdBy,
    required double totalAmount,
    required List<Map<String, dynamic>> items,
    String? employeeName,
    String? jobTitle,
  }) async {
    final data = await _client.from('purchase_requests').insert({
      'subject': subject,
      'justification': description,
      'branch_id': branchId,
      'created_by': createdBy,
      'total_amount': totalAmount,
      'status': 'pending',
      'requested_by_name': employeeName,
      'requested_by_title': jobTitle,
    }).select().single();

    final request = PurchaseRequestModel.fromJson(data);

    // Insert items in batch
    if (items.isNotEmpty) {
      final itemsToInsert = items.map((item) => {
        'request_id': request.id,
        'product_name': item['product_name'],
        'product_id': item['product_id'],
        'specifications': item['specifications'],
        'unit': item['unit'] ?? 'pcs',
        'quantity': (item['quantity'] as num).toInt(),
        'unit_price': (item['unit_price'] as num).toDouble(),
        'country_of_origin': item['country_of_origin'],
        'warranty_period': item['warranty_period'],
      }).toList();

      await _client.from('request_items').insert(itemsToInsert);
    }

    return request;
  }

  @override
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
