import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:dar_alamirat_requests/core/localization/app_localizations.dart';
import 'package:dar_alamirat_requests/core/theme/app_theme.dart';
import 'package:dar_alamirat_requests/features/management/domain/entities/structure_node.dart';
import 'package:dar_alamirat_requests/features/management/presentation/cubit/company_structure_cubit.dart';
import 'package:dar_alamirat_requests/features/management/presentation/cubit/user_cubit.dart';
import 'package:dar_alamirat_requests/features/auth/domain/entities/profile.dart';
import 'package:dar_alamirat_requests/core/di/injection_container.dart';

class AddStructureNodePage extends StatefulWidget {
  final StructureLevel level;
  final String? parentId;
  final StructureNode? nodeToEdit;

  const AddStructureNodePage({
    super.key,
    required this.level,
    this.parentId,
    this.nodeToEdit,
  });

  @override
  State<AddStructureNodePage> createState() => _AddStructureNodePageState();
}

class _AddStructureNodePageState extends State<AddStructureNodePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _nameArController;
  late TextEditingController _descriptionController;
  late TextEditingController _phoneController;
  String? _selectedManagerId;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.nodeToEdit?.name);
    _nameArController = TextEditingController(text: widget.nodeToEdit?.nameAr);
    _descriptionController = TextEditingController(text: widget.nodeToEdit?.description);
    _phoneController = TextEditingController(text: widget.nodeToEdit?.phone);
    _selectedManagerId = widget.nodeToEdit?.managerId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameArController.dispose();
    _descriptionController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isEditing = widget.nodeToEdit != null;

    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => sl<CompanyStructureCubit>()),
        BlocProvider(create: (context) => sl<UserCubit>()..loadUsers()),
      ],
      child: BlocConsumer<CompanyStructureCubit, CompanyStructureState>(
        listener: (context, state) {
          // Navigation logic handled in _submit
        },
        builder: (context, state) {
          return Scaffold(
            appBar: AppBar(
              title: Text(isEditing 
                ? (l10n.translate('edit') ?? 'Edit') 
                : (l10n.translate('add') ?? 'Add')),
            ),
            body: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildTextField(
                    controller: _nameController,
                    label: l10n.translate('nameEn') ?? 'Name (EN)',
                    icon: LucideIcons.type,
                    validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _nameArController,
                    label: l10n.translate('nameAr') ?? 'Name (AR)',
                    icon: LucideIcons.languages,
                  ),
                  const SizedBox(height: 16),
                  
                  // Manager Selection
                  BlocBuilder<UserCubit, UserState>(
                    builder: (context, userState) {
                      List<Profile> managers = [];
                      if (userState is UserLoaded) {
                        managers = userState.users;
                      }

                      return DropdownButtonFormField<String>(
                        value: _selectedManagerId,
                        decoration: InputDecoration(
                          labelText: l10n.translate('directManager') ?? 'Manager',
                          prefixIcon: const Icon(LucideIcons.userCheck),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        hint: Text(l10n.translate('selectManager') ?? 'Select Manager'),
                        items: [
                          DropdownMenuItem<String>(
                            value: null,
                            child: Text(l10n.translate('none') ?? 'None'),
                          ),
                          ...managers.map((m) => DropdownMenuItem(
                            value: m.id,
                            child: Text('${m.fullName} (${l10n.translate(m.role.name)})'),
                          )),
                        ],
                        onChanged: (val) {
                          setState(() => _selectedManagerId = val);
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  _buildTextField(
                    controller: _descriptionController,
                    label: l10n.translate('description') ?? 'Description',
                    icon: LucideIcons.fileText,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _phoneController,
                    label: l10n.translate('phone') ?? 'Phone',
                    icon: LucideIcons.phone,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () => _submit(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryPink,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: state.isLoading 
                      ? const CircularProgressIndicator()
                      : Text(
                          isEditing ? (l10n.translate('save') ?? 'Save') : (l10n.translate('create') ?? 'Create'),
                          style: const TextStyle(color: AppTheme.darkGray, fontWeight: FontWeight.bold),
                        ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      maxLines: maxLines,
      validator: validator,
      keyboardType: keyboardType,
    );
  }

  void _submit(BuildContext context) {
    if (!_formKey.currentState!.validate()) return;

    final data = {
      'name': _nameController.text,
      'name_ar': _nameArController.text,
      'description': _descriptionController.text,
      'phone': _phoneController.text,
      'manager_id': _selectedManagerId,
    };

    final cubit = context.read<CompanyStructureCubit>();
    if (widget.nodeToEdit != null) {
      cubit.updateNode(widget.level, widget.nodeToEdit!.id, data, parentId: widget.parentId).then((_) {
        Navigator.pop(context);
      });
    } else {
      cubit.createNode(widget.level, data, parentId: widget.parentId).then((_) {
        Navigator.pop(context);
      });
    }
  }
}
