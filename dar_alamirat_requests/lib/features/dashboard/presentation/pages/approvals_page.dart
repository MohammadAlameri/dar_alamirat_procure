import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:dar_alamirat_requests/core/localization/app_localizations.dart';
import 'package:dar_alamirat_requests/features/auth/domain/entities/profile.dart';
import 'package:dar_alamirat_requests/features/purchase_request/domain/entities/purchase_request.dart';
import 'package:dar_alamirat_requests/features/expense_request/domain/entities/expense_request.dart';
import 'package:dar_alamirat_requests/core/widgets/custom_widgets.dart';
import '../cubit/approval_cubit.dart';

class ApprovalsPage extends StatelessWidget {
  final Profile profile;
  final String? branchId;

  const ApprovalsPage({
    super.key,
    required this.profile,
    this.branchId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ApprovalCubit()
        ..loadApprovals(
          profile: profile,
          branchId: branchId,
        ),
      child: ApprovalsView(
        profile: profile,
        branchId: branchId,
      ),
    );
  }
}

class ApprovalsView extends StatelessWidget {
  final Profile profile;
  final String? branchId;

  const ApprovalsView({
    super.key,
    required this.profile,
    this.branchId,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocBuilder<ApprovalCubit, ApprovalState>(
      builder: (context, state) {
        if (state is ApprovalLoading) {
          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 120),
                  itemCount: 6,
                  itemBuilder: (context, index) => const RequestCardShimmer(),
                ),
              ),
            ],
          );
        }

        if (state is ApprovalLoaded) {
          if (state.pendingRequests.isEmpty) {
            return Center(child: Text(l10n.translate('noPendingApprovals')));
          }

          return Column(
            children: [
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    context.read<ApprovalCubit>().loadApprovals(
                          profile: profile,
                          branchId: branchId,
                        );
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 120),
                    itemCount: state.pendingRequests.length,
                    itemBuilder: (context, index) {
                      final item = state.pendingRequests[index];
                      if (item is PurchaseRequest) {
                        return RequestCard(
                          subject: item.subject,
                          requester: item.profile?.fullName ?? l10n.translate('unknown'),
                          date: item.createdAt,
                          amount: item.totalAmount,
                          status: item.status,
                          type: 'procure',
                          onTap: () async {
                            await context.push('/request-details', extra: {
                              'requestId': item.id,
                              'type': 'procure',
                              'currentUser': profile,
                            });
                            if (context.mounted) {
                              context.read<ApprovalCubit>().loadApprovals(
                                profile: profile,
                                branchId: branchId,
                              );
                            }
                          },
                        );
                      } else {
                        final e = item as ExpenseRequest;
                        return RequestCard(
                          subject: e.subject,
                          requester: e.profile?.fullName ?? l10n.translate('unknown'),
                          date: e.createdAt,
                          amount: e.amount,
                          status: e.status,
                          type: 'expense',
                          onTap: () async {
                            await context.push('/request-details', extra: {
                              'requestId': e.id,
                              'type': 'expense',
                              'currentUser': profile,
                            });
                            if (context.mounted) {
                              context.read<ApprovalCubit>().loadApprovals(
                                profile: profile,
                                branchId: branchId,
                              );
                            }
                          },
                        );
                      }
                    },
                  ),
                ),
              ),
            ],
          );
        }

        if (state is ApprovalError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(LucideIcons.alertCircle, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(state.message),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    context.read<ApprovalCubit>().loadApprovals(
                          profile: profile,
                          branchId: branchId,
                        );
                  },
                  child: Text(l10n.translate('retry')),
                ),
              ],
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}
