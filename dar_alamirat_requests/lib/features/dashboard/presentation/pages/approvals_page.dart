import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dar_alamirat_requests/core/localization/app_localizations.dart';
import 'package:dar_alamirat_requests/features/auth/domain/entities/profile.dart';
import 'package:dar_alamirat_requests/features/purchase_request/domain/entities/purchase_request.dart';
import 'package:dar_alamirat_requests/features/purchase_request/data/models/purchase_request_model.dart';
import 'package:dar_alamirat_requests/features/expense_request/domain/entities/expense_request.dart';
import 'package:dar_alamirat_requests/features/expense_request/data/models/expense_request_model.dart';

import 'package:dar_alamirat_requests/core/widgets/custom_widgets.dart';

class ApprovalsPage extends StatefulWidget {
  final Profile profile;
  final String? branchId;

  const ApprovalsPage({
    super.key,
    required this.profile,
    this.branchId,
  });

  @override
  State<ApprovalsPage> createState() => _ApprovalsPageState();
}

class _ApprovalsPageState extends State<ApprovalsPage> {
  bool _isLoading = true;
  List<dynamic> _pendingRequests = [];

  @override
  void initState() {
    super.initState();
    _fetchApprovals();
  }

  Future<void> _fetchApprovals() async {
    setState(() => _isLoading = true);
    try {
      final role = widget.profile.role;
      final userId = widget.profile.id;
      final branchId = widget.branchId;

      // 1. Fetch Purchase Requests
      var purchaseQuery = Supabase.instance.client
          .from('purchase_requests')
          .select('*, profiles:created_by(id, full_name, email, role, manager_id)');

      if (branchId != null) {
        purchaseQuery = purchaseQuery.eq('branch_id', branchId);
      }

      final purchaseData = await purchaseQuery.order('created_at', ascending: false);
      final allPurchases = (purchaseData as List).map((e) => PurchaseRequestModel.fromJson(e)).toList();

      // Filter pending purchases by role (Mirroring website logic)
      List<PurchaseRequest> pendingPurchases = [];
      if (role == UserRole.manager) {
        pendingPurchases = allPurchases.where((r) => r.status == 'pending' || r.status == 'rejected_by_manager').toList();
      } else if (role == UserRole.it_procurement) {
        pendingPurchases = allPurchases.where((r) => ['manager_approved', 'finance_approved', 'received_by_staff', 'rejected_by_it', 'rejected_by_it_purchase'].contains(r.status)).toList();
      } else if (role == UserRole.finance) {
        pendingPurchases = allPurchases.where((r) => r.status == 'it_approved' || r.status == 'rejected_by_finance').toList();
      } else if (role == UserRole.employee) {
        pendingPurchases = allPurchases.where((r) => r.createdBy == userId && (r.status == 'purchased' || r.status == 'rejected_by_staff')).toList();
      } else if (role == UserRole.admin) {
        pendingPurchases = allPurchases; // Admin sees all
      }

      // 2. Fetch Expense Requests
      var expenseQuery = Supabase.instance.client
          .from('expense_requests')
          .select('*, profiles:employee_id(id, full_name, email, role, manager_id)');

      if (branchId != null) {
        expenseQuery = expenseQuery.eq('branch_id', branchId);
      }

      final expenseData = await expenseQuery.order('created_at', ascending: false);
      final allExpenses = (expenseData as List).map((e) => ExpenseRequestModel.fromJson(e)).toList();

      // Filter pending expenses by role
      List<ExpenseRequest> pendingExpenses = [];
      if (role == UserRole.manager) {
        pendingExpenses = allExpenses.where((e) => e.status == 'pending' || e.status == 'rejected_by_manager').toList();
      } else if (role == UserRole.finance) {
        pendingExpenses = allExpenses.where((e) => ['finance', 'general_manager'].contains(e.highestApprovalLevel) && (e.status == 'manager_approved' || e.status == 'rejected_by_finance')).toList();
      } else if (role == UserRole.general_manager) {
        pendingExpenses = allExpenses.where((e) => e.highestApprovalLevel == 'general_manager' && (e.status == 'finance_approved' || e.status == 'rejected_by_gm')).toList();
      } else if (role == UserRole.accountant) {
        pendingExpenses = allExpenses.where((e) {
          if (['paid', 'completed', 'received'].contains(e.status)) return false;
          if (e.highestApprovalLevel == 'manager' && e.status == 'manager_approved') return true;
          if (e.highestApprovalLevel == 'finance' && e.status == 'finance_approved') return true;
          if (e.highestApprovalLevel == 'general_manager' && e.status == 'gm_approved') return true;
          return false;
        }).toList();
      } else if (role == UserRole.admin) {
        pendingExpenses = allExpenses;
      }

      setState(() {
        _pendingRequests = [...pendingPurchases, ...pendingExpenses];
        _pendingRequests.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching approvals: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: _fetchApprovals,
            child: _pendingRequests.isEmpty
                ? Center(child: Text(l10n.translate('noPendingApprovals')))
                : ListView.builder(
                    padding: const EdgeInsets.only(left: 16, right: 16, bottom: 120),
                    itemCount: _pendingRequests.length,
                    itemBuilder: (context, index) {
                      final item = _pendingRequests[index];
                      if (item is PurchaseRequest) {
                        return RequestCard(
                          subject: item.subject,
                          requester: item.profile?.fullName ?? 'Unknown',
                          date: item.createdAt,
                          amount: item.totalAmount,
                          status: item.status,
                          type: 'procure',
                          onTap: () {
                            // TODO: Navigate to approval details
                          },
                        );
                      } else {
                        final e = item as ExpenseRequest;
                        return RequestCard(
                          subject: e.subject,
                          requester: e.profile?.fullName ?? 'Unknown',
                          date: e.createdAt,
                          amount: e.amount,
                          status: e.status,
                          type: 'expense',
                          onTap: () {
                            // TODO: Navigate to approval details
                          },
                        );
                      }
                    },
                  ),
          ),
        ),
      ],
    );
  }
}
