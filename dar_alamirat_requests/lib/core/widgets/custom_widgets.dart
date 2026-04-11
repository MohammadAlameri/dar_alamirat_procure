import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shimmer/shimmer.dart';
import 'package:dar_alamirat_requests/core/localization/app_localizations.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  final double fontSize;

  const StatusBadge({
    super.key,
    required this.status,
    this.fontSize = 10,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    Color color = Colors.grey;
    String statusKey = status.toLowerCase();
    
    if (statusKey.contains('approved')) {
      color = Colors.green;
      statusKey = 'approved';
    } else if (statusKey.contains('rejected')) {
      color = Colors.red;
      statusKey = 'rejected';
    } else if (statusKey == 'pending') {
      color = Colors.orange;
    } else if (statusKey == 'completed' || statusKey == 'paid' || statusKey == 'received') {
      color = Colors.blue;
    } else if (statusKey == 'purchased') {
      color = Colors.deepPurple;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        l10n != null ? l10n.translate(statusKey).toUpperCase() : statusKey.toUpperCase(),
        style: TextStyle(color: color, fontSize: fontSize, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class RequestCard extends StatelessWidget {
  final String subject;
  final String requester;
  final DateTime date;
  final double amount;
  final String status;
  final String type; // 'procure' or 'expense'
  final VoidCallback onTap;

  const RequestCard({
    super.key,
    required this.subject,
    required this.requester,
    required this.date,
    required this.amount,
    required this.status,
    required this.type,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isProcure = type == 'procure';
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: isProcure ? Colors.blue.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
          child: Icon(
            isProcure ? LucideIcons.shoppingCart : LucideIcons.banknote,
            size: 20,
            color: isProcure ? Colors.blue : Colors.orange,
          ),
        ),
        title: Text(
          subject,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '$requester • ${DateFormat('MMM dd, yyyy').format(date)}',
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 6),
            StatusBadge(status: status),
          ],
        ),
        trailing: Text(
          '${amount.toStringAsFixed(2)} ${AppLocalizations.of(context)?.translate('sar') ?? 'SAR'}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        onTap: onTap,
      ),
    );
  }
}

class RequestCardShimmer extends StatelessWidget {
  const RequestCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: const CircleAvatar(
            backgroundColor: Colors.white,
          ),
          title: Container(
            height: 14,
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Container(
                height: 12,
                width: 150,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 20,
                width: 80,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ],
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                height: 14,
                width: 60,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 16,
                width: 16,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
