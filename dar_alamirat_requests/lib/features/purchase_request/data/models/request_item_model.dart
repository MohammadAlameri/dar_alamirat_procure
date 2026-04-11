import '../../domain/entities/request_item.dart';
import '../../../auth/data/models/profile_model.dart';

class RequestItemModel extends RequestItem {
  RequestItemModel({
    required super.id,
    required super.requestId,
    super.categoryId,
    super.productId,
    required super.productName,
    super.specifications,
    super.unit,
    required super.quantity,
    required super.unitPrice,
    super.countryOfOrigin,
    super.warrantyPeriod,
  });

  factory RequestItemModel.fromJson(Map<String, dynamic> json) {
    return RequestItemModel(
      id: json['id'],
      requestId: json['request_id'],
      categoryId: json['category_id'],
      productId: json['product_id'],
      productName: json['product_name'] ?? '',
      specifications: json['specifications'],
      unit: json['unit'],
      quantity: (json['quantity'] ?? 0).toInt(),
      unitPrice: (json['unit_price'] ?? 0).toDouble(),
      countryOfOrigin: json['country_of_origin'],
      warrantyPeriod: json['warranty_period'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'request_id': requestId,
      'category_id': categoryId,
      'product_id': productId,
      'product_name': productName,
      'specifications': specifications,
      'unit': unit,
      'quantity': quantity,
      'unit_price': unitPrice,
      'country_of_origin': countryOfOrigin,
      'warranty_period': warrantyPeriod,
    };
  }
}

class ApprovalLogModel extends ApprovalLog {
  ApprovalLogModel({
    required super.id,
    required super.requestId,
    required super.userId,
    required super.action,
    super.comments,
    required super.createdAt,
    super.profile,
  });

  factory ApprovalLogModel.fromJson(Map<String, dynamic> json) {
    return ApprovalLogModel(
      id: json['id'],
      requestId: json['request_id'],
      userId: json['user_id'],
      action: json['action'] ?? '',
      comments: json['comments'],
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      profile: json['profiles'] != null ? ProfileModel.fromJson(json['profiles']) : null,
    );
  }
}
