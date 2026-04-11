import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dar_alamirat_requests/core/localization/app_localizations.dart';
import 'package:dar_alamirat_requests/features/auth/domain/entities/profile.dart';
import 'package:dar_alamirat_requests/features/management/domain/entities/branch.dart';
import 'package:dar_alamirat_requests/core/widgets/custom_widgets.dart';
import 'package:dar_alamirat_requests/core/theme/app_theme.dart';
import 'package:dar_alamirat_requests/core/di/injection_container.dart';
import '../cubit/purchase_request_cubit.dart';

class PurchaseRequestsPage extends StatelessWidget {
  final Profile profile;
  final Branch? initialBranch;

  const PurchaseRequestsPage({
    super.key,
    required this.profile,
    this.initialBranch,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<PurchaseRequestCubit>()
        ..loadRequests(
          profile: profile,
          branchId: initialBranch?.id,
        ),
      child: PurchaseRequestsView(
        profile: profile,
        initialBranch: initialBranch,
      ),
    );
  }
}

class PurchaseRequestsView extends StatefulWidget {
  final Profile profile;
  final Branch? initialBranch;

  const PurchaseRequestsView({
    super.key,
    required this.profile,
    this.initialBranch,
  });

  @override
  State<PurchaseRequestsView> createState() => _PurchaseRequestsViewState();
}

class _PurchaseRequestsViewState extends State<PurchaseRequestsView> with AutomaticKeepAliveClientMixin {
  String _selectedStatus = 'all';
  Branch? _selectedBranch;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _selectedBranch = widget.initialBranch;
  }

  @override
  void didUpdateWidget(PurchaseRequestsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialBranch?.id != oldWidget.initialBranch?.id) {
      setState(() {
        _selectedBranch = widget.initialBranch;
      });
      _fetchRequests();
    }
  }

  void _fetchRequests() {
    context.read<PurchaseRequestCubit>().loadRequests(
          profile: widget.profile,
          branchId: _selectedBranch?.id,
          status: _selectedStatus,
        );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFilterList(l10n),
        Expanded(
          child: BlocBuilder<PurchaseRequestCubit, PurchaseRequestState>(
            builder: (context, state) {
              if (state is PurchaseRequestLoading) {
                return ListView.builder(
                  padding: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 120),
                  itemCount: 6,
                  itemBuilder: (context, index) => const RequestCardShimmer(),
                );
              }

              if (state is PurchaseRequestLoaded) {
                if (state.requests.isEmpty) {
                  return ListView(
                    padding: const EdgeInsets.only(bottom: 120),
                    children: [
                      SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                      Center(child: Text(l10n.translate('noRequestsFound'))),
                    ],
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async => _fetchRequests(),
                  child: ListView.builder(
                    padding: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 120),
                    itemCount: state.requests.length,
                    itemBuilder: (context, index) {
                      final request = state.requests[index];
                      return RequestCard(
                        subject: request.subject,
                        requester: request.profile?.fullName ?? l10n.translate('unknown'),
                        date: request.createdAt,
                        amount: request.totalAmount,
                        status: request.status,
                        type: 'procure',
                        onTap: () {
                          context.push('/request-details', extra: {
                            'requestId': request.id,
                            'type': 'procure',
                            'currentUser': widget.profile,
                          });
                        },
                      );
                    },
                  ),
                );
              }

              if (state is PurchaseRequestError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(l10n.translate('errorLoadingRequests')),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _fetchRequests,
                        child: Text(l10n.translate('retry')),
                      ),
                    ],
                  ),
                );
              }

              return const SizedBox.shrink();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilterList(AppLocalizations l10n) {
    final statuses = ['all', 'pending', 'manager_approved', 'completed', 'rejected'];
    return Container(
      height: 48,
      margin: const EdgeInsets.only(bottom: 12, top: 4),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: statuses.length,
        separatorBuilder: (context, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final status = statuses[index];
          final isSelected = _selectedStatus == status;
          return ChoiceChip(
            label: Text(
              _getStatusLabel(status, l10n),
              style: TextStyle(
                color: isSelected ? Colors.white : AppTheme.darkGray,
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
            selected: isSelected,
            showCheckmark: false,
            selectedColor: AppTheme.primaryPink,
            backgroundColor: Colors.white,
            side: BorderSide(color: isSelected ? AppTheme.primaryPink : Colors.grey.shade300),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            onSelected: (selected) {
              if (selected) {
                setState(() {
                  _selectedStatus = status;
                });
                _fetchRequests();
              }
            },
          );
        },
      ),
    );
  }

  String _getStatusLabel(String status, AppLocalizations l10n) {
    switch (status) {
      case 'all': return l10n.translate('all');
      case 'pending': return l10n.translate('pending');
      case 'manager_approved': return l10n.translate('manager_approved');
      case 'completed': return l10n.translate('completed');
      case 'rejected': return l10n.translate('rejected');
      default: return status.replaceAll('_', ' ').replaceFirst(status[0], status[0].toUpperCase());
    }
  }
}
