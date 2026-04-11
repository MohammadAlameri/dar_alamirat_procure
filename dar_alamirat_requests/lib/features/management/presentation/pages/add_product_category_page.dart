import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:dar_alamirat_requests/core/theme/app_theme.dart';
import 'package:dar_alamirat_requests/core/localization/app_localizations.dart';
import 'package:dar_alamirat_requests/features/management/data/repositories/product_repository.dart';
import 'package:dar_alamirat_requests/core/widgets/custom_snackbar.dart';
import '../cubit/product_cubit.dart';

class AddProductPage extends StatelessWidget {
  final Map<String, dynamic>? productToEdit;
  
  const AddProductPage({super.key, this.productToEdit});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ProductCubit(ProductRepository())..loadProducts(),
      child: _AddProductPageContent(productToEdit: productToEdit),
    );
  }
}

class _AddProductPageContent extends StatefulWidget {
  final Map<String, dynamic>? productToEdit;
  
  const _AddProductPageContent({this.productToEdit});

  @override
  State<_AddProductPageContent> createState() => _AddProductPageContentState();
}

class _AddProductPageContentState extends State<_AddProductPageContent> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _detailsController = TextEditingController();
  String? _selectedCategoryId;
  bool _isSubmitting = false;
  List<Map<String, dynamic>> _categories = [];

  @override
  void dispose() {
    _nameController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadCategories();
    if (widget.productToEdit != null) {
      _nameController.text = widget.productToEdit!['name'] ?? '';
      _selectedCategoryId = widget.productToEdit!['category_id']?.toString();
      _detailsController.text = widget.productToEdit!['product_details'] ?? '';
    }
  }

  Future<void> _loadCategories() async {
    try {
      final cubit = context.read<ProductCubit>();
      await cubit.loadProducts();
      if (cubit.state is ProductLoaded) {
        setState(() {
          _categories = (cubit.state as ProductLoaded).categories;
        });
      }
    } catch (e) {
      debugPrint('Error loading categories: $e');
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    final l10n = AppLocalizations.of(context)!;

    try {
      final cubit = context.read<ProductCubit>();
      
      if (widget.productToEdit != null) {
        await cubit.updateProduct(
          widget.productToEdit!['id'],
          name: _nameController.text.trim(),
          categoryId: _selectedCategoryId,
          productDetails: _detailsController.text.trim(),
        );
      } else {
        await cubit.createProduct(
          name: _nameController.text.trim(),
          categoryId: _selectedCategoryId,
          productDetails: _detailsController.text.trim(),
        );
      }

      if (mounted) {
        AppSnackBar.show(
          context,
          widget.productToEdit != null ? l10n.translate('productUpdatedSuccessfully') : l10n.translate('productCreatedSuccessfully'),
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
        title: Text(widget.productToEdit != null ? l10n.translate('editProduct') : l10n.translate('addProduct')),
        backgroundColor: AppTheme.primaryPink,
        foregroundColor: AppTheme.darkGray,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Product Name
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: l10n.translate('productNameRequired'),
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(LucideIcons.package),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return l10n.translate('productNameRequired');
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Category Dropdown
            DropdownButtonFormField<String>(
              initialValue: _selectedCategoryId,
              decoration: InputDecoration(
                labelText: l10n.translate('category'),
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(LucideIcons.folder),
              ),
              hint: Text(l10n.translate('selectCategoryOptional')),
              items: _categories.map((category) {
                return DropdownMenuItem<String>(
                  value: category['id'],
                  child: Text(category['name']),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedCategoryId = value);
              },
            ),
            const SizedBox(height: 16),

            // Product Details
            TextFormField(
              controller: _detailsController,
              decoration: InputDecoration(
                labelText: l10n.translate('productDetails'),
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(LucideIcons.fileText),
              ),
              maxLines: 3,
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
                        widget.productToEdit != null ? l10n.translate('updateProduct') : l10n.translate('createProduct'),
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

class AddCategoryPage extends StatelessWidget {
  final Map<String, dynamic>? categoryToEdit;
  
  const AddCategoryPage({super.key, this.categoryToEdit});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ProductCubit(ProductRepository())..loadProducts(),
      child: _AddCategoryPageContent(categoryToEdit: categoryToEdit),
    );
  }
}

class _AddCategoryPageContent extends StatefulWidget {
  final Map<String, dynamic>? categoryToEdit;

  const _AddCategoryPageContent({this.categoryToEdit});

  @override
  State<_AddCategoryPageContent> createState() => _AddCategoryPageContentState();
}

class _AddCategoryPageContentState extends State<_AddCategoryPageContent> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.categoryToEdit != null) {
      _nameController.text = widget.categoryToEdit!['name'] ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    final l10n = AppLocalizations.of(context)!;

    try {
      final cubit = context.read<ProductCubit>();
      
      if (widget.categoryToEdit != null) {
        await cubit.updateCategory(
          widget.categoryToEdit!['id'],
          name: _nameController.text.trim(),
        );
      } else {
        await cubit.createCategory(
          name: _nameController.text.trim(),
        );
      }

      if (mounted) {
        AppSnackBar.show(
          context,
          widget.categoryToEdit != null ? l10n.translate('categoryUpdatedSuccessfully') : l10n.translate('categoryCreatedSuccessfully'),
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
        title: Text(widget.categoryToEdit != null ? l10n.translate('editCategory') : l10n.translate('addCategory')),
        backgroundColor: AppTheme.primaryPink,
        foregroundColor: AppTheme.darkGray,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Category Name
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: l10n.translate('categoryName'),
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(LucideIcons.folder),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return l10n.translate('categoryNameRequired');
                }
                return null;
              },
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
                        widget.categoryToEdit != null ? l10n.translate('updateCategory') : l10n.translate('createCategory'),
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
