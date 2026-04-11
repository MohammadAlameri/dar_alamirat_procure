import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/localization/app_localizations.dart';

class MaintenanceScreen extends StatelessWidget {
  final String? message;

  const MaintenanceScreen({
    super.key,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      backgroundColor: AppTheme.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Illustration / Icon
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.primaryPink.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.handyman_outlined,
                  size: 80,
                  color: AppTheme.primaryPink,
                ),
              ),
              const SizedBox(height: 32),
              
              // Title
              Text(
                isAr ? 'التطبيق تحت الصيانة' : 'App Under Maintenance',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.darkGray,
                ),
              ),
              const SizedBox(height: 16),
              
              // Message
              Text(
                message ?? (isAr 
                    ? 'نعمل حالياً على تحسين التطبيق لتقديم تجربة أفضل. يرجى المحاولة مرة أخرى لاحقاً.'
                    : 'We are currently improving the app to provide a better experience. Please try again later.'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 48),
              
              // Retry Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () {
                    context.go('/splash');
                  },
                  icon: const Icon(Icons.refresh),
                  label: Text(
                    l10n.translate('retry'),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
