import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:dar_alamirat_requests/core/localization/app_localizations.dart';
import 'package:dar_alamirat_requests/core/theme/app_theme.dart';
import 'package:dar_alamirat_requests/features/auth/domain/entities/profile.dart';
import 'package:dar_alamirat_requests/features/management/domain/entities/branch.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dar_alamirat_requests/core/di/injection_container.dart';
import 'package:dar_alamirat_requests/core/widgets/custom_snackbar.dart';
import '../cubit/purchase_request_cubit.dart';

class AddPurchaseRequestPage extends StatelessWidget {
  final Profile profile;
  final Branch? selectedBranch;

  const AddPurchaseRequestPage({
    super.key,
    required this.profile,
    this.selectedBranch,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<PurchaseRequestCubit>(),
      child: _AddPurchaseRequestPageContent(
        profile: profile,
        selectedBranch: selectedBranch,
      ),
    );
  }
}

class _AddPurchaseRequestPageContent extends StatefulWidget {
  final Profile profile;
  final Branch? selectedBranch;

  const _AddPurchaseRequestPageContent({
    required this.profile,
    this.selectedBranch,
  });

  @override
  State<_AddPurchaseRequestPageContent> createState() => _AddPurchaseRequestPageContentState();
}

class _AddPurchaseRequestPageContentState extends State<_AddPurchaseRequestPageContent> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _justificationController = TextEditingController();
  final _employeeNameController = TextEditingController();
  final _jobTitleController = TextEditingController();
  
  final List<Map<String, dynamic>> _items = [];
  bool _isSubmitting = false;
  List<Map<String, dynamic>> _availableProducts = [];

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    try {
      final client = Supabase.instance.client;
      final data = await client.from('products').select('*');
      if (mounted) {
        setState(() {
          _availableProducts = (data as List).cast<Map<String, dynamic>>();
        });
      }
    } catch (e) {
      debugPrint('Error loading products: $e');
    }
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _justificationController.dispose();
    _employeeNameController.dispose();
    _jobTitleController.dispose();
    for (var item in _items) {
      item['spec_controller']?.dispose();
      item['price_controller']?.dispose();
      item['qty_controller']?.dispose();
      item['product_controller']?.dispose();
    }
    super.dispose();
  }

  void _addItem() {
    setState(() {
      _items.add({
        'product_name': '',
        'product_id': null,
        'specifications': '',
        'unit': 'pcs',
        'quantity': 1,
        'unit_price': 0.0,
        'spec_controller': TextEditingController(),
        'price_controller': TextEditingController(text: '0.0'),
        'qty_controller': TextEditingController(text: '1'),
        'product_controller': TextEditingController(),
      });
    });
  }

  void _removeItem(int index) {
    setState(() {
      _items[index]['spec_controller']?.dispose();
      _items[index]['price_controller']?.dispose();
      _items[index]['qty_controller']?.dispose();
      _items[index]['product_controller']?.dispose();
      _items.removeAt(index);
    });
  }

  void _updateItem(int index, String key, dynamic value) {
    setState(() {
      _items[index][key] = value;
    });
  }

  double _calculateTotal() {
    return _items.fold(0, (sum, item) {
      final qty = (item['quantity'] as num).toDouble();
      final price = (item['unit_price'] as num).toDouble();
      return sum + (qty * price);
    });
  }

  Future<void> _submitForm() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;
    if (_items.isEmpty) {
      AppSnackBar.show(
        context,
        l10n.translate('addAtLeastOneItem'),
        type: SnackBarType.warning,
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final cubit = context.read<PurchaseRequestCubit>();
      await cubit.createRequest(
        subject: _subjectController.text.trim(),
        description: _justificationController.text.trim(),
        branchId: widget.selectedBranch!.id,
        createdBy: widget.profile.id,
        totalAmount: _calculateTotal(),
        items: _items,
        employeeName: _employeeNameController.text.trim(),
        jobTitle: _jobTitleController.text.trim(),
      );

      if (mounted) {
        AppSnackBar.show(
          context,
          l10n.translate('purchaseRequestCreatedSuccessfully'),
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
        title: Text(l10n.translate('newPurchaseRequest')),
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

            // Justification
            TextFormField(
              controller: _justificationController,
              decoration: InputDecoration(
                labelText: l10n.translate('justification'),
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(LucideIcons.alignLeft),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            // Employee Name
            TextFormField(
              controller: _employeeNameController,
              decoration: InputDecoration(
                labelText: l10n.translate('employeeName'),
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(LucideIcons.user),
              ),
            ),
            const SizedBox(height: 16),

            // Job Title
            TextFormField(
              controller: _jobTitleController,
              decoration: InputDecoration(
                labelText: l10n.translate('jobTitle'),
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(LucideIcons.briefcase),
              ),
            ),
            const SizedBox(height: 24),

            // Items Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.translate('items'),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                ElevatedButton.icon(
                  onPressed: _addItem,
                  icon: const Icon(LucideIcons.plus, size: 18),
                  label: Text(l10n.translate('addItem')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryPink,
                    foregroundColor: AppTheme.darkGray,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Items List
            if (_items.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    l10n.translate('noItemsAdded'),
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
              ),

            ..._items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            '${l10n.translate('itemLabel')} ${index + 1}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(LucideIcons.trash2, color: Colors.red),
                            onPressed: () => _removeItem(index),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Product Name
                      Autocomplete<Map<String, dynamic>>(
                        displayStringForOption: (option) => option['name'] as String,
                        optionsBuilder: (textEditingValue) {
                          if (textEditingValue.text.isEmpty) {
                            return const Iterable<Map<String, dynamic>>.empty();
                          }
                          return _availableProducts.where((product) =>
                              product['name'].toString().toLowerCase().contains(textEditingValue.text.toLowerCase()));
                        },
                        onSelected: (selection) {
                          _updateItem(index, 'product_name', selection['name']);
                          _updateItem(index, 'product_id', selection['id']);
                          if (selection['product_details'] != null) {
                            _updateItem(index, 'specifications', selection['product_details']);
                            item['spec_controller']?.text = selection['product_details'];
                          }
                        },
                        fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                          // Keep item state synced
                          // If we loaded a draft or something, we'd set controller.text here.
                          // But we start fresh, so we just attach listeners.
                          return TextFormField(
                            controller: controller,
                            focusNode: focusNode,
                            decoration: InputDecoration(
                              labelText: l10n.translate('productNameRequired2'),
                              border: const OutlineInputBorder(),
                            ),
                            onChanged: (value) => _updateItem(index, 'product_name', value),
                            validator: (value) => (value == null || value.trim().isEmpty) ? l10n.translate('requiredField') : null,
                          );
                        },
                      ),
                      const SizedBox(height: 8),

                      // Specifications
                      TextFormField(
                        controller: item['spec_controller'],
                        decoration: InputDecoration(
                          labelText: l10n.translate('specifications'),
                          border: const OutlineInputBorder(),
                        ),
                        onChanged: (value) => _updateItem(index, 'specifications', value),
                      ),
                      const SizedBox(height: 8),

                      // Unit
                      DropdownButtonFormField<String>(
                        initialValue: item['unit'],
                        decoration: InputDecoration(
                          labelText: l10n.translate('unit'),
                          border: const OutlineInputBorder(),
                        ),
                        items: ['pcs', 'box', 'kg', 'liter', 'meter', 'set']
                            .map((unit) => DropdownMenuItem(
                                  value: unit,
                                  child: Text(l10n.translate(unit)),
                                ))
                            .toList(),
                        onChanged: (value) => _updateItem(index, 'unit', value),
                      ),
                      const SizedBox(height: 8),

                      // Quantity & Unit Price
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: item['qty_controller'],
                              decoration: InputDecoration(
                                labelText: l10n.translate('quantityRequired'),
                                border: const OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              onTap: () {
                                if (item['qty_controller']?.text == '1' || item['qty_controller']?.text == '0') {
                                  item['qty_controller']?.text = '';
                                }
                              },
                              onChanged: (value) {
                                _updateItem(index, 'quantity', double.tryParse(value) ?? 0);
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) return l10n.translate('requiredField');
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: item['price_controller'],
                              decoration: InputDecoration(
                                labelText: l10n.translate('unitPriceRequired'),
                                border: const OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              onTap: () {
                                if (item['price_controller']?.text == '0.0' || item['price_controller']?.text == '0') {
                                  item['price_controller']?.text = '';
                                }
                              },
                              onChanged: (value) {
                                _updateItem(index, 'unit_price', double.tryParse(value) ?? 0);
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) return l10n.translate('requiredField');
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Item Total
                      Text(
                        '${l10n.translate('total')}: ${((item['quantity'] as num).toDouble() * (item['unit_price'] as num).toDouble()).toStringAsFixed(2)} ${l10n.translate('sar')}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryPink,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),

            if (_items.isNotEmpty) ...[
              const SizedBox(height: 16),
              Card(
                color: AppTheme.backgroundGray,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.translate('grandTotal'),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${_calculateTotal().toStringAsFixed(2)} ${l10n.translate('sar')}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.darkGray,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

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
                        l10n.translate('submitRequest'),
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
