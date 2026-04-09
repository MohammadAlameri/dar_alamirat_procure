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
                l10n.translate('procurementSummaryDesc'),
                LucideIcons.fileText,
                Colors.blue,
              ),
              const SizedBox(height: 16),
              _buildReportItem(
                context,
                l10n.translate('expenseSummary'),
                l10n.translate('expenseSummaryDesc'),
                LucideIcons.banknote,
                Colors.orange,
              ),
              const SizedBox(height: 16),
              _buildReportItem(
                context,
                l10n.translate('branchPerformance'),
                l10n.translate('branchPerformanceDesc'),
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
