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
import 'screens/shopping_list_screen.dart';
import 'screens/onboarding_screen.dart';
import 'widgets/add_item_dialog.dart';
import 'ads/ad_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint('🔥 main: WidgetsFlutterBinding initialized');

  try {
    debugPrint('🔥 main: initializing Firebase...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('🔥 main: Firebase initialized');

    FlutterError.onError = (errorDetails) {
      FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  } catch (e) {
    debugPrint('🔥 main: Firebase initialization failed: $e');
  }

  debugPrint('🔥 main: initializing Hive...');
  await Hive.initFlutter();
  Hive.registerAdapter(ShoppingItemAdapter());
  Hive.registerAdapter(ShoppingListAdapter());
  debugPrint('🔥 main: Hive ready');

  debugPrint('🔥 main: firing AdManager().initialize() (non-blocking)...');
  AdManager().initialize().catchError((e) {
    debugPrint('🔥 main: Ad initialization error: $e');
  });

  debugPrint('🔥 main: calling runApp()...');
  runApp(MyApp());
  debugPrint('🔥 main: runApp() called — UI should be visible now');
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
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF4BDB88),
            brightness: Brightness.light,
            primary: const Color(0xFF4BDB88),
            secondary: const Color(0xFF6C3FA0),
            surface: Colors.white,
            onSurface: const Color(0xFF1B1B1B),
          ),
          scaffoldBackgroundColor: const Color(0xFFF5F7F5),
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            elevation: 0,
            scrolledUnderElevation: 2,
            backgroundColor: Color(0xFFF5F7F5),
            foregroundColor: Color(0xFF1B1B1B),
            titleTextStyle: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1B1B1B),
            ),
          ),
          cardTheme: CardThemeData(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            color: Colors.white,
          ),
          floatingActionButtonTheme: const FloatingActionButtonThemeData(
            backgroundColor: Color(0xFF4BDB88),
            foregroundColor: Colors.white,
            elevation: 4,
            shape: CircleBorder(),
          ),
          bottomNavigationBarTheme: BottomNavigationBarThemeData(
            backgroundColor: Colors.white,
            selectedItemColor: const Color(0xFF4BDB88),
            unselectedItemColor: Colors.grey.shade500,
            type: BottomNavigationBarType.fixed,
            elevation: 8,
            selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4BDB88),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF4BDB88),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF4BDB88), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
          checkboxTheme: CheckboxThemeData(
            fillColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return const Color(0xFF4BDB88);
              }
              return Colors.grey.shade400;
            }),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          dialogTheme: DialogThemeData(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 8,
          ),
          snackBarTheme: SnackBarThemeData(
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => _StartupScreen(),
          '/home': (context) => const HomeScreen(),
          '/onboarding': (context) => const OnboardingScreen(),
          '/shopping': (context) => Scaffold(
            backgroundColor: const Color(0xFFF5F7F5),
            appBar: AppBar(
              title: Consumer<ShoppingProvider>(
                builder: (context, provider, _) => Text(
                  provider.currentList?.name ?? 'Lista de compras',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              actions: [
                Consumer<ShoppingProvider>(
                  builder: (context, provider, _) {
                    if (provider.currentList == null) return Container();
                    return IconButton(
                      icon: const Icon(Icons.check_circle_outline),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Completar Compra'),
                            content: const Text(
                              '¿Has terminado de hacer las compras? Esto moverá la lista al historial.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(ctx).pop(),
                                child: const Text('Cancelar'),
                              ),
                              TextButton(
                                onPressed: () {
                                  provider.completeShoppingList();
                                  Navigator.of(ctx).pop();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('¡Compra completada!'),
                                      behavior: SnackBarBehavior.fixed,
                                    ),
                                  );
                                },
                                child: const Text(
                                  'Completar',
                                  style: TextStyle(color: Colors.green),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      tooltip: 'Completar compra',
                    );
                  },
                ),
              ],
            ),
            body: ShoppingListScreen(),
            floatingActionButton: Consumer<ShoppingProvider>(
              builder: (context, provider, _) {
                if (provider.currentList == null) return Container();
                return FloatingActionButton(
                  onPressed: () => showDialog(
                    context: context,
                    builder: (context) => AddItemDialog(),
                  ),
                  child: const Icon(Icons.add),
                );
              },
            ),
          ),
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
