import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:dar_alamirat_requests/core/theme/app_theme.dart';
import 'package:dar_alamirat_requests/features/auth/domain/entities/profile.dart';
import 'package:dar_alamirat_requests/features/management/domain/entities/branch.dart';
import 'package:dar_alamirat_requests/features/expense_request/data/repositories/expense_request_repository.dart';
import '../cubits/expense_request_cubit.dart';

class AddExpenseRequestPage extends StatefulWidget {
  final Profile profile;
  final Branch? selectedBranch;

  const AddExpenseRequestPage({
    super.key,
    required this.profile,
    this.selectedBranch,
  });

  @override
  State<AddExpenseRequestPage> createState() => _AddExpenseRequestPageState();
}

class _AddExpenseRequestPageState extends State<AddExpenseRequestPage> {
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

    try {
      final cubit = context.read<ExpenseRequestCubit>();
      await cubit.createRequest(
        subject: _subjectController.text.trim(),
        description: _statementController.text.trim(),
        branchId: widget.selectedBranch!.id,
        employeeId: widget.profile.id,
        amount: double.tryParse(_amountController.text) ?? 0,
        highestApprovalLevel: _approvalLevel,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Expense request created successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Expense Request'),
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
              decoration: const InputDecoration(
                labelText: 'Subject *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(LucideIcons.fileText),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a subject';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Statement/Description
            TextFormField(
              controller: _statementController,
              decoration: const InputDecoration(
                labelText: 'Statement/Description *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(LucideIcons.alignLeft),
              ),
              maxLines: 4,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a description';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Amount
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Amount (SAR) *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(LucideIcons.banknote),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter an amount';
                }
                if (double.tryParse(value) == null) {
                  return 'Please enter a valid number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Approval Level
            DropdownButtonFormField<String>(
              value: _approvalLevel,
              decoration: const InputDecoration(
                labelText: 'Highest Approval Level *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(LucideIcons.userCheck),
              ),
              items: const [
                DropdownMenuItem(value: 'manager', child: Text('Manager')),
                DropdownMenuItem(value: 'finance', child: Text('Finance')),
                DropdownMenuItem(value: 'general_manager', child: Text('General Manager')),
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
              color: Colors.blue.withOpacity(0.1),
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(LucideIcons.info, color: Colors.blue),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'The request will go through the approval workflow based on the selected approval level.',
                        style: TextStyle(color: Colors.blue),
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
                    : const Text(
                        'Submit Expense Request',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
