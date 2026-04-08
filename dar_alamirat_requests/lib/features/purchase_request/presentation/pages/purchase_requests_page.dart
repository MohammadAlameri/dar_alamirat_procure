import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dar_alamirat_requests/core/localization/app_localizations.dart';
import 'package:dar_alamirat_requests/features/auth/domain/entities/profile.dart';
import 'package:dar_alamirat_requests/features/management/domain/entities/branch.dart';
import 'package:dar_alamirat_requests/features/management/data/models/branch_model.dart';
import 'package:dar_alamirat_requests/features/purchase_request/domain/entities/purchase_request.dart';
import 'package:dar_alamirat_requests/features/purchase_request/data/models/purchase_request_model.dart';

import 'package:dar_alamirat_requests/core/widgets/custom_widgets.dart';
import 'package:dar_alamirat_requests/core/theme/app_theme.dart';

class PurchaseRequestsPage extends StatefulWidget {
  final Profile profile;
  final Branch? initialBranch;

  const PurchaseRequestsPage({
    super.key,
    required this.profile,
    this.initialBranch,
  });

  @override
  State<PurchaseRequestsPage> createState() => PurchaseRequestsPageState();
}

class PurchaseRequestsPageState extends State<PurchaseRequestsPage> {
  bool _isLoading = true;
  List<PurchaseRequest> _requests = [];
  Branch? _selectedBranch;
  String _selectedStatus = 'all';
  List<Branch> _availableBranches = [];

  @override
  void initState() {
    super.initState();
    _selectedBranch = widget.initialBranch;
    _loadInitialData();
  }

  @override
  void didUpdateWidget(PurchaseRequestsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialBranch?.id != oldWidget.initialBranch?.id) {
      setState(() {
        _selectedBranch = widget.initialBranch;
      });
      _fetchRequests();
    }
  }

  Future<void> _loadInitialData() async {
    await _loadBranches();
    await _fetchRequests();
  }

  Future<void> _loadBranches() async {
    try {
      final data = await Supabase.instance.client
          .from('user_branches')
          .select('*, branches(*)')
          .eq('user_id', widget.profile.id);
      
      final userBranches = (data as List).map((e) => UserBranchModel.fromJson(e)).toList();
      setState(() {
        _availableBranches = userBranches.map((ub) => ub.branch!).toList();
        if (_selectedBranch == null && _availableBranches.isNotEmpty) {
          _selectedBranch = _availableBranches.first;
        }
      });
    } catch (e) {
      debugPrint('Error loading branches: $e');
    }
  }

  Future<void> _fetchRequests() async {
    setState(() => _isLoading = true);
    try {
      final role = widget.profile.role;
      final userId = widget.profile.id;
      final branchId = _selectedBranch?.id;

      var query = Supabase.instance.client
          .from('purchase_requests')
          .select('*, profiles:created_by(id, full_name, email, role, manager_id)');

      if (branchId != null) {
        query = query.eq('branch_id', branchId);
      }

      // Filter by role
      if (role == UserRole.employee) {
        query = query.eq('created_by', userId);
      }
      
      if (_selectedStatus != 'all') {
        query = query.eq('status', _selectedStatus);
      }

      final data = await query.order('created_at', ascending: false);
      setState(() {
        _requests = (data as List).map((e) => PurchaseRequestModel.fromJson(e)).toList();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching requests: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFilterList(l10n),
        Expanded(
          child: _isLoading
              ? ListView.builder(
                  padding: const EdgeInsets.only(left: 16, right: 16, bottom: 120),
                  itemCount: 6,
                  itemBuilder: (context, index) => const RequestCardShimmer(),
                )
              : RefreshIndicator(
                  onRefresh: _fetchRequests,
                  child: _requests.isEmpty
                      ? ListView(
                          padding: const EdgeInsets.only(bottom: 120),
                          children: [
                            SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                            Center(child: Text(l10n.translate('noRequestsFound'))),
                          ],
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.only(left: 16, right: 16, bottom: 120),
                          itemCount: _requests.length,
                          itemBuilder: (context, index) {
                            final request = _requests[index];
                            return RequestCard(
                              subject: request.subject,
                              requester: request.profile?.fullName ?? 'Unknown',
                              date: request.createdAt,
                              amount: request.totalAmount,
                              status: request.status,
                              type: 'procure',
                              onTap: () {
                                // TODO: Navigate to details
                              },
                            );
                          },
                        ),
                ),
        ),
      ],
    );
  }

  Widget _buildFilterList(AppLocalizations l10n) {
    final statuses = ['all', 'pending', 'manager_approved', 'completed', 'rejected'];
    return Container(
      height: 48,
      margin: const EdgeInsets.only(bottom: 12, top: 4),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: statuses.length,
        separatorBuilder: (context, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final status = statuses[index];
          final isSelected = _selectedStatus == status;
          return ChoiceChip(
            label: Text(
              _getStatusLabel(status, l10n),
              style: TextStyle(
                color: isSelected ? Colors.white : AppTheme.darkGray,
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
            selected: isSelected,
            showCheckmark: false,
            selectedColor: AppTheme.primaryPink,
            backgroundColor: Colors.white,
            side: BorderSide(color: isSelected ? AppTheme.primaryPink : Colors.grey.shade300),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            onSelected: (selected) {
              if (selected) {
                setState(() {
                  _selectedStatus = status;
                });
                _fetchRequests();
              }
            },
          );
        },
      ),
    );
  }

  String _getStatusLabel(String status, AppLocalizations l10n) {
    // Attempting to use localized strings where possible, or fallback manually
    switch (status) {
      case 'all': return 'All';
      case 'pending': return 'Pending';
      case 'manager_approved': return 'Manager Approved';
      case 'completed': return 'Completed';
      case 'rejected': return 'Rejected';
      default: return status.replaceAll('_', ' ').replaceFirst(status[0], status[0].toUpperCase());
    }
  }
}
