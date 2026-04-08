import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../main.dart';
import '../../../auth/domain/entities/profile.dart';
import '../../../auth/data/models/profile_model.dart';
import '../../../management/domain/entities/branch.dart';
import '../../../management/data/models/branch_model.dart';
import '../../../purchase_request/domain/entities/purchase_request.dart';
import '../../../purchase_request/data/models/purchase_request_model.dart';
import '../../../expense_request/domain/entities/expense_request.dart';
import '../../../expense_request/data/models/expense_request_model.dart';
import 'package:intl/intl.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 0;
  Profile? _profile;
  bool _isLoading = true;
  List<UserBranch> _userBranches = [];
  Branch? _selectedBranch;
  List<PurchaseRequest> _purchaseRequests = [];
  List<ExpenseRequest> _expenseRequests = [];
  
  // Stats
  int _totalCount = 0;
  int _pendingCount = 0;
  int _approvedCount = 0;
  int _rejectedCount = 0;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      try {
        final data = await Supabase.instance.client
            .from('profiles')
            .select()
            .eq('id', user.id)
            .single();
        final profile = ProfileModel.fromJson(data);
        
        setState(() {
          _profile = profile;
        });

        // Load branches
        await _loadUserBranches(user.id);
        
        // Initial data fetch
        await _fetchDashboardData();
      } catch (e) {
        debugPrint('Error loading profile: $e');
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadUserBranches(String userId) async {
    try {
      final data = await Supabase.instance.client
          .from('user_branches')
          .select('*, branches(*)')
          .eq('user_id', userId);
      
      final branches = (data as List).map((e) => UserBranchModel.fromJson(e)).toList();
      
      setState(() {
        _userBranches = branches;
        if (_userBranches.isNotEmpty) {
          // Try to find first "full" access branch, otherwise first branch
          final fullBranch = _userBranches.where((b) => b.accessLevel == 'full').firstOrNull;
          _selectedBranch = fullBranch?.branch ?? _userBranches.first.branch;
        }
      });
    } catch (e) {
      debugPrint('Error loading user branches: $e');
    }
  }

  Future<void> _fetchDashboardData() async {
    if (_profile == null) return;
    
    setState(() => _isLoading = true);
    
    try {
      final role = _profile!.role;
      final userId = _profile!.id;
      final branchId = _selectedBranch?.id;

      // 1. Fetch Purchase Requests
      var purchaseQuery = Supabase.instance.client
          .from('purchase_requests')
          .select('*, profiles:created_by(id, full_name, email, role, manager_id)');

      if (branchId != null) {
        purchaseQuery = purchaseQuery.eq('branch_id', branchId);
      }
      if (role == UserRole.employee) {
        purchaseQuery = purchaseQuery.eq('created_by', userId);
      }
      
      final purchaseData = await purchaseQuery.order('created_at', ascending: false);
      final purchases = (purchaseData as List).map((e) => PurchaseRequestModel.fromJson(e)).toList();

      // 2. Fetch Expense Requests
      var expenseQuery = Supabase.instance.client
          .from('expense_requests')
          .select('*, profiles:employee_id(id, full_name, email, role, manager_id)');

      if (branchId != null) {
        expenseQuery = expenseQuery.eq('branch_id', branchId);
      }
      if (role == UserRole.employee) {
        expenseQuery = expenseQuery.eq('employee_id', userId);
      }

      final expenseData = await expenseQuery.order('created_at', ascending: false);
      final expenses = (expenseData as List).map((e) => ExpenseRequestModel.fromJson(e)).toList();

      setState(() {
        _purchaseRequests = purchases;
        _expenseRequests = expenses;
        _calculateStats();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching dashboard data: $e');
      setState(() => _isLoading = false);
    }
  }

  void _calculateStats() {
    // Mirroring website logic
    _totalCount = _purchaseRequests.length + _expenseRequests.length;
    
    // Pending PR: 'pending', 'manager_approved', 'it_approved', 'finance_approved', 'purchased'
    final pendingPR = _purchaseRequests.where((r) => 
      ['pending', 'manager_approved', 'it_approved', 'finance_approved', 'purchased'].contains(r.status)
    ).length;
    
    // Pending Expense: not 'completed', 'paid', 'received' AND not 'rejected'
    final pendingExp = _expenseRequests.where((e) => 
      !['completed', 'paid', 'received'].contains(e.status) && !e.status.toLowerCase().contains('rejected')
    ).length;
    
    _pendingCount = pendingPR + pendingExp;
    
    // Approved
    _approvedCount = _purchaseRequests.where((r) => r.status == 'completed').length + 
                     _expenseRequests.where((e) => e.status == 'completed').length;
    
    // Rejected
    _rejectedCount = _purchaseRequests.where((r) => r.status.toLowerCase().contains('rejected')).length + 
                     _expenseRequests.where((e) => e.status.toLowerCase().contains('rejected')).length;
  }

  void _showMenu() {
    final l10n = AppLocalizations.of(context)!;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final role = _profile?.role ?? UserRole.employee;
    final isAdmin = role == UserRole.admin;
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // User Header
              Row(
                children: [
                  CircleAvatar(backgroundColor: AppTheme.primaryBlue, child: Text(_profile?.fullName.substring(0, 1).toUpperCase() ?? 'U', style: const TextStyle(color: Colors.white))),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_profile?.fullName ?? 'User', style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(_profile?.email ?? '', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ],
              ),
              const Divider(height: 32),
              
              // Menu Grid
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
                  _buildMenuItem(11, LucideIcons.languages, isAr ? 'English' : 'العربية', onTap: () {
                    final newLocale = isAr ? const Locale('en') : const Locale('ar');
                    MyApp.setLocale(context, newLocale);
                    Navigator.pop(context);
                  }),
                  _buildMenuItem(12, LucideIcons.logOut, l10n.translate('signOut'), color: Colors.red, onTap: () async {
                    await Supabase.instance.client.auth.signOut();
                    if (mounted) context.go('/login');
                  }),
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
          Icon(icon, color: color ?? AppTheme.primaryBlue, size: 24),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(fontSize: 10, color: color ?? Colors.black87), textAlign: TextAlign.center, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    
    final l10n = AppLocalizations.of(context)!;
    final role = _profile?.role ?? UserRole.employee;
    final isManager = role == UserRole.manager || role == UserRole.general_manager || role == UserRole.finance || role == UserRole.it_procurement || role == UserRole.admin;

    return Scaffold(
      extendBody: true, // Crucial for floating navbar
      appBar: AppBar(
        title: Text(_getTitle(l10n)),
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        actions: [
          if (_userBranches.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: DropdownButton<Branch>(
                value: _selectedBranch,
                underline: const SizedBox(),
                icon: const Icon(LucideIcons.building, size: 18),
                items: _userBranches.map((ub) {
                  return DropdownMenuItem<Branch>(
                    value: ub.branch,
                    child: Text(ub.branch?.name ?? 'Branch', style: const TextStyle(fontSize: 14)),
                  );
                }).toList(),
                onChanged: (Branch? newValue) {
                  if (newValue != null && newValue.id != _selectedBranch?.id) {
                    setState(() {
                      _selectedBranch = newValue;
                    });
                    _fetchDashboardData();
                  }
                },
              ),
            ),
        ],
      ),
      body: _getBody(),
      bottomNavigationBar: _buildFloatingBottomNavbar(l10n, isManager),
    );
  }

  Widget _buildFloatingBottomNavbar(AppLocalizations l10n, bool isManager) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      height: 70,
      decoration: BoxDecoration(
        color: AppTheme.primaryBlue,
        borderRadius: BorderRadius.circular(35),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withOpacity(0.3),
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
          
          // Menu Toggle
          _buildNavIcon(99, LucideIcons.menu, l10n.translate('menu'), onTap: _showMenu),
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
            color: isSelected ? Colors.white : Colors.white54,
            size: isSelected ? 24 : 22,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white54,
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  String _getTitle(AppLocalizations l10n) {
    switch (_selectedIndex) {
      case 0: return l10n.translate('dashboard');
      case 1: return l10n.translate('myRequests');
      case 2: return l10n.translate('expenseRequests');
      case 3: return l10n.translate('pendingApprovals');
      case 5: return l10n.translate('reports');
      case 6: return l10n.translate('userManagement');
      case 7: return l10n.translate('branchManagement');
      case 8: return l10n.translate('productManagement');
      default: return l10n.translate('dashboard');
    }
  }

  Widget _getBody() {
    switch (_selectedIndex) {
      case 0: return _buildOverview();
      default: return Center(child: Text(_getTitle(AppLocalizations.of(context)!)));
    }
  }

  Widget _buildOverview() {
    final l10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.translate('dashboardOverview'), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.4,
            children: [
              _buildStatCard(l10n.translate('totalRequests'), _totalCount.toString(), LucideIcons.fileText, Colors.blue),
              _buildStatCard(l10n.translate('pendingReview'), _pendingCount.toString(), LucideIcons.clock, Colors.orange),
              _buildStatCard(l10n.translate('approved'), _approvedCount.toString(), LucideIcons.checkCircle, Colors.green),
              _buildStatCard(l10n.translate('rejected'), _rejectedCount.toString(), LucideIcons.xCircle, Colors.red),
            ],
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l10n.translate('recentRequests'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              IconButton(onPressed: () {}, icon: const Icon(LucideIcons.plusCircle, color: AppTheme.primaryBlue)),
            ],
          ),
          const SizedBox(height: 16),
          _buildRecentRequestsList(),
          const SizedBox(height: 100), // Space for floating navbar
        ],
      ),
    );
  }

  Widget _buildRecentRequestsList() {
    final combined = [..._purchaseRequests.map((r) => _UnifiedRequest(r.id, r.subject, r.status, r.createdAt, r.totalAmount, 'procure', r.profile?.fullName ?? 'Unknown')), 
                      ..._expenseRequests.map((e) => _UnifiedRequest(e.id, e.subject, e.status, e.createdAt, e.amount, 'expense', e.profile?.fullName ?? 'Unknown'))];
    
    combined.sort((a, b) => b.date.compareTo(a.date));
    final recent = combined.take(10).toList();

    if (recent.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(40.0),
          child: Center(child: Text('No requests found', style: TextStyle(color: Colors.grey))),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: recent.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final item = recent[index];
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            backgroundColor: item.type == 'procure' ? Colors.blue.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
            child: Icon(
              item.type == 'procure' ? LucideIcons.shoppingCart : LucideIcons.banknote,
              size: 16,
              color: item.type == 'procure' ? Colors.blue : Colors.orange,
            ),
          ),
          title: Text(item.subject, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          subtitle: Text('${item.requester} • ${DateFormat('MMM dd, yyyy').format(item.date)}', style: const TextStyle(fontSize: 12)),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${item.amount.toStringAsFixed(2)} AED', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 4),
              _buildStatusBadge(item.status),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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

  Widget _buildStatusBadge(String status) {
    Color color = Colors.grey;
    if (status.contains('approved')) color = Colors.green;
    else if (status.contains('rejected')) color = Colors.red;
    else if (status == 'pending') color = Colors.orange;
    else if (status == 'completed') color = Colors.blue;
    else if (status == 'purchased') color = Colors.deepPurple;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        status.replaceAll('_', ' ').toUpperCase(),
        style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.bold),
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
