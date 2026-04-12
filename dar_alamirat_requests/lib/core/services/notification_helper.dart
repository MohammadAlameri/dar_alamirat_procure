import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'notification_service.dart';

/// Helper to determine who should receive notifications and send them.
class NotificationHelper {
  static final _client = Supabase.instance.client;

  /// Send notification when a new purchase request is created.
  /// Notifies managers of the branch.
  static Future<void> onPurchaseRequestCreated({
    required String subject,
    required String branchId,
    required String createdByName,
  }) async {
    try {
      // Find managers for this branch
      final managerIds = await _getUsersByRole('manager', branchId);
      if (managerIds.isEmpty) return;

      await NotificationService().sendNotificationToUsers(
        userIds: managerIds,
        title: 'طلب مشتريات جديد',
        body: '$createdByName قدم طلب مشتريات: $subject',
        requestType: 'purchase',
      );
    } catch (e) {
      debugPrint('[NotificationHelper] Error sending purchase create notification: $e');
    }
  }

  /// Send notification when a new expense request is created.
  /// Notifies managers of the branch.
  static Future<void> onExpenseRequestCreated({
    required String subject,
    required String branchId,
    required String createdByName,
  }) async {
    try {
      // Find managers for this branch
      final managerIds = await _getUsersByRole('manager', branchId);
      if (managerIds.isEmpty) return;

      await NotificationService().sendNotificationToUsers(
        userIds: managerIds,
        title: 'طلب مصروفات جديد',
        body: '$createdByName قدم طلب مصروفات: $subject',
        requestType: 'expense',
      );
    } catch (e) {
      debugPrint('[NotificationHelper] Error sending expense create notification: $e');
    }
  }

  /// Send notification when a purchase request status changes.
  /// Notifies the appropriate next approver or the request creator.
  static Future<void> onPurchaseStatusChanged({
    required String requestId,
    required String newStatus,
    required String subject,
    required String branchId,
    required String? createdBy,
  }) async {
    try {
      final targetUserIds = <String>[];
      String title = '';
      String body = '';

      switch (newStatus) {
        case 'manager_approved':
          // Notify IT Procurement
          targetUserIds.addAll(await _getUsersByRole('it_procurement', branchId));
          title = 'طلب مشتريات بانتظار مراجعتك';
          body = 'تمت موافقة المدير على طلب: $subject';
          break;

        case 'it_approved':
          // Notify Finance
          targetUserIds.addAll(await _getUsersByRole('finance', branchId));
          title = 'طلب مشتريات بانتظار موافقتك';
          body = 'تمت موافقة المشتريات على طلب: $subject';
          break;

        case 'finance_approved':
          // Notify IT Procurement to purchase
          targetUserIds.addAll(await _getUsersByRole('it_procurement', branchId));
          title = 'طلب مشتريات جاهز للشراء';
          body = 'تمت موافقة المالية على طلب: $subject';
          break;

        case 'purchased':
          // Notify request creator to receive
          if (createdBy != null) targetUserIds.add(createdBy);
          title = 'تم شراء طلبك';
          body = 'تم شراء طلب المشتريات: $subject - يرجى الاستلام';
          break;

        case 'received_by_staff':
          // Notify IT Procurement to complete
          targetUserIds.addAll(await _getUsersByRole('it_procurement', branchId));
          title = 'تم استلام المشتريات';
          body = 'تم استلام طلب: $subject من قبل الموظف';
          break;

        case 'rejected_by_manager':
          if (createdBy != null) targetUserIds.add(createdBy);
          title = 'تم رفض طلبك';
          body = 'تم رفض طلب المشتريات: $subject من قبل المدير';
          break;

        case 'rejected_by_it':
          if (createdBy != null) targetUserIds.add(createdBy);
          title = 'تم رفض طلبك';
          body = 'تم رفض طلب المشتريات: $subject من قبل المشتريات';
          break;

        case 'rejected_by_finance':
          targetUserIds.addAll(await _getUsersByRole('it_procurement', branchId));
          title = 'تم رفض طلب مشتريات';
          body = 'تم رفض طلب: $subject من قبل المالية';
          break;

        case 'rejected_by_staff':
          targetUserIds.addAll(await _getUsersByRole('it_procurement', branchId));
          title = 'رفض استلام';
          body = 'رفض الموظف استلام طلب: $subject';
          break;

        case 'completed':
          if (createdBy != null) targetUserIds.add(createdBy);
          title = 'تم إكمال الطلب';
          body = 'تم إكمال طلب المشتريات: $subject';
          break;

        default:
          return;
      }

      if (targetUserIds.isEmpty) return;

      // Remove current user from notification targets
      final currentUserId = _client.auth.currentUser?.id;
      targetUserIds.removeWhere((id) => id == currentUserId);

      if (targetUserIds.isEmpty) return;

      await NotificationService().sendNotificationToUsers(
        userIds: targetUserIds,
        title: title,
        body: body,
        requestId: requestId,
        requestType: 'purchase',
      );
    } catch (e) {
      debugPrint('[NotificationHelper] Error sending purchase status notification: $e');
    }
  }

