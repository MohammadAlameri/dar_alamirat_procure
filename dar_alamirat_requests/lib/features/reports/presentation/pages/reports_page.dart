import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:dar_alamirat_requests/core/localization/app_localizations.dart';

class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _buildReportItem(
                context,
                l10n.translate('procurementSummary'),
                'Overview of all purchase requests and costs.',
                LucideIcons.fileText,
                Colors.blue,
              ),
              const SizedBox(height: 16),
              _buildReportItem(
                context,
                l10n.translate('expenseSummary'),
                'Overview of all expense requests and reimbursements.',
                LucideIcons.banknote,
                Colors.orange,
              ),
              const SizedBox(height: 16),
              _buildReportItem(
                context,
                l10n.translate('branchPerformance'),
                'Compare activity across different branches.',
                LucideIcons.building,
                Colors.green,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReportItem(BuildContext context, String title, String subtitle, IconData icon, Color color) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Text(subtitle),
        trailing: const Icon(LucideIcons.chevronRight),
        onTap: () {
          // TODO: Generate and show report
        },
      ),
    );
  }
}
