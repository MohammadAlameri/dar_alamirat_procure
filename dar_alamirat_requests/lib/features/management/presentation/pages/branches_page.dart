import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:dar_alamirat_requests/core/localization/app_localizations.dart';
import 'package:dar_alamirat_requests/core/theme/app_theme.dart';
import 'package:dar_alamirat_requests/features/management/domain/entities/branch.dart';
import 'package:dar_alamirat_requests/features/management/data/repositories/branch_repository.dart';
import '../cubits/branch_cubit.dart';

class BranchesPage extends StatelessWidget {
  const BranchesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => BranchCubit(BranchRepository())..loadBranches(),
      child: const BranchesView(),
    );
  }
}

class BranchesView extends StatelessWidget {
  const BranchesView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Stack(
      children: [
        BlocBuilder<BranchCubit, BranchState>(
          builder: (context, state) {
            if (state is BranchLoading) {
              return Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 120),
                      children: const [
                        BranchCardShimmer(),
                        BranchCardShimmer(),
                        BranchCardShimmer(),
                      ],
                    ),
                  ),
                ],
              );
            }

            if (state is BranchLoaded) {
              if (state.branches.isEmpty) {
                return Center(child: Text(l10n.translate('noBranchesFound')));
              }

              return Column(
                children: [
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () => context.read<BranchCubit>().loadBranches(),
                      child: ListView.builder(
                        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 120),
                        itemCount: state.branches.length,
                        itemBuilder: (context, index) {
                          final branch = state.branches[index];
                          return BranchCard(
                            branch: branch,
                            onToggleActive: (val) {
                              context.read<BranchCubit>().updateBranch(
                                    id: branch.id,
                                    isActive: val,
                                  );
                            },
                            onTap: () {
                              // TODO: Edit branch
                            },
                          );
                        },
                      ),
                    ),
                  ),
                ],
              );
            }

            if (state is BranchError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(LucideIcons.alertCircle, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(state.message),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => context.read<BranchCubit>().loadBranches(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            return const SizedBox.shrink();
          },
        ),
        Positioned(
          bottom: 100,
          right: 20,
          child: FloatingActionButton(
            onPressed: () {
              // TODO: Show create branch dialog
            },
            backgroundColor: AppTheme.primaryPink,
            child: const Icon(LucideIcons.plus, color: AppTheme.darkGray),
          ),
        ),
      ],
    );
  }
}

class BranchCard extends StatelessWidget {
  final Branch branch;
  final ValueChanged<bool> onToggleActive;
  final VoidCallback onTap;

  const BranchCard({
    super.key,
    required this.branch,
    required this.onToggleActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
          onChanged: onToggleActive,
        ),
        onTap: onTap,
      ),
    );
  }
}

class BranchCardShimmer extends StatelessWidget {
  const BranchCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: const ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: Colors.grey,
        ),
        title: SizedBox(
          height: 14,
          width: double.infinity,
          child: ColoredBox(color: Colors.grey),
        ),
        subtitle: SizedBox(
          height: 12,
          width: 100,
          child: ColoredBox(color: Colors.grey),
        ),
        trailing: SizedBox(
          height: 24,
          width: 40,
          child: ColoredBox(color: Colors.grey),
        ),
      ),
    );
  }
}

