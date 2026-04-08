import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:dar_alamirat_requests/core/localization/app_localizations.dart';
import 'package:dar_alamirat_requests/core/theme/app_theme.dart';
import 'package:dar_alamirat_requests/features/auth/domain/entities/profile.dart';
import 'package:dar_alamirat_requests/features/auth/data/models/profile_model.dart';

class UserManagementPage extends StatefulWidget {
  const UserManagementPage({super.key});

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  bool _isLoading = true;
  List<Profile> _profiles = [];

  @override
  void initState() {
    super.initState();
    _fetchProfiles();
  }

  Future<void> _fetchProfiles() async {
    setState(() => _isLoading = true);
    try {
      final data = await Supabase.instance.client
          .from('profiles')
          .select('*')
          .neq('role', 'admin') // Usually exclude other admins
          .order('full_name');
      
      setState(() {
        _profiles = (data as List).map((e) => ProfileModel.fromJson(e)).toList();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching profiles: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return Stack(
      children: [
        Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: _fetchProfiles,
                child: _profiles.isEmpty
                    ? Center(child: Text(l10n.translate('noUsersFound')))
                    : ListView.builder(
                        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 120),
                        itemCount: _profiles.length,
                        itemBuilder: (context, index) {
                          final profile = _profiles[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: AppTheme.primaryPink.withOpacity(0.1),
                                child: Text(profile.fullName.substring(0, 1).toUpperCase(),
                                    style: const TextStyle(color: AppTheme.primaryPink, fontWeight: FontWeight.bold)),
                              ),
                              title: Text(profile.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('${profile.email}\nRole: ${profile.role.name.toUpperCase()}'),
                              isThreeLine: true,
                              trailing: IconButton(
                                icon: const Icon(LucideIcons.edit2, size: 18),
                                onPressed: () {
                                  // TODO: Edit user profile
                                },
                              ),
                              onTap: () {
                                // TODO: Show user details
                              },
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
        Positioned(
          bottom: 100,
          right: 20,
          child: FloatingActionButton(
            onPressed: () {},
            backgroundColor: AppTheme.primaryPink,
            child: const Icon(LucideIcons.userPlus, color: AppTheme.darkGray),
          ),
        ),
      ],
    );
  }
}
