import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:dar_alamirat_requests/core/localization/app_localizations.dart';
import 'package:dar_alamirat_requests/core/theme/app_theme.dart';

class FloatingBottomNavbar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;
  final bool isManager;
  final VoidCallback onMenuTap;

  const FloatingBottomNavbar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.isManager,
    required this.onMenuTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      height: 70,
      decoration: BoxDecoration(
        color: AppTheme.primaryPink,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryPink.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavIcon(0, LucideIcons.layoutDashboard, l10n.translate('dashboard')),
          _buildNavIcon(1, LucideIcons.fileText, l10n.translate('myRequests')),
          _buildNavIcon(2, LucideIcons.banknote, l10n.translate('expenseRequests')),
          if (isManager) _buildNavIcon(3, LucideIcons.checkSquare, l10n.translate('approvals')),
          _buildNavIcon(99, LucideIcons.menu, l10n.translate('menu'), onTap: onMenuTap),
        ],
      ),
    );
  }

  Widget _buildNavIcon(int index, IconData icon, String label, {VoidCallback? onTap}) {
    final isSelected = selectedIndex == index;
    return InkWell(
      onTap: onTap ?? () => onItemSelected(index),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: isSelected ? AppTheme.darkGray : Colors.black54,
            size: isSelected ? 24 : 22,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? AppTheme.darkGray : Colors.black54,
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
