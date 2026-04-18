import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:lucide_icons/lucide_icons.dart';
import 'package:dar_alamirat_requests/core/localization/app_localizations.dart';
import 'package:dar_alamirat_requests/core/widgets/custom_widgets.dart';
import 'package:dar_alamirat_requests/features/auth/domain/entities/profile.dart';
import 'package:dar_alamirat_requests/features/purchase_request/domain/entities/purchase_request.dart';
import 'package:dar_alamirat_requests/features/purchase_request/domain/entities/request_item.dart';
import 'package:dar_alamirat_requests/features/expense_request/domain/entities/expense_request.dart';
import 'package:dar_alamirat_requests/core/services/print_service.dart';
import 'package:dar_alamirat_requests/core/widgets/custom_snackbar.dart';
import 'package:dar_alamirat_requests/core/theme/app_theme.dart';
import '../cubit/request_details_cubit.dart';

class RequestDetailsPage extends StatelessWidget {
  final String requestId;
  final String type;
  final Profile currentUser;

  const RequestDetailsPage({
    super.key,
    required this.requestId,
    required this.type,
    required this.currentUser,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => RequestDetailsCubit()..loadDetails(requestId, type),
      child: RequestDetailsView(currentUser: currentUser),
    );
  }
}

class RequestDetailsView extends StatelessWidget {
  final Profile currentUser;

