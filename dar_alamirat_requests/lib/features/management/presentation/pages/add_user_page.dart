import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:dar_alamirat_requests/core/theme/app_theme.dart';
import 'package:dar_alamirat_requests/features/management/presentation/cubit/user_cubit.dart';

import 'package:dar_alamirat_requests/features/auth/domain/entities/profile.dart';
import 'package:dar_alamirat_requests/core/localization/app_localizations.dart';

class AddUserPage extends StatefulWidget {
  final Profile? userToEdit;
  
  const AddUserPage({super.key, this.userToEdit});

  @override
  State<AddUserPage> createState() => _AddUserPageState();
}

class _AddUserPageState extends State<AddUserPage> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _jobTitleController = TextEditingController();
  final _departmentController = TextEditingController();
  
  String _selectedRole = 'employee';
  String? _selectedManagerId;
  bool _isLoading = false;
  bool _obscurePassword = true;

  final List<String> _roles = [
    'employee',
    'manager',
    'it_procurement',
    'finance',
    'admin',
    'general_manager',
    'accountant',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.userToEdit != null) {
      final user = widget.userToEdit!;
      _fullNameController.text = user.fullName;
      _emailController.text = user.email;
      _selectedRole = user.role.name;
      _jobTitleController.text = user.jobTitle ?? '';
      _departmentController.text = user.department ?? '';
      _selectedManagerId = user.managerId;
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _jobTitleController.dispose();
    _departmentController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final l10n = AppLocalizations.of(context)!;

    try {
      final cubit = context.read<UserCubit>();
      
      if (widget.userToEdit != null) {
        await cubit.updateUser(
          id: widget.userToEdit!.id,
          fullName: _fullNameController.text.trim(),
          email: _emailController.text.trim(),
          role: UserRole.values.firstWhere((e) => e.name == _selectedRole),
          jobTitle: _jobTitleController.text.trim().isEmpty ? null : _jobTitleController.text.trim(),
          department: _departmentController.text.trim().isEmpty ? null : _departmentController.text.trim(),
          managerId: _selectedManagerId,
        );
      } else {
        await cubit.createUser(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          fullName: _fullNameController.text.trim(),
          role: _selectedRole,
          jobTitle: _jobTitleController.text.trim().isEmpty ? null : _jobTitleController.text.trim(),
          department: _departmentController.text.trim().isEmpty ? null : _departmentController.text.trim(),
          managerId: _selectedManagerId,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.userToEdit != null ? l10n.translate('userUpdatedSuccessfully') : l10n.translate('userCreatedSuccessfully')),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.translate('error')}: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.userToEdit != null;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? l10n.translate('updateUser') : l10n.translate('addUser')),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.darkGray,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Full Name
            TextFormField(
              controller: _fullNameController,
              decoration: InputDecoration(
                labelText: l10n.translate('name'),
                hintText: l10n.translate('enterFullName'),
                prefixIcon: const Icon(LucideIcons.user, size: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return l10n.translate('fullNameRequired');
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Email
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              enabled: !isEditing, // Email shouldn't be edited easily
              decoration: InputDecoration(
                labelText: l10n.translate('email'),
                hintText: 'user@example.com',
                prefixIcon: const Icon(LucideIcons.mail, size: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return l10n.translate('emailRequired');
                }
                if (!value.contains('@')) {
                  return l10n.translate('invalidEmail');
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Password
            if (!isEditing) ...[
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: l10n.translate('password'),
                  hintText: l10n.translate('enterPassword'),
                  prefixIcon: const Icon(LucideIcons.lock, size: 20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? LucideIcons.eye : LucideIcons.eyeOff,
                      size: 20,
                    ),
                    onPressed: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return l10n.translate('passwordRequired');
                  }
                  if (value.length < 6) {
                    return l10n.translate('passwordMinLength');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
            ],

            // Role Dropdown
            DropdownButtonFormField<String>(
              initialValue: _selectedRole,
              decoration: InputDecoration(
                labelText: l10n.translate('roles'),
                prefixIcon: const Icon(LucideIcons.shield, size: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: _roles.map((role) {
                return DropdownMenuItem(
                  value: role,
                  child: Text(l10n.translate(role).toUpperCase()),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedRole = value);
                }
              },
            ),
            const SizedBox(height: 16),

            // Job Title (Optional)
            TextFormField(
              controller: _jobTitleController,
              decoration: InputDecoration(
                labelText: l10n.translate('jobTitleOptional'),
                hintText: l10n.translate('egSoftwareEngineer'),
                prefixIcon: const Icon(LucideIcons.briefcase, size: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Department (Optional)
            TextFormField(
              controller: _departmentController,
              decoration: InputDecoration(
                labelText: l10n.translate('departmentOptional'),
                hintText: l10n.translate('egItFinance'),
                prefixIcon: const Icon(LucideIcons.building, size: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Direct Manager Dropdown
            BlocBuilder<UserCubit, UserState>(
              builder: (context, state) {
                List<Profile> managers = [];
                if (state is UserLoaded) {
                  managers = state.users.where((u) => u.id != widget.userToEdit?.id).toList();
                }

                return DropdownButtonFormField<String>(
                  initialValue: _selectedManagerId,
                  decoration: InputDecoration(
                    labelText: l10n.translate('directManager'),
                    prefixIcon: const Icon(LucideIcons.userCheck, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  hint: Text(l10n.translate('selectManager')),
                  items: managers.map((manager) {
                    return DropdownMenuItem(
                      value: manager.id,
                      child: Text('${manager.fullName} (${manager.role.name})'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedManagerId = value);
                  },
                );
              },
            ),
            const SizedBox(height: 24),

            // Info Card
            if (!isEditing)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(LucideIcons.info, color: Colors.blue, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l10n.translate('createUserAccountInfo'),
                        style: const TextStyle(fontSize: 14, color: Colors.blue),
                      ),
                    ),
                  ],
                ),
              ),
            if (!isEditing) const SizedBox(height: 24),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryPink,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        isEditing ? l10n.translate('updateUserButton') : l10n.translate('createUserButton'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
