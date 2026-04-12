import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
/* ... rest of imports ... */
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/custom_snackbar.dart';
import '../../../../core/di/injection_container.dart';
import '../../../dashboard/domain/repositories/dashboard_repository.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../main.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _rememberMe = false;

  Future<void> _chatWithAdmin() async {
    final Uri url = Uri.parse("https://wa.me/966551771975");
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        if (mounted) {
          AppSnackBar.show(context, 'Could not launch WhatsApp', type: SnackBarType.error);
        }
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.show(context, 'Error: $e', type: SnackBarType.error);
      }
    }
  }

  Future<void> _signIn() async {
/* ... existing _signIn code ... */
    final l10n = AppLocalizations.of(context)!;
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      AppSnackBar.show(
        context,
        l10n.translate('pleaseFillAllFields'),
        type: SnackBarType.error,
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      
      final user = response.user;
      if (user != null) {
        final repo = sl<DashboardRepository>();
        final profileResult = await repo.getProfile(user.id);
        
        bool hasAccess = await profileResult.fold(
          (failure) async => false,
          (profile) async {
            final branchesResult = await repo.getUserBranches(user.id, profile.role);
            return branchesResult.fold(
              (failure) => false,
              (branches) => branches.isNotEmpty,
            );
          },
        );

        if (!hasAccess) {
          await Supabase.instance.client.auth.signOut();
          if (mounted) {
            AppSnackBar.show(context, l10n.translate('accountInactive'), type: SnackBarType.error);
          }
          return;
        }
      }

      if (mounted) {
        // Save FCM token after successful login
        NotificationService().saveTokenToDatabase();
        context.go('/dashboard');
      }
    } on AuthException catch (e) {
      if (mounted) {
        String message = e.message;
        if (message.contains('Invalid login credentials')) {
          message = AppLocalizations.of(context)!.translate('invalidCredentials');
        }
        AppSnackBar.show(context, message, type: SnackBarType.error);
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.show(
          context,
          AppLocalizations.of(context)!.translate('unexpectedError'),
          type: SnackBarType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _toggleLanguage() {
    final currentLocale = Localizations.localeOf(context);
    final newLocale = currentLocale.languageCode == 'en' ? const Locale('ar') : const Locale('en');
    MyApp.setLocale(context, newLocale);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Language Switcher
                  Align(
                    alignment: isAr ? Alignment.centerLeft : Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: _toggleLanguage,
                      icon: const Icon(LucideIcons.languages, size: 18),
                      label: Text(isAr ? 'English' : 'العربية'),
                      style: TextButton.styleFrom(
                        side: const BorderSide(color: AppTheme.primaryPink),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Logo & Header
                  const Icon(LucideIcons.shoppingCart, size: 48, color: AppTheme.primaryPink),
                  const SizedBox(height: 16),
                  Text(
                    l10n.translate('title'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.primaryPink),
                  ),
                  Text(
                    l10n.translate('procurementSystem'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 32),
                  
                  // Login Form
                  Text(l10n.translate('emailAddress'), style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      hintText: l10n.translate('emailAddress'),
                      prefixIcon: const Icon(LucideIcons.mail, size: 20),
                      fillColor: Colors.grey[200],
                      filled: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  Text(l10n.translate('password'), style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      hintText: l10n.translate('password'),
                      prefixIcon: const Icon(LucideIcons.lock, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword ? LucideIcons.eye : LucideIcons.eyeOff, size: 20),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                      fillColor: Colors.grey[200],
                      filled: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  Row(
                    children: [
                      SizedBox(
                        height: 24,
                        width: 24,
                        child: Checkbox(
                          value: _rememberMe,
                          onChanged: (v) => setState(() => _rememberMe = v ?? false),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(l10n.translate('rememberMe')),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  ElevatedButton(
                    onPressed: _isLoading ? null : _signIn, 
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                      child: _isLoading 
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(l10n.translate('signIn')),
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  Text.rich(
                    TextSpan(
                      text: l10n.translate('noAccount'),
                      style: const TextStyle(color: Colors.black),
                      children: [
                        const TextSpan(text: ' '),
                        TextSpan(
                          text: l10n.translate('chatWithAdmin'),
                          style: const TextStyle(color: AppTheme.primaryPink, fontWeight: FontWeight.bold),
                          recognizer: TapGestureRecognizer()..onTap = _chatWithAdmin,
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

