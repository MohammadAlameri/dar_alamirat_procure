import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:dar_alamirat_requests/core/theme/app_theme.dart';
import 'package:dar_alamirat_requests/core/localization/app_localizations.dart';
import 'package:dar_alamirat_requests/features/management/data/repositories/branch_repository.dart';
import '../cubit/branch_cubit.dart';

class AddBranchPage extends StatelessWidget {
  const AddBranchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => BranchCubit(BranchRepository()),
      child: const _AddBranchPageContent(),
    );
  }
}

class _AddBranchPageContent extends StatefulWidget {
  const _AddBranchPageContent();

  @override
  State<_AddBranchPageContent> createState() => _AddBranchPageContentState();
}

class _AddBranchPageContentState extends State<_AddBranchPageContent> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _nameArController = TextEditingController();
  final _codeController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _nameArController.dispose();
    _codeController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    final l10n = AppLocalizations.of(context)!;

    try {
      final cubit = context.read<BranchCubit>();
      await cubit.createBranch(
        name: _nameController.text.trim(),
        nameAr: _nameArController.text.trim().isEmpty ? null : _nameArController.text.trim(),
        code: _codeController.text.trim().isEmpty ? null : _codeController.text.trim(),
        address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
        phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.translate('branchCreatedSuccessfully'))),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.translate('error')}: $e')),
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
        title: Text(l10n.translate('addBranch')),
        backgroundColor: AppTheme.primaryPink,
        foregroundColor: AppTheme.darkGray,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Branch Name (English)
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: l10n.translate('branchNameEn'),
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(LucideIcons.building),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return l10n.translate('branchNameRequired');
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Branch Name (Arabic)
            TextFormField(
              controller: _nameArController,
              decoration: InputDecoration(
                labelText: l10n.translate('branchNameAr'),
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(LucideIcons.languages),
              ),
            ),
            const SizedBox(height: 16),

            // Branch Code
            TextFormField(
              controller: _codeController,
              decoration: InputDecoration(
                labelText: l10n.translate('branchCode'),
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(LucideIcons.hash),
              ),
            ),
            const SizedBox(height: 16),

            // Address
            TextFormField(
              controller: _addressController,
              decoration: InputDecoration(
                labelText: l10n.translate('address'),
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(LucideIcons.mapPin),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),

            // Phone
            TextFormField(
              controller: _phoneController,
              decoration: InputDecoration(
                labelText: l10n.translate('phone'),
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(LucideIcons.phone),
              ),
              keyboardType: TextInputType.phone,
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
                        l10n.translate('createBranch'),
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
