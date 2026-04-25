import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:dar_alamirat_requests/core/localization/app_localizations.dart';
import 'package:dar_alamirat_requests/core/theme/app_theme.dart';
import 'package:dar_alamirat_requests/features/management/domain/entities/structure_node.dart';
import 'package:dar_alamirat_requests/features/management/presentation/cubit/company_structure_cubit.dart';
import 'package:dar_alamirat_requests/features/management/presentation/pages/add_structure_node_page.dart';
import 'package:dar_alamirat_requests/features/management/presentation/pages/assign_employee_page.dart';
import 'package:dar_alamirat_requests/features/management/presentation/pages/company_structure_page.dart';

class StructureNodeDetailsPage extends StatelessWidget {
  final StructureNode node;
  final StructureLevel level;
  final Function(StructureLevel, String?, String?)? onDrillDown;

  const StructureNodeDetailsPage({
    super.key,
    required this.node,
    required this.level,
    this.onDrillDown,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(_getLevelLabel(context, level)),
        backgroundColor: AppTheme.primaryPink,
        foregroundColor: AppTheme.darkGray,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Details header
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: AppTheme.primaryPink,
                      child: Icon(_getIcon(), size: 40, color: AppTheme.darkGray),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      node.displayName,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    if (node.description != null && node.description!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        node.description!,
                        style: const TextStyle(fontSize: 14, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 16),
                    _buildInfoRow(LucideIcons.phone, node.phone ?? l10n.translate('notAvailable') ?? 'N/A'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Drill down button (if not unit)
            if (level != StructureLevel.unit) ...[
              ElevatedButton.icon(
                onPressed: () {
                  if (onDrillDown != null) {
                    Navigator.pop(context);
                    onDrillDown!(
                      _getNextLevel(level),
                      node.id,
                      node.displayName,
                    );
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CompanyStructurePage(
                          initialLevel: _getNextLevel(level),
                          initialParentId: node.id,
                          initialParentName: node.displayName,
                        ),
                      ),
                    );
                  }
                },
                icon: Icon(LucideIcons.arrowDownCircle, color: Colors.green.shade700),
                label: Text(
                  _getNextLevelActionLabel(context, level),
                  style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.bold),
                ),
                style: _buttonStyle(Colors.green),
              ),
              const SizedBox(height: 16),
            ],

            // Manage Employees
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AssignEmployeePage(node: node, level: level)),
                );
              },
              icon: Icon(LucideIcons.users, color: Colors.indigo.shade700),
              label: Text(l10n.translate('manageEmployees') ?? 'Manage Employees', style: TextStyle(color: Colors.indigo.shade700, fontWeight: FontWeight.bold)),
              style: _buttonStyle(Colors.indigo),
            ),
            const SizedBox(height: 16),

            // Edit button
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddStructureNodePage(level: level, nodeToEdit: node),
                  ),
                );
              },
              icon: Icon(LucideIcons.edit, color: Colors.blue.shade700),
              label: Text(l10n.translate('edit') ?? 'Edit', style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.bold)),
              style: _buttonStyle(Colors.blue),
            ),
            const SizedBox(height: 16),

            // Delete button
            ElevatedButton.icon(
              onPressed: () => _confirmDelete(context),
              icon: Icon(LucideIcons.trash2, color: Colors.red.shade700),
              label: Text(l10n.translate('delete') ?? 'Delete', style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold)),
              style: _buttonStyle(Colors.red),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 8),
        Text(value, style: const TextStyle(fontSize: 16, color: Colors.grey)),
      ],
    );
  }

  ButtonStyle _buttonStyle(MaterialColor color) {
    return ElevatedButton.styleFrom(
      backgroundColor: color.shade50,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.shade200),
      ),
      padding: const EdgeInsets.symmetric(vertical: 16),
    );
  }

  String _getLevelLabel(BuildContext context, StructureLevel level) {
    final l10n = AppLocalizations.of(context)!;
    switch (level) {
      case StructureLevel.department: return l10n.translate('departmentDetails') ?? 'Department Details';
      case StructureLevel.branch: return l10n.translate('branchDetails') ?? 'Branch Details';
      case StructureLevel.division: return l10n.translate('divisionDetails') ?? 'Division Details';
      case StructureLevel.unit: return l10n.translate('unitDetails') ?? 'Unit Details';
    }
  }

  IconData _getIcon() {
    switch (level) {
      case StructureLevel.department: return LucideIcons.layers;
      case StructureLevel.branch: return LucideIcons.building;
      case StructureLevel.division: return LucideIcons.layoutGrid;
      case StructureLevel.unit: return LucideIcons.box;
    }
  }

  StructureLevel _getNextLevel(StructureLevel level) {
    switch (level) {
      case StructureLevel.department: return StructureLevel.branch;
      case StructureLevel.branch: return StructureLevel.division;
      case StructureLevel.division: return StructureLevel.unit;
      case StructureLevel.unit: return StructureLevel.unit; // Should not happen
    }
  }

  String _getNextLevelActionLabel(BuildContext context, StructureLevel level) {
    final l10n = AppLocalizations.of(context)!;
    switch (level) {
      case StructureLevel.department: return l10n.translate('viewBranches') ?? 'View Branches';
      case StructureLevel.branch: return l10n.translate('viewDivisions') ?? 'View Divisions';
      case StructureLevel.division: return l10n.translate('viewUnits') ?? 'View Units';
      case StructureLevel.unit: return '';
    }
  }

  void _confirmDelete(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.translate('confirmDelete') ?? 'Confirm Delete'),
        content: Text(l10n.translate('confirmDeleteMessage') ?? 'Are you sure you want to delete this item?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.translate('cancel') ?? 'Cancel')),
          TextButton(
            onPressed: () {
              // Delete logic would go here via Cubit
              Navigator.pop(ctx);
            },
            child: Text(l10n.translate('delete') ?? 'Delete', style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
