import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/localization/app_localizations.dart';

class UpdateScreen extends StatelessWidget {
  final String storeUrl;
  final bool forceUpdate;

  const UpdateScreen({
    super.key,
    required this.storeUrl,
    required this.forceUpdate,
  });

  Future<void> _launchStore() async {
    if (storeUrl.isEmpty) return;
    final Uri url = Uri.parse(storeUrl);
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        debugPrint('Could not launch $url');
      }
    } catch (e) {
      debugPrint('Error launching URL: $e');
    }
  }

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
              const Spacer(),
              
              // Illustration / Icon
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.primaryPink.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.rocket_launch_rounded,
                  size: 80,
                  color: AppTheme.primaryPink,
                ),
              ),
              const SizedBox(height: 32),
              
              // Title
              Text(
                isAr ? 'تحديث جديد متوفر!' : 'New Update Available!',
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
                isAr 
                    ? 'يرجى تحديث التطبيق للحصول على آخر المميزات والتحسينات ولضمان أفضل تجربة استخدام.'
                    : 'Please update the app to get the latest features and improvements and ensure the best experience.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                  height: 1.5,
                ),
              ),
              
              const Spacer(),
              
              // Update Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _launchStore,
                  child: Text(
                    isAr ? 'تحديث الآن' : 'Update Now',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              
              // Skip Button (Only if not forced)
              if (!forceUpdate) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: TextButton(
                    onPressed: () {
                      context.go('/login');
                    },
                    child: Text(
                      isAr ? 'تخطي التحديث حالياً' : 'Skip For Now',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
