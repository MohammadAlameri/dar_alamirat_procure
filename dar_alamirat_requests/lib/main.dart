import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'core/theme/app_theme.dart';
import 'core/localization/app_localizations.dart';
import 'core/constants/app_constants.dart';
import 'core/services/language_service.dart';
import 'core/services/notification_service.dart';
import 'core/navigation/app_router.dart';
import 'core/di/injection_container.dart' as di;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load .env file
  await dotenv.load(fileName: ".env");
  
  // Disable runtime fetching to fix SocketException when offline
  GoogleFonts.config.allowRuntimeFetching = false;

  // Initialize Firebase
  await Firebase.initializeApp();

  // Register background message handler
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  
  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
  );

  await di.init();

  // Initialize notification service
  final notificationService = NotificationService();
  await notificationService.initialize();

  // Set up notification tap handler for navigation
  notificationService.onNotificationTap = (requestId, requestType) {
    if (requestId != null && requestId.isNotEmpty) {
      // Navigate to request details when notification is tapped
      final context = AppRouter.router.routerDelegate.navigatorKey.currentContext;
      if (context != null) {
        AppRouter.router.push('/request-details', extra: {
          'requestId': requestId,
          'type': requestType ?? 'purchase',
        });
      }
    }
  };

  // Load saved locale
  final Locale savedLocale = await LanguageService.getLocale();

  runApp(MyApp(savedLocale: savedLocale));
}

class MyApp extends StatefulWidget {
  final Locale savedLocale;
  const MyApp({super.key, required this.savedLocale});

  static void setLocale(BuildContext context, Locale newLocale) {
    _MyAppState? state = context.findAncestorStateOfType<_MyAppState>();
    state?.setLocale(newLocale);
  }

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late Locale _locale;

  @override
  void initState() {
    super.initState();
    _locale = widget.savedLocale;
  }

  void setLocale(Locale locale) {
    setState(() {
      _locale = locale;
    });
    // Save language code
    LanguageService.saveLanguage(locale.languageCode);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Dar Alamirat Procurement',
      routerConfig: AppRouter.router,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      locale: _locale,
      supportedLocales: const [
        Locale('en', ''),
        Locale('ar', ''),
      ],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
