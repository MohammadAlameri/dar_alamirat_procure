import '../../../auth/domain/entities/profile.dart';
import 'request_item.dart';

class PurchaseRequest {
  final String id;
  final String subject;
  final String? justification;
  final String status;
  final double totalAmount;
  final String? createdBy;
  final DateTime createdAt;
  final String? branchId;
  final Profile? profile; 
  final List<RequestItem> items;
  final List<ApprovalLog> logs;
  final String? suggestedSuppliers;
  final String? budgetLineItem;
  final String? commitmentNumber;
  final String? amountInWords;
  final bool? budgetStatus;
  final String? staffAcceptanceStatus;
  final String? staffRejectionReason;
  final DateTime? staffReceivingDate;

  PurchaseRequest({
    required this.id,
    required this.subject,
    this.justification,
    required this.status,
    this.totalAmount = 0.0,
    this.createdBy,
    required this.createdAt,
    this.branchId,
    this.profile,
    this.items = const [],
    this.logs = const [],
    this.suggestedSuppliers,
    this.budgetLineItem,
    this.commitmentNumber,
    this.amountInWords,
    this.budgetStatus,
    this.staffAcceptanceStatus,
    this.staffRejectionReason,
    this.staffReceivingDate,
  });

  String get type => 'procure';

  PurchaseRequest copyWith({
    String? status,
    double? totalAmount,
    String? suggestedSuppliers,
    String? budgetLineItem,
    String? commitmentNumber,
    String? amountInWords,
    bool? budgetStatus,
    String? staffAcceptanceStatus,
    String? staffRejectionReason,
    DateTime? staffReceivingDate,
    List<RequestItem>? items,
    List<ApprovalLog>? logs,
  }) {
    return PurchaseRequest(
      id: id,
      subject: subject,
      justification: justification,
      status: status ?? this.status,
      totalAmount: totalAmount ?? this.totalAmount,
      createdBy: createdBy,
      createdAt: createdAt,
      branchId: branchId,
      profile: profile,
      items: items ?? this.items,
      logs: logs ?? this.logs,
      suggestedSuppliers: suggestedSuppliers ?? this.suggestedSuppliers,
      budgetLineItem: budgetLineItem ?? this.budgetLineItem,
      commitmentNumber: commitmentNumber ?? this.commitmentNumber,
      amountInWords: amountInWords ?? this.amountInWords,
      budgetStatus: budgetStatus ?? this.budgetStatus,
      staffAcceptanceStatus: staffAcceptanceStatus ?? this.staffAcceptanceStatus,
      staffRejectionReason: staffRejectionReason ?? this.staffRejectionReason,
      staffReceivingDate: staffReceivingDate ?? this.staffReceivingDate,
    );
  }
}
