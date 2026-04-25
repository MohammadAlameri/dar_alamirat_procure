import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shimmer/shimmer.dart';
import 'package:dar_alamirat_requests/core/localization/app_localizations.dart';
import 'package:dar_alamirat_requests/core/theme/app_theme.dart';
import 'package:dar_alamirat_requests/features/management/domain/entities/structure_node.dart';
import 'package:dar_alamirat_requests/features/management/data/repositories/company_structure_repository.dart';
import 'package:dar_alamirat_requests/features/management/presentation/pages/add_structure_node_page.dart';
import 'package:dar_alamirat_requests/features/management/presentation/pages/structure_node_details_page.dart';
import 'package:dar_alamirat_requests/core/di/injection_container.dart';
import '../cubit/company_structure_cubit.dart';

class CompanyStructurePage extends StatefulWidget {
  final StructureLevel initialLevel;
  final String? initialParentId;
  final String? initialParentName;

  const CompanyStructurePage({
    super.key,
    this.initialLevel = StructureLevel.department,
    this.initialParentId,
    this.initialParentName,
  });

  @override
  State<CompanyStructurePage> createState() => _CompanyStructurePageState();
}

class _CompanyStructurePageState extends State<CompanyStructurePage> {
  late StructureLevel _currentLevel;
  String? _currentParentId;
  String? _currentParentName;
  
  final List<({StructureLevel level, String? parentId, String? parentName})> _history = [];

  @override
  void initState() {
    super.initState();
    _currentLevel = widget.initialLevel;
    _currentParentId = widget.initialParentId;
    _currentParentName = widget.initialParentName;
  }

  void _pushLevel(StructureLevel level, String? parentId, String? parentName) {
    setState(() {
      _history.add((level: _currentLevel, parentId: _currentParentId, parentName: _currentParentName));
      _currentLevel = level;
      _currentParentId = parentId;
      _currentParentName = parentName;
    });
  }

  bool _popLevel() {
    if (_history.isEmpty) return true; // Let the system handle it
    setState(() {
      final previous = _history.removeLast();
      _currentLevel = previous.level;
      _currentParentId = previous.parentId;
      _currentParentName = previous.parentName;
    });
    return false; // We handled it
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _history.isEmpty,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _popLevel();
      },
      child: BlocProvider(
        key: ValueKey('structure_${_currentLevel}_$_currentParentId'),
        create: (context) {
          final cubit = sl<CompanyStructureCubit>();
          _loadData(cubit, _currentLevel, _currentParentId);
          return cubit;
        },
        child: CompanyStructureView(
          level: _currentLevel,
          parentId: _currentParentId,
          parentName: _currentParentName,
          onNavigateToNext: _pushLevel,
          onBack: _history.isNotEmpty ? _popLevel : null,
        ),
      ),
    );
  }

  void _loadData(CompanyStructureCubit cubit, StructureLevel level, String? parentId) {
    switch (level) {
      case StructureLevel.department:
        cubit.loadDepartments();
        break;
      case StructureLevel.branch:
        if (parentId != null) cubit.loadBranches(parentId);
        break;
      case StructureLevel.division:
        if (parentId != null) cubit.loadDivisions(parentId);
        break;
      case StructureLevel.unit:
        if (parentId != null) cubit.loadUnits(parentId);
        break;
    }
  }
}

class CompanyStructureView extends StatelessWidget {
  final StructureLevel level;
  final String? parentId;
  final String? parentName;
  final Function(StructureLevel, String?, String?)? onNavigateToNext;
  final VoidCallback? onBack;

  const CompanyStructureView({
    super.key,
    required this.level,
    this.parentId,
    this.parentName,
    this.onNavigateToNext,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(parentName ?? l10n.translate('departments') ?? 'Departments'),
        leading: onBack != null 
          ? IconButton(
              icon: const Icon(LucideIcons.arrowLeft),
              onPressed: onBack,
            )
          : null,
      ),
      body: BlocBuilder<CompanyStructureCubit, CompanyStructureState>(
        builder: (context, state) {
          if (state.isLoading) {
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 5,
              itemBuilder: (context, index) => const NodeCardShimmer(),
            );
          }

          if (state.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(LucideIcons.alertCircle, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(state.error!),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _refresh(context),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state.nodes.isEmpty) {
            return Center(child: Text(l10n.translate('noItemsFound') ?? 'No items found'));
          }

          return RefreshIndicator(
            onRefresh: () async => _refresh(context),
            child: ListView.builder(
              padding: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 100),
              itemCount: state.nodes.length,
              itemBuilder: (context, index) {
                final node = state.nodes[index];
                return NodeCard(
                  node: node,
                  level: level,
                  onTap: () => _onNodeTap(context, node),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 90),
        child: FloatingActionButton(
          onPressed: () => _navigateToAdd(context),
          backgroundColor: AppTheme.primaryPink,
          child: const Icon(LucideIcons.plus, color: AppTheme.darkGray),
        ),
      ),
    );
  }

  String _getLevelName(BuildContext context, StructureLevel level) {
    final l10n = AppLocalizations.of(context)!;
    switch (level) {
      case StructureLevel.department: return l10n.translate('departments') ?? 'Departments';
      case StructureLevel.branch: return l10n.translate('branches') ?? 'Branches';
      case StructureLevel.division: return l10n.translate('divisions') ?? 'Divisions';
      case StructureLevel.unit: return l10n.translate('units') ?? 'Units';
    }
  }

  void _refresh(BuildContext context) {
    final cubit = context.read<CompanyStructureCubit>();
    switch (level) {
      case StructureLevel.department: cubit.loadDepartments(); break;
      case StructureLevel.branch: if (parentId != null) cubit.loadBranches(parentId!); break;
      case StructureLevel.division: if (parentId != null) cubit.loadDivisions(parentId!); break;
      case StructureLevel.unit: if (parentId != null) cubit.loadUnits(parentId!); break;
    }
  }

  void _onNodeTap(BuildContext context, StructureNode node) {
    // Navigate to Details page. If it's a unit, it's a leaf node.
    // Otherwise, it allows drilling down via onDrillDown callback.
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StructureNodeDetailsPage(
          node: node, 
          level: level,
          onDrillDown: onNavigateToNext,
        ),
      ),
    );
  }

  void _navigateToAdd(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddStructureNodePage(level: level, parentId: parentId),
      ),
    ).then((_) => _refresh(context));
  }
}

class NodeCard extends StatelessWidget {
  final StructureNode node;
  final StructureLevel level;
  final VoidCallback onTap;

  const NodeCard({
    super.key,
    required this.node,
    required this.level,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.primaryPink,
          child: Icon(_getIcon(), color: AppTheme.darkGray, size: 20),
        ),
        title: Text(
          node.displayName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(node.phone ?? ''),
        trailing: const Icon(LucideIcons.chevronRight, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }

  IconData _getIcon() {
    switch (level) {
      case StructureLevel.department: return LucideIcons.layers;
      case StructureLevel.branch: return LucideIcons.building;
      case StructureLevel.division: return LucideIcons.layoutGrid;
      case StructureLevel.unit: return LucideIcons.box;
    }
  }
}

class NodeCardShimmer extends StatelessWidget {
  const NodeCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: const ListTile(
          leading: CircleAvatar(backgroundColor: Colors.white),
          title: SizedBox(height: 14, child: ColoredBox(color: Colors.white)),
          subtitle: SizedBox(height: 12, width: 100, child: ColoredBox(color: Colors.white)),
        ),
      ),
    );
  }
}
