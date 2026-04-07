import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../main.dart';
import '../../../auth/domain/entities/profile.dart';
import '../../../auth/data/models/profile_model.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 0;
  Profile? _profile;
  bool _isLoading = true;

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
        setState(() {
          _profile = ProfileModel.fromJson(data);
          _isLoading = false;
        });
      } catch (e) {
        debugPrint('Error loading profile: $e');
        setState(() => _isLoading = false);
      }
    }
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
              _buildStatCard(l10n.translate('totalRequests'), '0', LucideIcons.fileText, Colors.blue),
              _buildStatCard(l10n.translate('pendingReview'), '0', LucideIcons.clock, Colors.orange),
              _buildStatCard(l10n.translate('approved'), '0', LucideIcons.checkCircle, Colors.green),
              _buildStatCard(l10n.translate('rejected'), '0', LucideIcons.xCircle, Colors.red),
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
          const Card(
            child: Padding(
              padding: EdgeInsets.all(40.0),
              child: Center(child: Text('No requests found', style: TextStyle(color: Colors.grey))),
            ),
          ),
          const SizedBox(height: 100), // Space for floating navbar
        ],
      ),
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
}
