import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'firebase_options.dart';
import 'db/shopping_item.dart';
import 'db/shopping_list.dart';
import 'providers/shopping_provider.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'theme/app_theme.dart';
import 'ads/ad_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    FlutterError.onError = (errorDetails) {
      FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  } catch (_) {
    // Sin Firebase (tests, plataformas sin google-services):
    // la app sigue funcionando solo con almacenamiento local.
  }

  await Hive.initFlutter();
  Hive.registerAdapter(ShoppingItemAdapter());
  Hive.registerAdapter(ShoppingListAdapter());

  // No bloquea el arranque: los anuncios se cargan en segundo plano
  // tras el consentimiento UMP.
  AdManager().initialize().catchError((_) {});

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ShoppingProvider(),
      child: MaterialApp(
        title: 'La Compra',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: ThemeMode.system,
        initialRoute: '/',
        routes: {
          '/': (context) => _StartupScreen(),
          '/home': (context) => const HomeScreen(),
          '/onboarding': (context) => const OnboardingScreen(),
        },
      ),
    );
  }
}

class _StartupScreen extends StatefulWidget {
  @override
  _StartupScreenState createState() => _StartupScreenState();
}

class _StartupScreenState extends State<_StartupScreen> {
  @override
  void initState() {
    super.initState();
    _checkOnboarding();
  }

  Future<void> _checkOnboarding() async {
    final box = await Hive.openBox('settings');
    final seen = box.get('onboardingSeen', defaultValue: false) as bool;
    if (mounted) {
      Navigator.of(context).pushReplacementNamed(
        seen ? '/home' : '/onboarding',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
