import '../../../auth/domain/entities/profile.dart';

class RequestItem {
  final String id;
  final String requestId;
  final String? categoryId;
  final String? productId;
  final String productName;
  final String? specifications;
  final String? unit;
  final int quantity;
  final double unitPrice;
  final String? countryOfOrigin;
  final String? warrantyPeriod;
  final String? brandModel;

  RequestItem({
    required this.id,
    required this.requestId,
    this.categoryId,
    this.productId,
    required this.productName,
    this.specifications,
    this.unit,
    required this.quantity,
    required this.unitPrice,
    this.countryOfOrigin,
    this.warrantyPeriod,
    this.brandModel,
  });

  double get total => quantity * unitPrice;
}

class ApprovalLog {
  final String id;
  final String requestId;
  final String userId;
  final String action;
  final String? comments;
  final DateTime createdAt;
  final Profile? profile;

  ApprovalLog({
    required this.id,
    required this.requestId,
    required this.userId,
    required this.action,
    this.comments,
    required this.createdAt,
    this.profile,
  });
}