  const RequestDetailsView({super.key, required this.currentUser});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.translate('requestDetails')),
        actions: [
          BlocBuilder<RequestDetailsCubit, RequestDetailsState>(
            builder: (context, state) {
              if (state is RequestDetailsLoaded) {
                return PopupMenuButton<String>(
                  icon: const Icon(LucideIcons.printer),
                  onSelected: (value) async {
                    try {
                      if (value == 'request') {
                        if (state.request is PurchaseRequest) {
                          await PrintService.printPurchaseRequest(state.request as PurchaseRequest);
                        } else if (state.request is ExpenseRequest) {
                          await PrintService.printExpenseRequest(state.request as ExpenseRequest);
                        }
                      } else if (value == 'receipt') {
                        if (state.request is PurchaseRequest) {
                          await PrintService.printReceipt(state.request as PurchaseRequest);
                        } else if (state.request is ExpenseRequest) {
                          await PrintService.printExpenseReceipt(state.request as ExpenseRequest);
                        }
                      }
                    } catch (e) {
                      if (context.mounted) {
                        AppSnackBar.show(context, '${l10n.translate('error')}: $e', type: SnackBarType.error);
                      }
                    }
                  },
                  itemBuilder: (context) {
                    final List<PopupMenuEntry<String>> items = [
                      PopupMenuItem(
                        value: 'request',
                        child: Row(
                          children: [
                            const Icon(LucideIcons.fileText, size: 18),
                            const SizedBox(width: 8),
                            Text(l10n.translate('printRequest')),
                          ],
                        ),
                      ),
                    ];

                    bool showReceipt = false;
                    if (state.request is PurchaseRequest) {
                      final req = state.request as PurchaseRequest;
                      showReceipt = req.status == 'purchased' || req.status == 'received_by_staff' || req.status == 'completed';
                    } else if (state.request is ExpenseRequest) {
                      final req = state.request as ExpenseRequest;
                      showReceipt = req.status == 'paid' || req.status == 'completed';
                    }

                    if (showReceipt) {
                      items.add(
                        PopupMenuItem(
                          value: 'receipt',
                          child: Row(
                            children: [
                              const Icon(LucideIcons.receipt, size: 18),
                              const SizedBox(width: 8),
                              Text(l10n.translate('printReceipt')),
                            ],
                          ),
                        ),
                      );
                    }
                    return items;
                  },
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: BlocConsumer<RequestDetailsCubit, RequestDetailsState>(
        listener: (context, state) {
          if (state is RequestDetailsActionSuccess) {
            AppSnackBar.show(context, l10n.translate(state.message), type: SnackBarType.success);
          }
          if (state is RequestDetailsError) {
            AppSnackBar.show(context, state.message, type: SnackBarType.error);
          }
        },
        builder: (context, state) {
          if (state is RequestDetailsLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is RequestDetailsLoaded) {
            final request = state.request;
            if (request is PurchaseRequest) {
              return _PurchaseDetails(request: request, currentUser: currentUser);
            } else if (request is ExpenseRequest) {
              return _ExpenseDetails(request: request, currentUser: currentUser);
            }
          }

          if (state is RequestDetailsError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(LucideIcons.alertCircle, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(state.message),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.read<RequestDetailsCubit>().loadDetails(
                          context.read<RequestDetailsCubit>().state is RequestDetailsLoaded ? (context.read<RequestDetailsCubit>().state as RequestDetailsLoaded).request.id : '',
                          context.read<RequestDetailsCubit>().state is RequestDetailsLoaded ? (context.read<RequestDetailsCubit>().state as RequestDetailsLoaded).request.type : '',
                        ),
                    child: Text(l10n.translate('retry')),
                  ),
                ],
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _PurchaseDetails extends StatelessWidget {
  final PurchaseRequest request;
  final Profile currentUser;

  const _PurchaseDetails({required this.request, required this.currentUser});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Header Info
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '#${request.id.substring(0, 8).toUpperCase()}',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    StatusBadge(status: request.status, fontSize: 12),
                  ],
                ),
                const Divider(height: 24),
                _InfoRow(label: l10n.translate('subject'), value: request.subject),
                const SizedBox(height: 8),
                _InfoRow(
                  label: l10n.translate('requester'),
                  value: request.profile?.fullName ?? request.createdBy ?? '---',
                ),
                const SizedBox(height: 8),
                _InfoRow(
                  label: l10n.translate('date'),
                  value: DateFormat('yyyy-MM-dd HH:mm').format(request.createdAt),
                ),
                const SizedBox(height: 8),
                _InfoRow(
                  label: l10n.translate('totalAmount'),
                  value: '${request.totalAmount.toStringAsFixed(2)} ${l10n.translate('sar')}',
                  valueColor: theme.primaryColor,
                  valueFontWeight: FontWeight.bold,
                ),
                if (request.justification != null && request.justification!.isNotEmpty) ...[
                  const Divider(height: 24),
                  Text(
                    l10n.translate('justification'),
                    style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(request.justification!),
                ],
              ],
            ),
          ),
        ),

        if (request.budgetLineItem != null || request.commitmentNumber != null || request.budgetStatus != null) ...[
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.translate('financeApproval'),
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.blueGrey),
                  ),
                  const Divider(height: 24),
                  if (request.budgetStatus != null)
                    _InfoRow(
                      label: l10n.translate('budgetStatus'),
                      value: request.budgetStatus! ? l10n.translate('available') : l10n.translate('unavailable'),
                      valueColor: request.budgetStatus! ? Colors.green : Colors.red,
                    ),
                  if (request.budgetLineItem != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: _InfoRow(label: l10n.translate('budgetLine'), value: request.budgetLineItem!),
                    ),
                  if (request.commitmentNumber != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: _InfoRow(label: l10n.translate('commitmentNo'), value: request.commitmentNumber!),
                    ),
                  if (request.amountInWords != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: _InfoRow(label: l10n.translate('amountInWords'), value: request.amountInWords!),
                    ),
                ],
              ),
            ),
          ),
        ],

        const SizedBox(height: 16),
        Text(
          l10n.translate('requestedItems'),
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...request.items.map((item) => _RequestItemCard(item: item)),

        if (request.logs.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text(
            l10n.translate('approvalLog'),
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...request.logs.reversed.map((log) => _ApprovalLogTile(log: log)),
        ],

        const SizedBox(height: 24),
        _buildActionButtons(context),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    final role = currentUser.role;
    final status = request.status;
    final l10n = AppLocalizations.of(context)!;

    bool showManagerAction = role == UserRole.manager && (status == 'pending' || status == 'rejected_by_manager');
    bool showITAction = role == UserRole.itProcurement && (status == 'manager_approved' || status == 'rejected_by_it');
    bool showFinanceAction = role == UserRole.finance && (status == 'it_approved' || status == 'rejected_by_finance');
    bool showPurchaseAction = (role == UserRole.itProcurement || role == UserRole.admin) && (status == 'finance_approved' || status == 'rejected_by_it_purchase');
    bool showStaffReceiptAction = (status == 'purchased' || status == 'rejected_by_staff') && currentUser.id == request.createdBy;
    bool showITCompleteAction = (role == UserRole.itProcurement || role == UserRole.admin) && (status == 'received_by_staff');

    if (showManagerAction) {
      return _ActionCard(
        title: l10n.translate('managerApproval'),
        onApprove: (comments, _) => _handleAction(context, 'manager_approved', comments),
        onReject: (comments, _) => _handleAction(context, 'rejected_by_manager', comments),
      );
    }

    if (showITAction) {
      return _ActionCard(
        title: l10n.translate('itProcurementReview'),
        extraFields: (context, controllers) => [
          TextField(
            controller: controllers['suggested_suppliers'] ??= TextEditingController(),
            decoration: InputDecoration(
              labelText: l10n.translate('suggestedSuppliers'),
              border: const OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
        ],
        onApprove: (comments, extras) => _handleAction(context, 'it_approved', comments, {
          'suggested_suppliers': extras['suggested_suppliers'],
        }),
        onReject: (comments, _) => _handleAction(context, 'rejected_by_it', comments),
      );
    }

    if (showFinanceAction) {
      return _ActionCard(
        title: l10n.translate('financeApproval'),
        extraFields: (context, controllers) => [
          TextField(
            controller: controllers['budget_line'] ??= TextEditingController(),
            decoration: InputDecoration(
              labelText: l10n.translate('budgetLine'),
              border: const OutlineInputBorder(),
            ),
          ),
          TextField(
            controller: controllers['commitment_no'] ??= TextEditingController(),
            decoration: InputDecoration(
              labelText: l10n.translate('commitmentNo'),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          StatefulBuilder(
            builder: (context, setState) {
              final isReserved = controllers['budget_status_val']?.text == 'true';
              return CheckboxListTile(
                title: Text(l10n.translate('budgetStatus')),
                subtitle: Text(l10n.translate('isBudgetAvailable')),
                value: isReserved,
                onChanged: (val) {
                  setState(() {
                    controllers['budget_status_val']?.text = val.toString();
                  });
                },
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
              );
            },
          ),
        ],
        onApprove: (comments, extras) => _handleAction(context, 'finance_approved', comments, {
          'budget_line_item': extras['budget_line'],
          'commitment_number': extras['commitment_no'],
          'amount_in_words': comments,
          'budget_status': extras['budget_status_val'] == 'true',
        }),
        onReject: (comments, _) => _handleAction(context, 'rejected_by_finance', comments),
      );
    }

    if (showPurchaseAction) {
      return _ActionCard(
        title: l10n.translate('markAsPurchased'),
        onApprove: (comments, _) => _handleAction(context, 'purchased', comments),
        onReject: (comments, _) => _handleAction(context, 'rejected_by_it_purchase', comments),
      );
    }

    if (showStaffReceiptAction) {
      return _ActionCard(
        title: l10n.translate('staffReceipt'),
        approveLabel: l10n.translate('acceptReceipt'),
        rejectLabel: l10n.translate('rejectReceipt'),
        onApprove: (comments, _) => _handleAction(context, 'received_by_staff', comments, {
          'staff_acceptance_status': 'accepted',
          'staff_receiving_date': DateTime.now().toIso8601String(),
        }),
        onReject: (comments, _) => _handleAction(context, 'rejected_by_staff', comments, {
          'staff_acceptance_status': 'rejected',
          'staff_rejection_reason': comments,
          'staff_receiving_date': DateTime.now().toIso8601String(),
        }),
      );
    }

    if (showITCompleteAction) {
       return _ActionCard(
        title: l10n.translate('completeRequest'),
        onApprove: (comments, _) => _handleAction(context, 'completed', comments),
        hideReject: true,
      );
    }

    return const SizedBox.shrink();
  }

  void _handleAction(BuildContext context, String action, String comments, [Map<String, dynamic>? extra]) {
    context.read<RequestDetailsCubit>().performAction(
      requestId: request.id,
      type: 'procure',
      action: action,
      comments: comments,
      currentUser: currentUser,
      additionalUpdates: extra,
    );
  }
}

class _ExpenseDetails extends StatelessWidget {
  final ExpenseRequest request;
  final Profile currentUser;

  const _ExpenseDetails({required this.request, required this.currentUser});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '#${request.id.substring(0, 8).toUpperCase()}',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    StatusBadge(status: request.status, fontSize: 12),
                  ],
                ),
                const Divider(height: 24),
                _InfoRow(label: l10n.translate('subject'), value: request.subject),
                const SizedBox(height: 8),
                _InfoRow(
                  label: l10n.translate('requester'),
                  value: request.profile?.fullName ?? '---',
                ),
                const SizedBox(height: 8),
                _InfoRow(
                  label: l10n.translate('date'),
                  value: DateFormat('yyyy-MM-dd HH:mm').format(request.createdAt),
                ),
                const SizedBox(height: 8),
                _InfoRow(
                  label: l10n.translate('amount'),
                  value: '${request.amount.toStringAsFixed(2)} ${l10n.translate('sar')}',
                  valueColor: theme.primaryColor,
                  valueFontWeight: FontWeight.bold,
                ),
                const Divider(height: 24),
                Text(
                  l10n.translate('statement'),
                  style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(request.statement),
              ],
            ),
          ),
        ),

        if (request.logs.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text(
            l10n.translate('approvalLog'),
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...request.logs.reversed.map((log) => _ApprovalLogTile(log: log)),
        ],

        const SizedBox(height: 24),
        _buildActionButtons(context),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    final role = currentUser.role;
    final status = request.status;
    final l10n = AppLocalizations.of(context)!;
    final highestLevel = request.highestApprovalLevel;

    bool showManagerAction = role == UserRole.manager && (status == 'pending' || status == 'rejected_by_manager');
    bool showFinanceAction = role == UserRole.finance && (highestLevel != 'manager') && (status == 'manager_approved' || status == 'rejected_by_finance');
    bool showGMAction = role == UserRole.generalManager && (highestLevel == 'general_manager') && (status == 'finance_approved' || status == 'rejected_by_gm');
    
    // Accountant/Payment processing
    bool showAccountantAction = (role == UserRole.accountant || role == UserRole.admin) && (
      (highestLevel == 'manager' && status == 'manager_approved') ||
      (highestLevel == 'finance' && status == 'finance_approved') ||
      (highestLevel == 'general_manager' && status == 'gm_approved')
    );

    if (showManagerAction) {
      return _ActionCard(
        title: l10n.translate('managerApproval'),
        onApprove: (comments, _) => _handleAction(context, 'manager_approved', comments),
        onReject: (comments, _) => _handleAction(context, 'rejected_by_manager', comments),
      );
    }

    if (showFinanceAction) {
      return _ActionCard(
        title: l10n.translate('financeApproval'),
        onApprove: (comments, _) => _handleAction(context, 'finance_approved', comments),
        onReject: (comments, _) => _handleAction(context, 'rejected_by_finance', comments),
      );
    }

    if (showGMAction) {
      return _ActionCard(
        title: l10n.translate('generalManagerApproval'),
        onApprove: (comments, _) => _handleAction(context, 'gm_approved', comments),
        onReject: (comments, _) => _handleAction(context, 'rejected_by_gm', comments),
      );
    }

    if (showAccountantAction) {
      return _ActionCard(
        title: l10n.translate('processPayment'),
        approveLabel: l10n.translate('markAsPaid'),
        onApprove: (comments, _) => _handleAction(context, 'paid', comments),
        onReject: (comments, _) => _handleAction(context, 'rejected_by_accountant', comments),
      );
    }

    return const SizedBox.shrink();
  }

  void _handleAction(BuildContext context, String action, String comments) {
    context.read<RequestDetailsCubit>().performAction(
      requestId: request.id,
      type: 'expense',
      action: action,
      comments: comments,
      currentUser: currentUser,
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final FontWeight? valueFontWeight;

  const _InfoRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.valueFontWeight,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: valueColor,
              fontWeight: valueFontWeight,
            ),
          ),
        ),
      ],
    );
  }
}

