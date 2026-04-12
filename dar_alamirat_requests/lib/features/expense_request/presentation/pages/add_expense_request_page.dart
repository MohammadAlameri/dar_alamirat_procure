import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:dar_alamirat_requests/core/theme/app_theme.dart';
import 'package:dar_alamirat_requests/core/localization/app_localizations.dart';
import 'package:dar_alamirat_requests/features/auth/domain/entities/profile.dart';
import 'package:dar_alamirat_requests/features/management/domain/entities/branch.dart';
import 'package:dar_alamirat_requests/core/di/injection_container.dart';
import 'package:dar_alamirat_requests/core/widgets/custom_snackbar.dart';
import '../cubit/expense_request_cubit.dart';

class AddExpenseRequestPage extends StatelessWidget {
  final Profile profile;
  final Branch? selectedBranch;

  const AddExpenseRequestPage({
    super.key,
    required this.profile,
    this.selectedBranch,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ExpenseRequestCubit>(),
      child: _AddExpenseRequestPageContent(
        profile: profile,
        selectedBranch: selectedBranch,
      ),
    );
  }
}

class _AddExpenseRequestPageContent extends StatefulWidget {
  final Profile profile;
  final Branch? selectedBranch;

  const _AddExpenseRequestPageContent({
    required this.profile,
    this.selectedBranch,
  });

  @override
  State<_AddExpenseRequestPageContent> createState() => _AddExpenseRequestPageContentState();
}

class _AddExpenseRequestPageContentState extends State<_AddExpenseRequestPageContent> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _statementController = TextEditingController();
  final _amountController = TextEditingController();
  String _approvalLevel = 'manager';
  bool _isSubmitting = false;

  @override
  void dispose() {
    _subjectController.dispose();
    _statementController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    final l10n = AppLocalizations.of(context)!;

    try {
      final cubit = context.read<ExpenseRequestCubit>();
      await cubit.createRequest(
        subject: _subjectController.text.trim(),
        description: _statementController.text.trim(),
        branchId: widget.selectedBranch!.id,
        employeeId: widget.profile.id,
        amount: double.tryParse(_amountController.text) ?? 0,
        highestApprovalLevel: _approvalLevel,
        employeeName: widget.profile.fullName,
      );

      if (mounted) {
        AppSnackBar.show(
          context,
          l10n.translate('expenseRequestCreatedSuccessfully'),
          type: SnackBarType.success,
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.show(
          context,
          '${l10n.translate('error')}: $e',
          type: SnackBarType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.translate('newExpenseRequest')),
        backgroundColor: AppTheme.primaryPink,
        foregroundColor: AppTheme.darkGray,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Subject
            TextFormField(
              controller: _subjectController,
              decoration: InputDecoration(
                labelText: l10n.translate('subjectRequired'),
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(LucideIcons.fileText),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return l10n.translate('enterSubject');
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Statement/Description
            TextFormField(
              controller: _statementController,
              decoration: InputDecoration(
                labelText: l10n.translate('statementRequired'),
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(LucideIcons.alignLeft),
              ),
              maxLines: 4,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return l10n.translate('enterDescription');
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Amount
            TextFormField(
              controller: _amountController,
              decoration: InputDecoration(
                labelText: l10n.translate('amountRequired'),
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(LucideIcons.banknote),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return l10n.translate('enterAmount');
                }
                if (double.tryParse(value) == null) {
                  return l10n.translate('validNumber');
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Approval Level
            DropdownButtonFormField<String>(
              initialValue: _approvalLevel,
              decoration: InputDecoration(
                labelText: l10n.translate('highestApprovalLevel'),
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(LucideIcons.userCheck),
              ),
              items: [
                DropdownMenuItem(value: 'manager', child: Text(l10n.translate('manager'))),
                DropdownMenuItem(value: 'finance', child: Text(l10n.translate('finance'))),
                DropdownMenuItem(value: 'general_manager', child: Text(l10n.translate('general_manager'))),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _approvalLevel = value);
                }
              },
            ),
            const SizedBox(height: 16),

            // Info Card
            Card(
              color: AppTheme.backgroundGray,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(LucideIcons.info, color: Color.fromARGB(255, 220, 203, 52)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l10n.translate('approvalWorkflowInfo'),
                        style: const TextStyle(color: Color.fromARGB(255, 220, 203, 52)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Submit Button
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryPink,
                  foregroundColor: AppTheme.darkGray,
                ),
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: AppTheme.darkGray)
                    : Text(
                        l10n.translate('submitExpenseRequest'),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
