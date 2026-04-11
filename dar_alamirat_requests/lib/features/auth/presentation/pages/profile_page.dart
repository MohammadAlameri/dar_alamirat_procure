import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:dar_alamirat_requests/core/theme/app_theme.dart';
import 'package:dar_alamirat_requests/features/auth/domain/entities/profile.dart';
import 'package:dar_alamirat_requests/core/localization/app_localizations.dart';

class ProfilePage extends StatelessWidget {
  final Profile profile;

  const ProfilePage({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Center(
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: AppTheme.primaryPink.withValues(alpha: 0.1),
                  child: const Icon(LucideIcons.user, size: 50, color: AppTheme.primaryPink),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppTheme.primaryPink,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(LucideIcons.camera, size: 14, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            profile.fullName,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          Text(
            profile.email,
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 32),
          _buildInfoSection(context, l10n),
        ],
      ),
    );
  }

  Widget _buildInfoSection(BuildContext context, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildInfoItem(LucideIcons.briefcase, l10n.translate('jobTitle'), profile.jobTitle ?? l10n.translate('notAssigned')),
          const Divider(height: 32),
          _buildInfoItem(LucideIcons.building, l10n.translate('department'), profile.department ?? l10n.translate('notAssigned')),
          const Divider(height: 32),
          _buildInfoItem(LucideIcons.shieldCheck, l10n.translate('role'), l10n.translate(profile.role.name)),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryPink.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: AppTheme.primaryPink),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ],
    );
  }
}
