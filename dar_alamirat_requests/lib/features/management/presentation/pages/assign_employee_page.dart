import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:dar_alamirat_requests/core/localization/app_localizations.dart';
import 'package:dar_alamirat_requests/core/theme/app_theme.dart';
import 'package:dar_alamirat_requests/features/management/domain/entities/structure_node.dart';
import 'package:dar_alamirat_requests/features/management/presentation/cubit/company_structure_cubit.dart';
import 'package:dar_alamirat_requests/features/management/presentation/cubit/user_assignment_cubit.dart';
import 'package:dar_alamirat_requests/features/management/presentation/cubit/user_cubit.dart';
import 'package:dar_alamirat_requests/features/management/data/repositories/company_structure_repository.dart';
import 'package:dar_alamirat_requests/features/management/data/repositories/user_repository.dart';
import 'package:dar_alamirat_requests/core/di/injection_container.dart';

class AssignEmployeePage extends StatelessWidget {
  final StructureNode node;
  final StructureLevel level;

  const AssignEmployeePage({
    super.key,
    required this.node,
    required this.level,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => sl<UserAssignmentCubit>()
            ..fetchAssignedUsers(
              departmentId: level == StructureLevel.department ? node.id : null,
              branchId: level == StructureLevel.branch ? node.id : null,
              divisionId: level == StructureLevel.division ? node.id : null,
              unitId: level == StructureLevel.unit ? node.id : null,
            ),
        ),
        BlocProvider(
          create: (_) => sl<UserCubit>()..loadUsers(),
        ),
      ],
      child: AssignEmployeeView(node: node, level: level),
    );
  }
}

class AssignEmployeeView extends StatefulWidget {
  final StructureNode node;
  final StructureLevel level;

  const AssignEmployeeView({
    super.key,
    required this.node,
    required this.level,
  });

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
        title: Text('${l10n.translate('assignEmployee') ?? 'Assign'} - ${widget.node.displayName}'),
        backgroundColor: AppTheme.primaryPink,
        foregroundColor: AppTheme.darkGray,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Form
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    BlocBuilder<UserCubit, UserState>(
                      builder: (context, state) {
                        if (state is UserLoaded) {
                          return DropdownButtonFormField<String>(
                            value: selectedUserId,
                            decoration: InputDecoration(
                              labelText: l10n.translate('selectEmployee') ?? 'Select Employee',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            items: state.users.map((u) => DropdownMenuItem(
                              value: u.id,
                              child: Text(u.fullName),
                            )).toList(),
                            onChanged: (val) => setState(() => selectedUserId = val),
                          );
                        }
                        return const CircularProgressIndicator();
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedAccessLevel,
                      decoration: InputDecoration(
                        labelText: l10n.translate('accessLevel') ?? 'Access Level',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'view', child: Text('View')),
                        DropdownMenuItem(value: 'full', child: Text('Full')),
                      ],
                      onChanged: (val) => setState(() => selectedAccessLevel = val!),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: selectedUserId == null ? null : () => _assign(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryPink,
                        minimumSize: const Size.fromHeight(50),
                      ),
                      child: Text(l10n.translate('assign') ?? 'Assign'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.translate('assignedEmployees') ?? 'Assigned Employees',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: BlocBuilder<UserAssignmentCubit, UserAssignmentState>(
                builder: (context, state) {
                  if (state is UserAssignmentLoaded) {
                    return ListView.builder(
                      itemCount: state.assignments.length,
                      itemBuilder: (context, index) {
                        final assignment = state.assignments[index];
                        return ListTile(
                          title: Text(assignment.profile?.fullName ?? 'Unknown'),
                          subtitle: Text(assignment.accessLevel),
                          trailing: IconButton(
                            icon: const Icon(LucideIcons.trash2, color: Colors.red),
                            onPressed: () => _remove(context, assignment.id),
                          ),
                        );
                      },
                    );
                  }
                  return const Center(child: CircularProgressIndicator());
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _assign(BuildContext context) {
    context.read<UserAssignmentCubit>().assignUser(
      userId: selectedUserId!,
      departmentId: widget.level == StructureLevel.department ? widget.node.id : null,
      branchId: widget.level == StructureLevel.branch ? widget.node.id : null,
      divisionId: widget.level == StructureLevel.division ? widget.node.id : null,
      unitId: widget.level == StructureLevel.unit ? widget.node.id : null,
      accessLevel: selectedAccessLevel,
    );
    setState(() => selectedUserId = null);
  }

  void _remove(BuildContext context, String id) {
    context.read<UserAssignmentCubit>().removeAssignment(
      id,
      departmentId: widget.level == StructureLevel.department ? widget.node.id : null,
      branchId: widget.level == StructureLevel.branch ? widget.node.id : null,
      divisionId: widget.level == StructureLevel.division ? widget.node.id : null,
      unitId: widget.level == StructureLevel.unit ? widget.node.id : null,
    );
  }
}
