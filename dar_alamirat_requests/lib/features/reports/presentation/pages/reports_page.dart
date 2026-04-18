import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:dar_alamirat_requests/core/localization/app_localizations.dart';
import 'package:dar_alamirat_requests/core/theme/app_theme.dart';
import 'package:dar_alamirat_requests/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:dar_alamirat_requests/features/management/data/repositories/branch_repository.dart';
import 'package:dar_alamirat_requests/features/management/data/repositories/user_repository.dart';
import 'package:dar_alamirat_requests/features/auth/domain/entities/profile.dart';
import 'package:dar_alamirat_requests/core/widgets/custom_widgets.dart';
import 'package:dar_alamirat_requests/core/widgets/custom_snackbar.dart';
import 'package:dar_alamirat_requests/core/utils/excel_export_helper.dart';
import 'package:dar_alamirat_requests/core/di/injection_container.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  final DashboardRepository _repository = sl<DashboardRepository>();
  final BranchRepository _branchRepository = BranchRepository();
  final UserRepository _userRepository = UserRepository();

  String _reportType = 'procure'; // 'procure' or 'expense'
  String? _selectedBranch;
  String? _selectedStaff;
  String? _selectedStatus;
  DateTime? _dateFrom;
  DateTime? _dateTo;

  List<BranchState> _branches = [];
  List<Profile> _staff = [];
  List<dynamic> _reportData = [];
  bool _isLoading = false;

  final List<String> _statuses = [
    'pending',
    'manager_approved',
    'it_approved',
    'finance_approved',
    'gm_approved',
    'purchased',
    'received_by_staff',
    'completed',
    'paid',
    'rejected_by_manager',
    'rejected_by_it',
    'rejected_by_finance',
    'rejected_by_gm'
  ];

  @override
  void initState() {
    super.initState();
    _loadFilters();
  }

  Future<void> _loadFilters() async {
    setState(() => _isLoading = true);
    try {
      final branches = await _branchRepository.fetchBranches(onlyActive: true);
      final users = await _userRepository.fetchAllProfiles();
      setState(() {
        _branches = branches.map((b) => BranchState(b.id, b.name, b.nameAr)).toList();
        _staff = users;
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _generateReport() async {
    setState(() => _isLoading = true);
    try {
      if (_reportType == 'procure') {
        final result = await _repository.getPurchaseRequests(
          branchId: _selectedBranch,
          userId: _selectedStaff,
          status: _selectedStatus,
          dateFrom: _dateFrom?.toIso8601String(),
          dateTo: _dateTo?.toIso8601String(),
        );
        result.fold(
          (failure) => _showError(failure.message),
          (data) => setState(() => _reportData = data),
        );
      } else {
        final result = await _repository.getExpenseRequests(
          branchId: _selectedBranch,
          userId: _selectedStaff,
          status: _selectedStatus,
          dateFrom: _dateFrom?.toIso8601String(),
          dateTo: _dateTo?.toIso8601String(),
        );
        result.fold(
          (failure) => _showError(failure.message),
          (data) => setState(() => _reportData = data),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    AppSnackBar.show(context, message, type: SnackBarType.error);
  }

  Future<void> _exportToExcel([Rect? sharePositionOrigin]) async {
    setState(() => _isLoading = true);
    try {
      await ExcelExportHelper.exportRequests(
        data: _reportData,
        reportType: _reportType,
        languageCode: 'ar', // Force Arabic as requested
        sharePositionOrigin: sharePositionOrigin,
      );
    } catch (e) {
      _showError(e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isRTL = l10n.isRTL;

    return RefreshIndicator(
      onRefresh: _loadFilters,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          // Filter Header
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildDropdown(
                        label: l10n.translate('type'),
                        initialValue: _reportType,
                        items: [
                          DropdownMenuItem(value: 'procure', child: Text(l10n.translate('procure'))),
                          DropdownMenuItem(value: 'expense', child: Text(l10n.translate('expense'))),
                        ],
                        onChanged: (v) => setState(() {
                          _reportType = v!;
                          _reportData = [];
                        }),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildDropdown(
                        label: l10n.translate('branch'),
                        initialValue: _selectedBranch,
                        items: [
                          DropdownMenuItem(value: null, child: Text(l10n.translate('all'))),
                          ..._branches.map((b) => DropdownMenuItem(
                                value: b.id,
                                child: Text(
                                  (isRTL && b.nameAr != null && b.nameAr!.isNotEmpty) ? b.nameAr! : b.name,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              )),
                        ],
                        onChanged: (v) => setState(() => _selectedBranch = v),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildDropdown(
                        label: l10n.translate('requester'),
                        initialValue: _selectedStaff,
                        items: [
                          DropdownMenuItem(value: null, child: Text(l10n.translate('all'))),
                          ..._staff.map((s) => DropdownMenuItem(
                                value: s.id,
                                child: Text(s.fullName, overflow: TextOverflow.ellipsis),
                              )),
                        ],
                        onChanged: (v) => setState(() => _selectedStaff = v),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildDropdown(
                        label: l10n.translate('status'),
                        initialValue: _selectedStatus,
                        items: [
                          DropdownMenuItem(value: null, child: Text(l10n.translate('all'))),
                          ..._statuses.map((s) => DropdownMenuItem(value: s, child: Text(l10n.translate(s), overflow: TextOverflow.ellipsis))),
                        ],
                        onChanged: (v) => setState(() => _selectedStatus = v),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _dateFrom ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                            cancelText: l10n.translate('cancel'),
                            confirmText: l10n.translate('ok'),
                            builder: (context, child) {
                              return Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: ColorScheme.light(
                                    primary: AppTheme.primaryPink,
                                    onPrimary: Colors.white,
                                    onSurface: AppTheme.darkGray,
                                  ),
                                  datePickerTheme: DatePickerThemeData(
                                    backgroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    cancelButtonStyle: TextButton.styleFrom(
                                      foregroundColor: Colors.grey,
                                    ),
                                    confirmButtonStyle: TextButton.styleFrom(
                                      foregroundColor: AppTheme.primaryPink,
                                    ),
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: child!,
                                ),
                              );
                            },
                          );
                          if (picked != null) setState(() => _dateFrom = picked);
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _buildDateDisplay(l10n.translate('dateFrom'), _dateFrom),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _dateTo ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                            cancelText: l10n.translate('cancel'),
                            confirmText: l10n.translate('ok'),
                            builder: (context, child) {
                              return Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: ColorScheme.light(
                                    primary: AppTheme.primaryPink,
                                    onPrimary: Colors.white,
                                    onSurface: AppTheme.darkGray,
                                  ),
                                  datePickerTheme: DatePickerThemeData(
                                    backgroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    cancelButtonStyle: TextButton.styleFrom(
                                      foregroundColor: Colors.grey,
                                    ),
                                    confirmButtonStyle: TextButton.styleFrom(
                                      foregroundColor: AppTheme.primaryPink,
                                    ),
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: child!,
                                ),
                              );
                            },
                          );
                          if (picked != null) setState(() => _dateTo = picked);
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _buildDateDisplay(l10n.translate('dateTo'), _dateTo),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _generateReport,
                          icon: const Icon(LucideIcons.search, size: 18),
                          label: Text(l10n.translate('generateReport'), key: ValueKey(l10n.locale.languageCode)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryPink,
                            foregroundColor: AppTheme.darkGray,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ),
                    if (_reportData.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      SizedBox(
                        height: 48,
                        width: 48,
                        child: Builder(builder: (btnContext) {
                          return ElevatedButton(
                            onPressed: _isLoading
                                ? null
                                : () {
                                    final box = btnContext.findRenderObject() as RenderBox?;
                                    final rect = box != null ? (box.localToGlobal(Offset.zero) & box.size) : null;
                                    _exportToExcel(rect);
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade600,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.zero,
                              shape: const CircleBorder(),
                            ),
                            child: const Icon(LucideIcons.fileSpreadsheet, size: 20),
                          );
                        }),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          if (_reportData.isNotEmpty) ...[
            _buildStatsCards(l10n),
            SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 120),
              scrollDirection: Axis.horizontal,
              child: DataTable(
                horizontalMargin: 12,
                columnSpacing: 20,
                headingRowColor: WidgetStateProperty.all(Colors.grey.shade100),
                columns: [
                  DataColumn(label: Text(l10n.translate('date'))),
                  DataColumn(label: Text(l10n.translate('subject'))),
                  DataColumn(label: Text(l10n.translate('requester'))),
                  DataColumn(label: Text(l10n.translate('status'))),
                  DataColumn(label: Text(l10n.translate('total')), numeric: true),
                ],
                rows: _reportData.map((r) {
                  final status = r.status.toString();
                  final amount = _reportType == 'procure' ? r.totalAmount : r.amount;
                  final requester = _reportType == 'procure' ? (r.profile?.fullName ?? '-') : (r.profile?.fullName ?? '-');

                  return DataRow(cells: [
                    DataCell(Text(DateFormat('yyyy-MM-dd').format(r.createdAt), style: const TextStyle(fontSize: 12))),
                    DataCell(SizedBox(width: 120, child: Text(r.subject, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis))),
                    DataCell(Text(requester, style: const TextStyle(fontSize: 12))),
                    DataCell(StatusBadge(status: status, fontSize: 10)),
                    DataCell(Text(amount.toStringAsFixed(2), style: const TextStyle(fontSize: 12))),
                  ]);
                }).toList(),
              ),
            ),
          ] else if (!_isLoading)
            SizedBox(
              height: 300,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(LucideIcons.fileSpreadsheet, size: 64, color: Colors.grey.shade300),
                    const SizedBox(height: 16),
                    Text(l10n.translate('noRequestsFound'), style: TextStyle(color: Colors.grey.shade500)),
                  ],
                ),
              ),
            ),

          if (_isLoading)
            const SizedBox(height: 100, child: Center(child: CircularProgressIndicator())),
        ],
      ),
    );
  }

  Widget _buildDropdown<T>({required String label, required T? initialValue, required List<DropdownMenuItem<T>> items, required ValueChanged<T?> onChanged}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey), overflow: TextOverflow.ellipsis),
        const SizedBox(height: 4),
        DropdownButtonFormField<T>(
          initialValue: initialValue,
          isExpanded: true,
          items: items,
          onChanged: onChanged,
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            fillColor: Colors.grey.shade50,
            filled: true,
          ),
          style: const TextStyle(fontSize: 12, color: Colors.black),
        ),
      ],
    );
  }

  Widget _buildDateDisplay(String label, DateTime? date) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey), overflow: TextOverflow.ellipsis),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black38),
            borderRadius: BorderRadius.circular(8),
            color: Colors.grey.shade50,
          ),
          child: Row(
            children: [
              Icon(LucideIcons.calendar, size: 14, color: Colors.grey.shade600),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  date != null ? DateFormat('yyyy-MM-dd').format(date) : '----/--/--',
                  style: const TextStyle(fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsCards(AppLocalizations l10n) {
    final count = _reportData.length;
    final total = _reportData.map((r) => _reportType == 'procure' ? r.totalAmount : r.amount).fold(0.0, (a, b) => a + b);
    final completed = _reportData.where((r) => ['completed', 'received', 'paid'].contains(r.status)).length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildStatItem(l10n.translate('total'), count.toString(), Colors.blue),
          const SizedBox(width: 6),
          _buildStatItem(l10n.translate('amount'), total.toStringAsFixed(0), Colors.green),
          const SizedBox(width: 6),
          _buildStatItem(l10n.translate('completed'), completed.toString(), Colors.orange),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Text(label, style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
            Text(value, style: TextStyle(fontSize: 14, color: color, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

class BranchState {
  final String id;
  final String name;
  final String? nameAr;
  BranchState(this.id, this.name, this.nameAr);
}
