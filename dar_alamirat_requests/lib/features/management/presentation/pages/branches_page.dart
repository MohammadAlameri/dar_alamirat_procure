import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:dar_alamirat_requests/core/localization/app_localizations.dart';
import 'package:dar_alamirat_requests/core/theme/app_theme.dart';
import 'package:dar_alamirat_requests/features/management/domain/entities/branch.dart';
import 'package:dar_alamirat_requests/features/management/data/models/branch_model.dart';

class BranchesPage extends StatefulWidget {
  const BranchesPage({super.key});

  @override
  State<BranchesPage> createState() => _BranchesPageState();
}

class _BranchesPageState extends State<BranchesPage> {
  bool _isLoading = true;
  List<Branch> _branches = [];

  @override
  void initState() {
    super.initState();
    _fetchBranches();
  }

  Future<void> _fetchBranches() async {
    setState(() => _isLoading = true);
    try {
      final data = await Supabase.instance.client
          .from('branches')
          .select('*')
          .order('name');
      
      setState(() {
        _branches = (data as List).map((e) => BranchModel.fromJson(e)).toList();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching branches: $e');
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
                onRefresh: _fetchBranches,
                child: _branches.isEmpty
                    ? Center(child: Text(l10n.translate('noBranchesFound')))
                    : ListView.builder(
                        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 120),
                        itemCount: _branches.length,
                        itemBuilder: (context, index) {
                          final branch = _branches[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              leading: const CircleAvatar(
                                backgroundColor: AppTheme.primaryPink,
                                child: Icon(LucideIcons.building, color: AppTheme.darkGray, size: 20),
                              ),
                              title: Text(branch.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text(branch.code ?? 'No Code'),
                              trailing: Switch(
                                value: branch.isActive,
                                onChanged: (val) {
                                  // TODO: Update branch status
                                },
                              ),
                              onTap: () {
                                // TODO: Edit branch
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
            child: const Icon(LucideIcons.plus, color: AppTheme.darkGray),
          ),
        ),
      ],
    );
  }
}
