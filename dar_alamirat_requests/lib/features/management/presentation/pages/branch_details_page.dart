import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:dar_alamirat_requests/core/localization/app_localizations.dart';
import 'package:dar_alamirat_requests/core/theme/app_theme.dart';
import 'package:dar_alamirat_requests/features/management/domain/entities/branch.dart';
import 'package:dar_alamirat_requests/features/management/presentation/cubit/branch_cubit.dart';
import 'package:dar_alamirat_requests/features/management/presentation/pages/add_branch_page.dart';
import 'package:dar_alamirat_requests/features/management/presentation/pages/assign_employee_page.dart';

class BranchDetailsPage extends StatelessWidget {
  final Branch branch;

  const BranchDetailsPage({super.key, required this.branch});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.translate('branchDetails')),
        backgroundColor: AppTheme.primaryPink,
        foregroundColor: AppTheme.darkGray,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Branch details header
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 40,
                      backgroundColor: AppTheme.primaryPink,
                      child: Icon(LucideIcons.building, size: 40, color: AppTheme.darkGray),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      branch.name,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${l10n.translate('code')}: ${branch.code ?? 'N/A'}',
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          l10n.translate('status'),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        Switch(
                          value: branch.isActive,
                          onChanged: (val) {
                            context.read<BranchCubit>().updateBranch(
                              id: branch.id,
                              isActive: val,
                            );
                            Navigator.pop(context); // Pop back after change, or pass state down. Simple pop is easier for now.
                          },
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Buttons
            ElevatedButton.icon(
              onPressed: () {
                final cubit = context.read<BranchCubit>();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BlocProvider.value(
                      value: cubit,
                      child: AddBranchPage(branchToEdit: branch),
                    ),
                  ),
                );
              },
              icon: Icon(LucideIcons.edit, color: Colors.blue.shade700),
              label: Text(l10n.translate('edit'), style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade50,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.blue.shade200),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 16),

            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AssignEmployeePage(branch: branch)),
                );
              },
              icon: Icon(LucideIcons.users, color: Colors.indigo.shade700),
              label: Text(l10n.translate('assignEmployee'), style: TextStyle(color: Colors.indigo.shade700, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo.shade50,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.indigo.shade200),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 16),

            ElevatedButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text(l10n.translate('deleteBranch')),
                    content: Text(l10n.translate('confirmDeleteBranch')),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text(l10n.translate('cancel')),
                      ),
                      TextButton(
                        onPressed: () {
                          // Call delete method on cubit. Note: delete might be unsupported or requires disabling.
                          Navigator.pop(ctx); // Close dialog
                          Navigator.pop(context); // Close details page
                        },
                        child: Text(l10n.translate('delete'), style: const TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
              },
              icon: Icon(LucideIcons.trash2, color: Colors.red.shade700),
              label: Text(l10n.translate('delete'), style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade50,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.red.shade200),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),

          ],
        ),
      ),
    );
  }
}
