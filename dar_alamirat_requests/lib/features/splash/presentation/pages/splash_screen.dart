import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/models/app_config.dart';
import '../../../../core/theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAppConfiguration();
  }

  Future<void> _checkAppConfiguration() async {
    try {
      // 1. Fetch Configuration from Supabase
      final response = await Supabase.instance.client
          .from(AppConstants.configurationsTable)
          .select()
          .single();
      
      final config = AppConfig.fromJson(response);

      // 2. Check Maintenance Mode
      if (config.maintenanceMode) {
        if (mounted) {
          final isAr = Localizations.localeOf(context).languageCode == 'ar';
          context.go('/maintenance', extra: isAr ? config.maintenanceMessageAr : config.maintenanceMessageEn);
        }
        return;
      }

      // 3. Check for Updates
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      final serverVersion = Platform.isAndroid ? config.androidVersion : config.iosVersion;
      final storeUrl = Platform.isAndroid ? config.androidStoreUrl : config.iosStoreUrl;

      if (serverVersion != null && _isUpdateAvailable(currentVersion, serverVersion)) {
        if (mounted) {
          context.go('/update', extra: {
            'storeUrl': storeUrl ?? '',
            'forceUpdate': config.forceUpdate,
          });
        }
        return;
      }

      // 4. No maintenance or update, proceed to landing
      if (mounted) {
        context.go('/login'); // Redirect to login, router will handle if already logged in
      }
    } catch (e) {
      debugPrint('Error checking configuration: $e');
      // If error, proceed normally or show error
      if (mounted) {
        context.go('/login');
      }
    }
  }

  bool _isUpdateAvailable(String currentVersion, String serverVersion) {
    try {
      final currentParts = currentVersion.split('.').map(int.parse).toList();
      final serverParts = serverVersion.split('.').map(int.parse).toList();

      for (int i = 0; i < serverParts.length; i++) {
        if (i >= currentParts.length) return true;
        if (serverParts[i] > currentParts[i]) return true;
        if (serverParts[i] < currentParts[i]) return false;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
             Image.asset(
              'assets/images/app_icon.jpg',
              width: 120,
              height: 120,
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(
              color: AppTheme.primaryPink,
            ),
          ],
        ),
      ),
    );
  }
}