  /// Send notification when an expense request status changes.
  static Future<void> onExpenseStatusChanged({
    required String requestId,
    required String newStatus,
    required String subject,
    required String branchId,
    required String? employeeId,
    required String highestApprovalLevel,
  }) async {
    try {
      final targetUserIds = <String>[];
      String title = '';
      String body = '';

      switch (newStatus) {
        case 'manager_approved':
          if (highestApprovalLevel == 'manager') {
            // Notify accountant
            targetUserIds.addAll(await _getUsersByRole('accountant', branchId));
            title = 'طلب مصروفات جاهز للدفع';
            body = 'تمت موافقة المدير على طلب: $subject';
          } else {
            // Notify finance
            targetUserIds.addAll(await _getUsersByRole('finance', branchId));
            title = 'طلب مصروفات بانتظار موافقتك';
            body = 'تمت موافقة المدير على طلب: $subject';
          }
          break;

        case 'finance_approved':
          if (highestApprovalLevel == 'finance') {
            // Notify accountant
            targetUserIds.addAll(await _getUsersByRole('accountant', branchId));
            title = 'طلب مصروفات جاهز للدفع';
            body = 'تمت موافقة المالية على طلب: $subject';
          } else {
            // Notify general manager
            targetUserIds.addAll(await _getUsersByRole('general_manager', branchId));
            title = 'طلب مصروفات بانتظار موافقتك';
            body = 'تمت موافقة المالية على طلب: $subject';
          }
          break;

        case 'gm_approved':
          // Notify accountant
          targetUserIds.addAll(await _getUsersByRole('accountant', branchId));
          title = 'طلب مصروفات جاهز للدفع';
          body = 'تمت موافقة المدير العام على طلب: $subject';
          break;

        case 'paid':
          if (employeeId != null) targetUserIds.add(employeeId);
          title = 'تم دفع المصروفات';
          body = 'تم دفع طلب المصروفات: $subject';
          break;

        case 'rejected_by_manager':
          if (employeeId != null) targetUserIds.add(employeeId);
          title = 'تم رفض طلبك';
          body = 'تم رفض طلب المصروفات: $subject من قبل المدير';
          break;

        case 'rejected_by_finance':
          if (employeeId != null) targetUserIds.add(employeeId);
          title = 'تم رفض طلبك';
          body = 'تم رفض طلب المصروفات: $subject من قبل المالية';
          break;

        case 'rejected_by_gm':
          if (employeeId != null) targetUserIds.add(employeeId);
          title = 'تم رفض طلبك';
          body = 'تم رفض طلب المصروفات: $subject من قبل المدير العام';
          break;

        case 'completed':
          if (employeeId != null) targetUserIds.add(employeeId);
          title = 'تم إكمال الطلب';
          body = 'تم إكمال طلب المصروفات: $subject';
          break;

        default:
          return;
      }

      if (targetUserIds.isEmpty) return;

      // Remove current user from notification targets
      final currentUserId = _client.auth.currentUser?.id;
      targetUserIds.removeWhere((id) => id == currentUserId);

      if (targetUserIds.isEmpty) return;

      await NotificationService().sendNotificationToUsers(
        userIds: targetUserIds,
        title: title,
        body: body,
        requestId: requestId,
        requestType: 'expense',
      );
    } catch (e) {
      debugPrint('[NotificationHelper] Error sending expense status notification: $e');
    }
  }

  /// Get user IDs by role for a specific branch
  static Future<List<String>> _getUsersByRole(String role, String branchId) async {
    try {
      // Get users who have the specified role AND are assigned to the branch
      final response = await _client
          .from('user_branches')
          .select('user_id, profiles!inner(id, role)')
          .eq('branch_id', branchId)
          .eq('profiles.role', role);

      final userIds = (response as List)
          .map((e) => e['user_id'] as String)
          .toSet()
          .toList();

      debugPrint('[NotificationHelper] Found ${userIds.length} $role users for branch $branchId');
      return userIds;
    } catch (e) {
      debugPrint('[NotificationHelper] Error getting users by role: $e');
      return [];
    }
  }
}
