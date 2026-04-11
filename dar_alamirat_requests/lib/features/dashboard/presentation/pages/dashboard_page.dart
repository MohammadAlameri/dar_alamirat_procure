import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../main.dart';
import '../../../../core/di/injection_container.dart';
import '../../../auth/domain/entities/profile.dart';
import '../../../purchase_request/presentation/pages/purchase_requests_page.dart';
import '../../../expense_request/presentation/pages/expense_requests_page.dart';
import '../../../purchase_request/presentation/pages/add_purchase_request_page.dart';
import '../../../expense_request/presentation/pages/add_expense_request_page.dart';
import '../cubit/dashboard_cubit.dart';
import '../cubit/dashboard_state.dart';
import 'approvals_page.dart';
import '../../../management/presentation/pages/branches_page.dart';
import '../../../management/presentation/pages/user_management_page.dart';
import '../../../management/presentation/pages/product_management_page.dart';
import '../../../reports/presentation/pages/reports_page.dart';
import '../../../auth/presentation/pages/profile_page.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<DashboardCubit>()..loadDashboard(),
      child: const DashboardView(),
    );
  }
}

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> with AutomaticKeepAliveClientMixin {
  int _selectedIndex = 0;
  int _refreshCounter = 0;

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l10n = AppLocalizations.of(context)!;

    return BlocBuilder<DashboardCubit, DashboardState>(
      builder: (context, state) {
        if (state is DashboardLoading) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (state is DashboardError) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(state.message, style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() => _refreshCounter++);
                      context.read<DashboardCubit>().loadDashboard();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        if (state is DashboardLoaded) {
          final isManager = state.profile.role == UserRole.manager ||
              state.profile.role == UserRole.generalManager ||
              state.profile.role == UserRole.finance ||
              state.profile.role == UserRole.itProcurement ||
              state.profile.role == UserRole.admin;

          return Scaffold(
            extendBody: true,
            appBar: AppBar(
              toolbarHeight: 70,
              titleSpacing: 24.0,
              title: Padding(
                padding: const EdgeInsets.only(top: 8.0, left: 6.0, right: 6.0),
                child: Text(_getTitle(l10n)),
              ),
              centerTitle: false,
              elevation: 1,
              backgroundColor: AppTheme.primaryPink,
              foregroundColor: AppTheme.darkGray,
              iconTheme: const IconThemeData(color: AppTheme.darkGray),
              actions: [
                if (state.userBranches.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0, right: 24.0, left: 16.0),
                    child: InkWell(
                      onTap: () => _showBranchDialog(context, state),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            state.selectedBranch == null 
                                ? l10n.translate('branch') 
                                : (l10n.isRTL && state.selectedBranch!.nameAr != null && state.selectedBranch!.nameAr!.isNotEmpty 
                                    ? state.selectedBranch!.nameAr! 
                                    : state.selectedBranch!.name),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          const SizedBox(width: 4),
                          const Icon(LucideIcons.chevronDown, size: 16),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            body: _getBody(state),
            floatingActionButton: _buildFAB(state),
            bottomNavigationBar: _buildFloatingBottomNavbar(l10n, isManager),
          );
        }

        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      },
    );
  }

  void _showBranchDialog(BuildContext context, DashboardLoaded state) {
    final dashboardCubit = context.read<DashboardCubit>();
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text(
            l10n.translate('branchManagement'),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: state.userBranches.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (_, index) {
                final branch = state.userBranches[index].branch;
                if (branch == null) return const SizedBox.shrink();
                final isSelected = state.selectedBranch?.id == branch.id;

                return ListTile(
                  leading: const Icon(LucideIcons.building, color: AppTheme.darkGray),
                  title: Text(
                    (l10n.isRTL && branch.nameAr != null && branch.nameAr!.isNotEmpty) ? branch.nameAr! : branch.name,
                    style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
                  ),
                  trailing: isSelected
                      ? const Icon(LucideIcons.check, color: AppTheme.primaryPink)
                      : null,
                  onTap: () {
                    Navigator.pop(dialogContext);
                    if (branch.id != state.selectedBranch?.id) {
                      dashboardCubit.changeBranch(branch);
                    }
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildFloatingBottomNavbar(AppLocalizations l10n, bool isManager) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      height: 70,
      decoration: BoxDecoration(
        color: AppTheme.primaryPink,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryPink.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavIcon(0, LucideIcons.layoutDashboard, l10n.translate('dashboard')),
          _buildNavIcon(1, LucideIcons.fileText, l10n.translate('myRequests')),
          _buildNavIcon(2, LucideIcons.banknote, l10n.translate('expenseRequests')),
          if (isManager) _buildNavIcon(3, LucideIcons.checkSquare, l10n.translate('approvals')),
          _buildNavIcon(99, LucideIcons.menu, l10n.translate('menu'), onTap: () => _showMenu(context)),
        ],
      ),
    );
  }

  Widget _buildNavIcon(int index, IconData icon, String label, {VoidCallback? onTap}) {
    final isSelected = _selectedIndex == index;
    return InkWell(
      onTap: onTap ?? () => setState(() => _selectedIndex = index),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: isSelected ? AppTheme.darkGray : Colors.black54,
            size: isSelected ? 24 : 22,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? AppTheme.darkGray : Colors.black54,
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  void _showMenu(BuildContext context) {
    final state = context.read<DashboardCubit>().state as DashboardLoaded;
    final l10n = AppLocalizations.of(context)!;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final isAdmin = state.profile.role == UserRole.admin;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bottomSheetContext) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                onTap: () {
                  setState(() => _selectedIndex = 10);
                  Navigator.pop(bottomSheetContext);
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: AppTheme.primaryPink,
                        child: Text(
                          state.profile.fullName.substring(0, 1).toUpperCase(),
                          style: const TextStyle(color: AppTheme.darkGray),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(state.profile.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text('${state.profile.email} • ${l10n.translate(state.profile.role.name)}', 
                                 style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ),
                      const Icon(LucideIcons.chevronRight, size: 16, color: Colors.grey),
                    ],
                  ),
                ),
              ),
              const Divider(height: 24),
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                children: [
                  if (isAdmin) ...[
                    _buildMenuItem(5, LucideIcons.barChart2, l10n.translate('reports')),
                    _buildMenuItem(6, LucideIcons.users, l10n.translate('userManagement')),
                    _buildMenuItem(7, LucideIcons.building, l10n.translate('branchManagement')),
                    _buildMenuItem(8, LucideIcons.package, l10n.translate('productManagement')),
                  ],
                  _buildMenuItem(
                    11,
                    LucideIcons.languages,
                    isAr ? 'English' : 'العربية',
                    onTap: () {
                      final newLocale = isAr ? const Locale('en') : const Locale('ar');
                      MyApp.setLocale(context, newLocale);
                      Navigator.pop(bottomSheetContext);
                    },
                  ),
                  _buildMenuItem(
                    12,
                    LucideIcons.logOut,
                    l10n.translate('signOut'),
                    color: Colors.red,
                    onTap: () async {
                      await Supabase.instance.client.auth.signOut();
                      if (context.mounted) {
                        context.go('/login');
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMenuItem(int index, IconData icon, String title, {VoidCallback? onTap, Color? color}) {
    return InkWell(
      onTap: onTap ?? () {
        setState(() => _selectedIndex = index);
        Navigator.pop(context);
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color ?? AppTheme.primaryPink, size: 32),
          const SizedBox(height: 6),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color ?? Colors.black87,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  String _getTitle(AppLocalizations l10n) {
    switch (_selectedIndex) {
      case 0: return l10n.translate('dashboard');
      case 1: return l10n.translate('purchaseRequests');
      case 2: return l10n.translate('expenseRequests');
      case 3: return l10n.translate('approvals');
      case 5: return l10n.translate('reports');
      case 6: return l10n.translate('userManagement');
      case 7: return l10n.translate('branchManagement');
      case 8: return l10n.translate('productManagement');
      case 10: return l10n.translate('profile');
      default: return l10n.translate('dashboard');
    }
  }

  Widget _getBody(DashboardLoaded state) {
    switch (_selectedIndex) {
      case 0: return _buildOverview(state);
      case 1: return PurchaseRequestsPage(key: ValueKey('pr_${state.selectedBranch?.id}_$_refreshCounter'), profile: state.profile, initialBranch: state.selectedBranch);
      case 2: return ExpenseRequestsPage(key: ValueKey('ex_${state.selectedBranch?.id}_$_refreshCounter'), profile: state.profile, initialBranch: state.selectedBranch);
      case 3: return ApprovalsPage(key: ValueKey('app_${state.selectedBranch?.id}_$_refreshCounter'), profile: state.profile, branchId: state.selectedBranch?.id);
      case 5: return const ReportsPage();
      case 6: return const UserManagementPage();
      case 7: return const BranchesPage();
      case 8: return const ProductManagementPage();
      case 10: return ProfilePage(profile: state.profile);
      default: return _buildOverview(state);
    }
  }

  Widget _buildOverview(DashboardLoaded state) {
    final l10n = AppLocalizations.of(context)!;
    return RefreshIndicator(
      onRefresh: () async {
        setState(() => _refreshCounter++);
        await context.read<DashboardCubit>().loadDashboard(branchId: state.selectedBranch?.id);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              _buildStatCard(l10n.translate('totalRequests'), state.totalCount.toString(), LucideIcons.fileText, Colors.blue),
              _buildStatCard(l10n.translate('pendingReview'), state.pendingCount.toString(), LucideIcons.clock, Colors.orange),
              _buildStatCard(l10n.translate('approved'), state.approvedCount.toString(), LucideIcons.checkCircle, Colors.green),
              _buildStatCard(l10n.translate('rejected'), state.rejectedCount.toString(), LucideIcons.xCircle, Colors.red),
            ],
          ),
          const SizedBox(height: 32),
          Text(
            l10n.translate('recentRequests'),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildRecentRequestsList(state, l10n),
          const SizedBox(height: 140),
        ],
      ),
    ),
    );
  }

  Widget _buildRecentRequestsList(DashboardLoaded state, AppLocalizations l10n) {
    final combined = [
      ...state.purchaseRequests.map((r) => _UnifiedRequest(r.id, r.subject, r.status, r.createdAt, r.totalAmount, 'procure', r.profile?.fullName ?? l10n.translate('unknown'))),
      ...state.expenseRequests.map((e) => _UnifiedRequest(e.id, e.subject, e.status, e.createdAt, e.amount, 'expense', e.profile?.fullName ?? l10n.translate('unknown'))),
    ];

    combined.sort((a, b) => b.date.compareTo(a.date));
    final recent = combined.take(10).toList();

    if (recent.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Center(child: Text(l10n.translate('noRequestsFound'), style: const TextStyle(color: Colors.grey))),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: recent.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final item = recent[index];
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            backgroundColor: (item.type == 'procure' ? Colors.blue : Colors.orange).withValues(alpha: 0.1),
            child: Icon(item.type == 'procure' ? LucideIcons.shoppingCart : LucideIcons.banknote, size: 16, color: item.type == 'procure' ? Colors.blue : Colors.orange),
          ),
          title: Text(item.subject, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          subtitle: Text('${item.requester} • ${DateFormat('MMM dd, yyyy').format(item.date)}', style: const TextStyle(fontSize: 12)),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${item.amount.toStringAsFixed(2)} ${l10n.translate('sar')}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 4),
              _buildStatusBadge(item.status, l10n),
            ],
          ),
          onTap: () async {
            await context.push('/request-details', extra: {'requestId': item.id, 'type': item.type, 'currentUser': state.profile});
            if (context.mounted) {
              setState(() => _refreshCounter++);
              context.read<DashboardCubit>().loadDashboard(branchId: state.selectedBranch?.id);
            }
          },
        );
      },
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey), overflow: TextOverflow.ellipsis),
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status, AppLocalizations l10n) {
    Color color = Colors.grey;
    String statusKey = status.toLowerCase();
    
    if (statusKey.contains('approved')) { color = Colors.green; statusKey = 'approved'; }
    else if (statusKey.contains('rejected')) { color = Colors.red; statusKey = 'rejected'; }
    else if (statusKey == 'pending') { color = Colors.orange; }
    else if (statusKey == 'completed') { color = Colors.blue; }
    else if (statusKey == 'purchased') { color = Colors.deepPurple; }
    else if (statusKey == 'paid') { color = Colors.green; }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withValues(alpha: 0.5))),
      child: Text(l10n.translate(statusKey).toUpperCase(), style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.bold)),
    );
  }

  Widget? _buildFAB(DashboardLoaded state) {
    if (![0, 1, 2].contains(_selectedIndex)) return null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: FloatingActionButton(
        onPressed: () {
          if (_selectedIndex == 1) {
            _navigateToAddPurchaseRequest(state);
          } else if (_selectedIndex == 2) {
            _navigateToAddExpenseRequest(state);
          } else {
            _showDashboardCreateOptions(state);
          }
        },
        backgroundColor: AppTheme.primaryPink,
        child: const Icon(LucideIcons.plus, color: AppTheme.darkGray),
      ),
    );
  }

  Future<void> _navigateToAddPurchaseRequest(DashboardLoaded state) async {
    if (state.selectedBranch == null) return;
    await Navigator.push(context, MaterialPageRoute(builder: (context) => AddPurchaseRequestPage(profile: state.profile, selectedBranch: state.selectedBranch)));
    if (mounted) {
      setState(() => _refreshCounter++);
      context.read<DashboardCubit>().loadDashboard(branchId: state.selectedBranch?.id);
    }
  }

  Future<void> _navigateToAddExpenseRequest(DashboardLoaded state) async {
    if (state.selectedBranch == null) return;
    await Navigator.push(context, MaterialPageRoute(builder: (context) => AddExpenseRequestPage(profile: state.profile, selectedBranch: state.selectedBranch)));
    if (mounted) {
      setState(() => _refreshCounter++);
      context.read<DashboardCubit>().loadDashboard(branchId: state.selectedBranch?.id);
    }
  }

  void _showDashboardCreateOptions(DashboardLoaded state) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildCreateOption(LucideIcons.shoppingCart, l10n.translate('addPurchaseRequest'), Colors.blue, () {
                _navigateToAddPurchaseRequest(state);
              }),
              _buildCreateOption(LucideIcons.banknote, l10n.translate('addExpenseRequest'), Colors.orange, () {
                _navigateToAddExpenseRequest(state);
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCreateOption(IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: () { Navigator.pop(context); onTap(); },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(radius: 24, backgroundColor: AppTheme.primaryPink.withValues(alpha: 0.3), child: Icon(icon, size: 24, color: AppTheme.darkGray)),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _UnifiedRequest {
  final String id;
  final String subject;
  final String status;
  final DateTime date;
  final double amount;
  final String type;
  final String requester;

  _UnifiedRequest(this.id, this.subject, this.status, this.date, this.amount, this.type, this.requester);
}
