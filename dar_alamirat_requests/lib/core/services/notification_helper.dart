import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'notification_service.dart';

/// Helper to determine who should receive notifications and send them.
class NotificationHelper {
  static final _client = Supabase.instance.client;

  /// Send notification when a new purchase request is created.
  /// Notifies managers of the branch.
  static Future<void> onPurchaseRequestCreated({
    required String requestId,
    required String subject,
    required String branchId,
    required String createdByName,
  }) async {
    try {
      debugPrint('[NotificationHelper] Notifying managers for new purchase request: $requestId');

      await NotificationService().sendNotificationToUsers(
        branchId: branchId,
        role: 'manager',
        title: 'طلب مشتريات جديد',
        body: '$createdByName قدم طلب مشتريات: $subject',
        requestId: requestId,
        requestType: 'procure',
      );
    } catch (e) {
      debugPrint('[NotificationHelper] Error sending purchase create notification: $e');
    }
  }

  /// Send notification when a new expense request is created.
  /// Notifies managers of the branch.
  static Future<void> onExpenseRequestCreated({
    required String requestId,
    required String subject,
    required String branchId,
    required String createdByName,
  }) async {
    try {
      debugPrint('[NotificationHelper] Notifying managers for new expense request: $requestId');

      await NotificationService().sendNotificationToUsers(
        branchId: branchId,
        role: 'manager',
        title: 'طلب مصروفات جديد',
        body: '$createdByName قدم طلب مصروفات: $subject',
        requestId: requestId,
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
      List<String>? targetUserIds;
      String? targetRole;
      List<String>? targetRoles;
      String title = '';
      String body = '';

      switch (newStatus) {
        case 'manager_approved':
          targetRole = 'it_procurement';
          title = 'طلب مشتريات بانتظار مراجعتك';
          body = 'تمت موافقة المدير على طلب: $subject';
          break;

        case 'it_approved':
          targetRole = 'finance';
          title = 'طلب مشتريات بانتظار موافقتك';
          body = 'تمت موافقة المشتريات على طلب: $subject';
          break;

        case 'finance_approved':
          targetRole = 'it_procurement';
          title = 'طلب مشتريات جاهز للشراء';
          body = 'تمت موافقة المالية على طلب: $subject';
          break;

        case 'purchased':
          if (createdBy != null) targetUserIds = [createdBy];
          title = 'تم شراء طلبك';
          body = 'تم شراء طلب المشتريات: $subject - يرجى الاستلام';
          break;

        case 'received_by_staff':
          targetRole = 'it_procurement';
          title = 'تم استلام المشتريات';
          body = 'تم استلام طلب: $subject من قبل الموظف';
          break;

        case 'rejected_by_manager':
          if (createdBy != null) targetUserIds = [createdBy];
          title = 'تم رفض طلبك';
          body = 'تم رفض طلب المشتريات: $subject من قبل المدير';
          break;

        case 'rejected_by_it':
          if (createdBy != null) targetUserIds = [createdBy];
          title = 'تم رفض طلبك';
          body = 'تم رفض طلب المشتريات: $subject من قبل المشتريات';
          break;

        case 'rejected_by_finance':
          targetRole = 'it_procurement';
          title = 'تم رفض طلب مشتريات';
          body = 'تم رفض طلب: $subject من قبل المالية';
          break;

        case 'rejected_by_staff':
          targetRole = 'it_procurement';
          title = 'رفض استلام';
          body = 'رفض الموظف استلام طلب: $subject';
          break;

        case 'completed':
          if (createdBy != null) targetUserIds = [createdBy];
          title = 'تم إكمال الطلب';
          body = 'تم إكمال طلب المشتريات: $subject';
          break;

        default:
          return;
      }

      debugPrint('[NotificationHelper] Sending purchase status update: $newStatus');

      await NotificationService().sendNotificationToUsers(
        userIds: targetUserIds,
        branchId: branchId,
        role: targetRole,
        roles: targetRoles,
        title: title,
        body: body,
        requestId: requestId,
        requestType: 'procure',
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
      List<String>? targetUserIds;
      String? targetRole;
      List<String>? targetRoles;
      String title = '';
      String body = '';

      switch (newStatus) {
        case 'manager_approved':
          if (highestApprovalLevel == 'manager') {
            targetRole = 'accountant';
            title = 'طلب مصروفات جاهز للدفع';
            body = 'تمت موافقة المدير على طلب: $subject';
          } else {
            targetRole = 'finance';
            title = 'طلب مصروفات بانتظار موافقتك';
            body = 'تمت موافقة المدير على طلب: $subject';
          }
          break;

        case 'finance_approved':
          if (highestApprovalLevel == 'finance') {
            targetRole = 'accountant';
            title = 'طلب مصروفات جاهز للدفع';
            body = 'تمت موافقة المالية على طلب: $subject';
          } else {
            targetRole = 'general_manager';
            title = 'طلب مصروفات بانتظار موافقتك';
            body = 'تمت موافقة المالية على طلب: $subject';
          }
          break;

        case 'gm_approved':
          targetRole = 'accountant';
          title = 'طلب مصروفات جاهز للدفع';
          body = 'تمت موافقة المدير العام على طلب: $subject';
          break;

        case 'paid':
          if (employeeId != null) targetUserIds = [employeeId];
          title = 'تم دفع المصروفات';
          body = 'تم دفع طلب المصروفات: $subject';
          break;

        case 'rejected_by_manager':
          if (employeeId != null) targetUserIds = [employeeId];
          title = 'تم رفض طلبك';
          body = 'تم رفض طلب المصروفات: $subject من قبل المدير';
          break;

        case 'rejected_by_finance':
          if (employeeId != null) targetUserIds = [employeeId];
          title = 'تم رفض طلبك';
          body = 'تم رفض طلب المصروفات: $subject من قبل المالية';
          break;

        case 'rejected_by_gm':
          if (employeeId != null) targetUserIds = [employeeId];
          title = 'تم رفض طلبك';
          body = 'تم رفض طلب المصروفات: $subject من قبل المدير العام';
          break;

        case 'completed':
          if (employeeId != null) targetUserIds = [employeeId];
          title = 'تم إكمال الطلب';
          body = 'تم إكمال طلب المصروفات: $subject';
          break;

        default:
          return;
      }

      debugPrint('[NotificationHelper] Sending expense status update: $newStatus');

      await NotificationService().sendNotificationToUsers(
        userIds: targetUserIds,
        branchId: branchId,
        role: targetRole,
        roles: targetRoles,
        title: title,
        body: body,
        requestId: requestId,
        requestType: 'expense',
      );
    } catch (e) {
      debugPrint('[NotificationHelper] Error sending expense status notification: $e');
    }
  }

}

