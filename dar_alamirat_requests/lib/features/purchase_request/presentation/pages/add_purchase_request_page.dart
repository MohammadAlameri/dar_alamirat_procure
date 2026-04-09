import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:dar_alamirat_requests/core/localization/app_localizations.dart';
import 'package:dar_alamirat_requests/core/theme/app_theme.dart';
import 'package:dar_alamirat_requests/features/auth/domain/entities/profile.dart';
import 'package:dar_alamirat_requests/features/management/domain/entities/branch.dart';
import 'package:dar_alamirat_requests/core/di/injection_container.dart';
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
  
  List<Map<String, dynamic>> _items = [];
  bool _isSubmitting = false;

  @override
  void dispose() {
    _subjectController.dispose();
    _justificationController.dispose();
    super.dispose();
  }

  void _addItem() {
    setState(() {
      _items.add({
        'product_name': '',
        'specifications': '',
        'unit': 'pcs',
        'quantity': 1,
        'unit_price': 0.0,
      });
    });
  }

  void _removeItem(int index) {
    setState(() {
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.translate('addAtLeastOneItem'))),
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
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.translate('purchaseRequestCreatedSuccessfully'))),
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
                      TextFormField(
                        initialValue: item['product_name'],
                        decoration: InputDecoration(
                          labelText: l10n.translate('productNameRequired2'),
                          border: const OutlineInputBorder(),
                        ),
                        onChanged: (value) => _updateItem(index, 'product_name', value),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return l10n.translate('requiredField');
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),

                      // Specifications
                      TextFormField(
                        initialValue: item['specifications'],
                        decoration: InputDecoration(
                          labelText: l10n.translate('specifications'),
                          border: const OutlineInputBorder(),
                        ),
                        onChanged: (value) => _updateItem(index, 'specifications', value),
                      ),
                      const SizedBox(height: 8),

                      // Unit
                      DropdownButtonFormField<String>(
                        value: item['unit'],
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
                              initialValue: item['quantity'].toString(),
                              decoration: InputDecoration(
                                labelText: l10n.translate('quantityRequired'),
                                border: const OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
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
                              initialValue: item['unit_price'].toString(),
                              decoration: InputDecoration(
                                labelText: l10n.translate('unitPriceRequired'),
                                border: const OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
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
            }).toList(),

            if (_items.isNotEmpty) ...[
              const SizedBox(height: 16),
              Card(
                color: AppTheme.primaryPink.withOpacity(0.1),
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
                          color: AppTheme.primaryPink,
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
