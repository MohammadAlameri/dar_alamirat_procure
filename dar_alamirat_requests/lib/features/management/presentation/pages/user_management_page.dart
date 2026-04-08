import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:dar_alamirat_requests/core/localization/app_localizations.dart';
import 'package:dar_alamirat_requests/core/theme/app_theme.dart';
import 'package:dar_alamirat_requests/features/auth/domain/entities/profile.dart';
import 'package:dar_alamirat_requests/features/management/data/repositories/user_repository.dart';
import '../cubits/user_cubit.dart';

class UserManagementPage extends StatelessWidget {
  const UserManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => UserCubit(UserRepository())..loadUsers(),
      child: const UserManagementView(),
    );
  }
}

class UserManagementView extends StatelessWidget {
  const UserManagementView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Stack(
      children: [
        BlocBuilder<UserCubit, UserState>(
          builder: (context, state) {
            if (state is UserLoading) {
              return Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 120),
                      children: const [
                        UserCardShimmer(),
                        UserCardShimmer(),
                        UserCardShimmer(),
                      ],
                    ),
                  ),
                ],
              );
            }

            if (state is UserLoaded) {
              if (state.users.isEmpty) {
                return Center(child: Text(l10n.translate('noUsersFound')));
              }

              return Column(
                children: [
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () => context.read<UserCubit>().loadUsers(),
                      child: ListView.builder(
                        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 120),
                        itemCount: state.users.length,
                        itemBuilder: (context, index) {
                          final profile = state.users[index];
                          return UserCard(
                            profile: profile,
                            onTap: () {
                              // TODO: Show user details
                            },
                            onEdit: () {
                              // TODO: Edit user profile
                            },
                          );
                        },
                      ),
                    ),
                  ),
                ],
              );
            }

            if (state is UserError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(LucideIcons.alertCircle, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(state.message),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => context.read<UserCubit>().loadUsers(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            return const SizedBox.shrink();
          },
        ),
        Positioned(
          bottom: 100,
          right: 20,
          child: FloatingActionButton(
            onPressed: () {
              // TODO: Show create user dialog
            },
            backgroundColor: AppTheme.primaryPink,
            child: const Icon(LucideIcons.userPlus, color: AppTheme.darkGray),
          ),
        ),
      ],
    );
  }
}

class UserCard extends StatelessWidget {
  final Profile profile;
  final VoidCallback onTap;
  final VoidCallback onEdit;

  const UserCard({
    super.key,
    required this.profile,
    required this.onTap,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.primaryPink.withOpacity(0.1),
          child: Text(
            profile.fullName.substring(0, 1).toUpperCase(),
            style: const TextStyle(color: AppTheme.primaryPink, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(profile.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('${profile.email}\nRole: ${profile.role.name.toUpperCase()}'),
        isThreeLine: true,
        trailing: IconButton(
          icon: const Icon(LucideIcons.edit2, size: 18),
          onPressed: onEdit,
        ),
        onTap: onTap,
      ),
    );
  }
}

class UserCardShimmer extends StatelessWidget {
  const UserCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: const ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: Colors.grey,
        ),
        title: SizedBox(
          height: 14,
          width: double.infinity,
          child: ColoredBox(color: Colors.grey),
        ),
        subtitle: SizedBox(
          height: 24,
          width: 150,
          child: ColoredBox(color: Colors.grey),
        ),
        trailing: SizedBox(
          height: 18,
          width: 18,
          child: ColoredBox(color: Colors.grey),
        ),
        isThreeLine: true,
      ),
    );
  }
}
