import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:totsy/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:io';
import 'dart:math';
import 'dart:async';
import 'package:totsy/routes/app.dart';
import 'package:totsy/routes/onboarding.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Lock orientation to portrait only
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Hide system UI (status bar, navigation bar)
  await SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.immersiveSticky,
    overlays: [],
  );

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize user ID
  await initializeUserId();

  // Initialize RevenueCat
  await initializeRevenueCat();

  runApp(const MyApp());
}

// Initialize RevenueCat with API keys
Future<void> initializeRevenueCat() async {
  try {
    // Set log level for debugging (remove in production)
    if (kDebugMode) {
      await Purchases.setLogLevel(LogLevel.debug);
    }
    
    // Get user ID first
    String userId = await getCurrentUserId();
    
    // Replace with your actual RevenueCat API keys
    if (Platform.isAndroid) {
      // Get this from RevenueCat Dashboard -> Project Settings -> API Keys -> Google Play
      await Purchases.configure(
        PurchasesConfiguration("goog_your_google_play_api_key_here")
          ..appUserID = userId.isNotEmpty ? userId : null,
      );
    } else if (Platform.isIOS) {
      // Get this from RevenueCat Dashboard -> Project Settings -> API Keys -> App Store
      await Purchases.configure(
        PurchasesConfiguration("appl_YBeVIonpuhySbgozwVJCoxpftwQ")
          ..appUserID = userId.isNotEmpty ? userId : null,
      );
    } else {
      throw UnsupportedError("Platform not supported for RevenueCat");
    }
    
    if (kDebugMode) {
      print("RevenueCat configured successfully with user ID: $userId");
    }
  } catch (e) {
    if (kDebugMode) {
      print("Error configuring RevenueCat: $e");
    }
    // Don't throw here - let the app continue even if RevenueCat fails
  }
}

// Generate and store unique user ID on first launch
Future<void> initializeUserId() async {
  const String userIdKey = 'user_id';
  final prefs = await SharedPreferences.getInstance();
  
  String? userId = prefs.getString(userIdKey);
  
  if (userId == null) {
    userId = generateUserId();
    await prefs.setString(userIdKey, userId);
    if (kDebugMode) {
      print('Generated new user ID: $userId');
    }
  } else {
    if (kDebugMode) {
      print('Existing user ID: $userId');
    }
  }
}

// Generate unique user ID
String generateUserId() {
  const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
  final random = Random();
  return List.generate(16, (index) => chars[random.nextInt(chars.length)]).join();
}

// Helper function to get current user ID
Future<String> getCurrentUserId() async {
  const String userIdKey = 'user_id';
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString(userIdKey) ?? '';
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp( 
      title: 'Totsy',
      theme: ThemeData(
        progressIndicatorTheme: ProgressIndicatorThemeData(color: Colors.black),
      ),
      debugShowCheckedModeBanner: false,
      home: const AppInitializer(),
    );
  }
}

class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  String _initializationStatus = 'Loading...';
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _determineInitialRoute();
  }

  Future<void> _determineInitialRoute() async {
    try {
      setState(() {
        _initializationStatus = 'Setting up your experience...';
      });

      // Small delay for smooth UX
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Check SharedPreferences first
      final prefs = await SharedPreferences.getInstance();
      final bool hasCompletedOnboarding = prefs.getBool('has_completed_onboarding') ?? false;
      final bool isPaidUser = prefs.getBool('paid_user') ?? false;
      final bool subscriptionActive = prefs.getBool('subscription_active') ?? false;
      
      if (kDebugMode) {
        print('Onboarding completed: $hasCompletedOnboarding');
        print('Paid user: $isPaidUser');
        print('Subscription active: $subscriptionActive');
      }

      // Also check RevenueCat subscription status for the most up-to-date info
      bool hasActiveSubscription = false;
      try {
        setState(() {
          _initializationStatus = 'Checking subscription status...';
        });
        
        final customerInfo = await Purchases.getCustomerInfo();
        hasActiveSubscription = customerInfo.entitlements.active.isNotEmpty;
        
        if (kDebugMode) {
          print('RevenueCat active subscriptions: ${customerInfo.entitlements.active.keys}');
        }
        
        // Update local storage if RevenueCat shows active subscription but local doesn't
        if (hasActiveSubscription && !isPaidUser) {
          await prefs.setBool('paid_user', true);
          await prefs.setBool('subscription_active', true);
          await prefs.setBool('has_completed_onboarding', true);
          if (kDebugMode) {
            print('Updated local storage: user has active RevenueCat subscription');
          }
        }
        // Update local storage if RevenueCat shows no subscription but local shows active
        else if (!hasActiveSubscription && isPaidUser) {
          await prefs.setBool('paid_user', false);
          await prefs.setBool('subscription_active', false);
          if (kDebugMode) {
            print('Updated local storage: user has no active RevenueCat subscription');
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error checking RevenueCat subscription: $e');
        }
        // Fall back to local storage values if RevenueCat check fails
        hasActiveSubscription = isPaidUser || subscriptionActive;
      }

      // Determine the final status
      final bool finalIsPaidUser = hasActiveSubscription || isPaidUser || subscriptionActive;
      final bool shouldGoToApp = hasCompletedOnboarding && finalIsPaidUser;

      if (kDebugMode) {
        print('Final routing decision:');
        print('  - Onboarding completed: $hasCompletedOnboarding');
        print('  - Is paid user: $finalIsPaidUser');
        print('  - Should go to app: $shouldGoToApp');
      }

      if (shouldGoToApp) {
        setState(() {
          _initializationStatus = 'Welcome back!';
        });
        
        await Future.delayed(const Duration(milliseconds: 300));
        _navigateToApp();
      } else {
        setState(() {
          _initializationStatus = 'Let\'s get started...';
        });
        
        await Future.delayed(const Duration(milliseconds: 300));
        _navigateToOnboarding();
      }
      
    } catch (e) {
      if (kDebugMode) {
        print('Error during app initialization: $e');
      }
      
      setState(() {
        _hasError = true;
        _initializationStatus = 'Something went wrong. Retrying...';
      });
      
      // Wait a bit then try again or fallback to onboarding
      await Future.delayed(const Duration(seconds: 2));
      _navigateToOnboarding();
    }
  }

  void _navigateToApp() {
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => AppFlow()),
      );
    }
  }

  void _navigateToOnboarding() {
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const OnboardingFlow()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromRGBO(243, 243, 243, 1), // Match your app's theme
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App logo or title
            Image.asset('assets/logo_transparent.png', height: 60),
            const SizedBox(height: 60),
            
            // Loading indicator (show error color if there's an error)
            CircularProgressIndicator(
              color: Color.fromRGBO(63, 114, 66, 1),
              strokeWidth: 2,
            ),
            const SizedBox(height: 24),
            
            // Status text
            Text(
              _initializationStatus,
              style: TextStyle(
                fontSize: 16,
                color: Color.fromRGBO(63, 114, 66, 1),
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 12),
            
            // Subtitle
            Text(
              _hasError 
                ? 'Please check your internet connection'
                : 'Please wait while we set things up',
              style: TextStyle(
                fontSize: 14,
                color: _hasError ? Colors.red[200] : Color.fromRGBO(63, 44, 43, 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            
            // Show retry option if there's an error
            if (_hasError) ...[
              const SizedBox(height: 32),
              TextButton(
                onPressed: () {
                  setState(() {
                    _hasError = false;
                    _initializationStatus = 'Retrying...';
                  });
                  _determineInitialRoute();
                },
                child: Text(
                  'Tap to retry',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color.fromRGBO(63, 44, 43, 1),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}