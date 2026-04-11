import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:dar_alamirat_requests/core/localization/app_localizations.dart';
import 'package:dar_alamirat_requests/core/theme/app_theme.dart';
import '../../domain/entities/branch.dart';
import '../cubit/user_branch_cubit.dart';
import '../cubit/user_cubit.dart';
import '../../data/repositories/branch_repository.dart';
import '../../data/repositories/user_repository.dart';

class AssignEmployeePage extends StatelessWidget {
  final Branch branch;

  const AssignEmployeePage({super.key, required this.branch});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => UserBranchCubit(branchRepository: BranchRepository())..fetchAssignedUsers(branch.id),
        ),
        BlocProvider(
          create: (_) => UserCubit(UserRepository())..loadUsers(),
        ),
      ],
      child: AssignEmployeeView(branch: branch),
    );
  }
}

class AssignEmployeeView extends StatefulWidget {
  final Branch branch;

  const AssignEmployeeView({super.key, required this.branch});

  @override
  State<AssignEmployeeView> createState() => _AssignEmployeeViewState();
}

class _AssignEmployeeViewState extends State<AssignEmployeeView> {
  String? selectedUserId;
  String selectedAccessLevel = 'view';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text('${l10n.translate('assignEmployee')} - ${widget.branch.name}'),
        backgroundColor: AppTheme.primaryPink,
        foregroundColor: AppTheme.darkGray,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Assignment Form
            Card(
              elevation: 0,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.translate('selectEmployee'),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 12),
                    BlocBuilder<UserCubit, UserState>(
                      builder: (context, state) {
                        if (state is UserLoading) return const Center(child: CircularProgressIndicator());
                        if (state is UserLoaded) {
                          return DropdownButtonFormField<String>(
                            value: selectedUserId,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                            ),
                            items: state.users.map((u) {
                              return DropdownMenuItem(
                                value: u.id,
                                child: Text('${u.fullName} (${l10n.translate(u.role.name)})'),
                              );
                            }).toList(),
                            onChanged: (val) => setState(() => selectedUserId = val),
                            hint: Text(l10n.translate('selectUser')),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                    const SizedBox(height: 20),
                    Text(
                      l10n.translate('accessLevel'),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedAccessLevel,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                      items: [
                        DropdownMenuItem(value: 'view', child: Text(l10n.translate('view'))),
                        DropdownMenuItem(value: 'full', child: Text(l10n.translate('full'))),
                      ],
                      onChanged: (val) => setState(() => selectedAccessLevel = val!),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryPink,
                        foregroundColor: AppTheme.darkGray,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        minimumSize: const Size.fromHeight(50),
                      ),
                      onPressed: selectedUserId == null ? null : () {
                        context.read<UserBranchCubit>().assignUser(selectedUserId!, widget.branch.id, selectedAccessLevel);
                        setState(() => selectedUserId = null);
                      },
                      child: Text(
                        l10n.translate('assign'),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              l10n.translate('assignedEmployees'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: BlocBuilder<UserBranchCubit, UserBranchState>(
                builder: (context, state) {
                  if (state is UserBranchLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state is UserBranchLoaded) {
                    if (state.userBranches.isEmpty) {
                      return Center(
                        child: Text(
                          l10n.translate('noAssignedUsers'),
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                        ),
                      );
                    }
                    return ListView.builder(
                      itemCount: state.userBranches.length,
                      itemBuilder: (context, index) {
                        final ub = state.userBranches[index];
                        final isFull = ub.accessLevel == 'full';
                        return Card(
                          elevation: 0,
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.grey.shade200),
                          ),
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: isFull ? Colors.green.shade50 : Colors.blue.shade50,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  LucideIcons.user,
                                  color: isFull ? Colors.green.shade600 : Colors.blue.shade600,
                                  size: 20,
                                ),
                              ),
                              title: Text(
                                ub.profile?.fullName ?? l10n.translate('unknownUser'),
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text('${l10n.translate('role')}: ${ub.profile != null ? l10n.translate(ub.profile!.role.name) : '-'}'),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isFull ? Colors.green.shade50 : Colors.blue.shade50,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      l10n.translate(ub.accessLevel),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: isFull ? Colors.green.shade700 : Colors.blue.shade700,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: Icon(LucideIcons.trash2, color: Colors.red.shade400, size: 20),
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          title: Text(l10n.translate('delete')),
                                          content: Text(l10n.translate('confirmDelete')),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(ctx),
                                              child: Text(l10n.translate('cancel')),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                context.read<UserBranchCubit>().removeUser(ub.id, widget.branch.id);
                                                Navigator.pop(ctx);
                                              },
                                              child: Text(l10n.translate('delete'), style: const TextStyle(color: Colors.red)),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                    splashRadius: 24,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
