import '../../domain/entities/purchase_request.dart';

abstract class PurchaseRequestRepository {
  Future<List<PurchaseRequest>> fetchRequests({
    String? branchId,
    String? userId,
    String? status,
  });

  Future<PurchaseRequest> createRequest({
    required String subject,
    required String description,
    required String branchId,
    required String createdBy,
    required double totalAmount,
    required List<Map<String, dynamic>> items,
  });

  Future<PurchaseRequest> updateStatus({
    required String id,
    required String status,
  });
}