class _RequestItemCard extends StatelessWidget {
  final RequestItem item;

  const _RequestItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.productName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            if (item.specifications != null && item.specifications!.isNotEmpty)
              Text(
                item.specifications!,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            if ((item.countryOfOrigin != null && item.countryOfOrigin!.isNotEmpty) ||
                (item.warrantyPeriod != null && item.warrantyPeriod!.isNotEmpty))
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Row(
                  children: [
                    if (item.countryOfOrigin != null && item.countryOfOrigin!.isNotEmpty)
                      Expanded(
                        child: Text(
                          '${l10n.translate('countryOfOrigin')}: ${item.countryOfOrigin}',
                          style: const TextStyle(fontSize: 11, color: Colors.blueGrey),
                        ),
                      ),
                    if (item.warrantyPeriod != null && item.warrantyPeriod!.isNotEmpty)
                      Expanded(
                        child: Text(
                          '${l10n.translate('warrantyPeriod')}: ${item.warrantyPeriod}',
                          style: const TextStyle(fontSize: 11, color: Colors.blueGrey),
                        ),
                      ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  textDirection: TextDirection.rtl,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('${item.quantity} ', style: const TextStyle(fontSize: 12)),
                    Text('${item.unit ?? l10n.translate('pcs')} ', style: const TextStyle(fontSize: 12)),
                    Text(' x ', style: const TextStyle(fontSize: 12)),
                    Text(item.unitPrice.toStringAsFixed(2), style: const TextStyle(fontSize: 12)),
                  ],
                ),
                Text(
                  '${(item.quantity * item.unitPrice).toStringAsFixed(2)} ${l10n.translate('sar')}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ApprovalLogTile extends StatelessWidget {
  final ApprovalLog log;

  const _ApprovalLogTile({required this.log});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isRejected = log.action.toLowerCase().contains('rejected');
    final color = isRejected ? Colors.red : Colors.green;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isRejected ? Colors.red.withValues(alpha: 0.05) : AppTheme.primaryPink.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                log.profile?.fullName ?? l10n.translate('system'),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              Text(
                DateFormat('MMM dd, HH:mm').format(log.createdAt),
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  l10n.translate(log.action),
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (log.comments != null && log.comments!.isNotEmpty)
                Expanded(
                  child: Text(
                    log.comments!,
                    style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatefulWidget {
  final String title;
  final String? approveLabel;
  final String? rejectLabel;
  final bool hideReject;
  final List<Widget> Function(BuildContext, Map<String, TextEditingController>)? extraFields;
  final Function(String comments, Map<String, String> extraValues) onApprove;
  final Function(String comments, Map<String, String> extraValues)? onReject;

  const _ActionCard({
    required this.title,
    this.approveLabel,
    this.rejectLabel,
    this.hideReject = false,
    this.extraFields,
    required this.onApprove,
    this.onReject,
  });

  @override
  State<_ActionCard> createState() => _ActionCardState();
}

class _ActionCardState extends State<_ActionCard> {
  final TextEditingController _commentController = TextEditingController();
  final Map<String, TextEditingController> _extraControllers = {};

  @override
  void dispose() {
    _commentController.dispose();
    for (var controller in _extraControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Map<String, String> _getExtraValues() {
    return _extraControllers.map((key, controller) => MapEntry(key, controller.text));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      color: AppTheme.primaryPink.withValues(alpha: 0.15),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppTheme.primaryPink),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (widget.extraFields != null) ...[
              ...widget.extraFields!(context, _extraControllers),
              const SizedBox(height: 16),
            ],
            TextField(
              controller: _commentController,
              decoration: InputDecoration(
                hintText: l10n.translate('addComments'),
                border: const OutlineInputBorder(),
                fillColor: Colors.white,
                filled: true,
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => widget.onApprove(_commentController.text, _getExtraValues()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(widget.approveLabel ?? l10n.translate('approve')),
                  ),
                ),
                if (!widget.hideReject) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (widget.onReject != null) {
                          widget.onReject!(_commentController.text, _getExtraValues());
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(widget.rejectLabel ?? l10n.translate('rejected')),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
