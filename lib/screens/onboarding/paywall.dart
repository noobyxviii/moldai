import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:moldai/routes/app.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';

// Add this service class if you don't have it already
class PurchaseService {
  static final PurchaseService _instance = PurchaseService._internal();
  factory PurchaseService() => _instance;
  PurchaseService._internal();

  final _purchaseStatusController = StreamController<bool>.broadcast();
  Stream<bool> get purchaseStatusStream => _purchaseStatusController.stream;

  void updatePurchaseStatus(bool isPaidUser) {
    _purchaseStatusController.add(isPaidUser);
  }

  void dispose() {
    _purchaseStatusController.close();
  }
}

// Remote Config Service
class RemoteConfigService {
  static final RemoteConfigService _instance = RemoteConfigService._internal();
  factory RemoteConfigService() => _instance;
  RemoteConfigService._internal();

  FirebaseRemoteConfig? _remoteConfig;
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _remoteConfig = FirebaseRemoteConfig.instance;
      
      // Set configuration settings
      await _remoteConfig!.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(minutes: 1),
        minimumFetchInterval: const Duration(hours: 1), // Adjust as needed
      ));

      // Set default values
      await _remoteConfig!.setDefaults(<String, dynamic>{
        'free_trial_enabled': true, // Default to enabled
      });

      // Fetch and activate
      await _remoteConfig!.fetchAndActivate();
      
      _isInitialized = true;
      debugPrint('Remote Config initialized successfully');
    } catch (e) {
      debugPrint('Failed to initialize Remote Config: $e');
      _isInitialized = false;
    }
  }

  bool get isFreeTrialEnabled {
    if (!_isInitialized || _remoteConfig == null) {
      return true; // Default fallback
    }
    return _remoteConfig!.getBool('free_trial_enabled');
  }

  Future<void> refresh() async {
    if (!_isInitialized || _remoteConfig == null) return;
    
    try {
      await _remoteConfig!.fetchAndActivate();
      debugPrint('Remote Config refreshed');
    } catch (e) {
      debugPrint('Failed to refresh Remote Config: $e');
    }
  }
}

class PaywallScreen extends StatefulWidget {
  final PageController controller;
  final int pageIndex;
  const PaywallScreen({
    super.key,
    required this.controller,
    required this.pageIndex,
  });

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  bool isWeeklySelected = true; // Weekly plan selected by default
  bool isFreeTrialEnabled = true; // Free trial enabled by default (local state)
  bool _remoteConfigFreeTrialEnabled = true; // Remote config state

  // RevenueCat specific variables
  Offerings? _offerings;
  List<Package> _packages = [];
  bool _isLoading = true;
  bool _isPurchasePending = false;
  bool _isRestoringPurchases = false;

  final RemoteConfigService _remoteConfigService = RemoteConfigService();

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    if (!Platform.isIOS && !Platform.isAndroid) {
      debugPrint('RevenueCat only supports iOS and Android');
      setState(() {
        _isLoading = false;
      });
      return;
    }

    // Initialize Remote Config first
    await _initializeRemoteConfig();
    
    await _loadOfferings();
    await _checkSubscriptionStatus();
  }

  Future<void> _initializeRemoteConfig() async {
    try {
      await _remoteConfigService.initialize();
      
      setState(() {
        _remoteConfigFreeTrialEnabled = _remoteConfigService.isFreeTrialEnabled;
        // If remote config disables free trial, switch to yearly and disable local toggle
        if (!_remoteConfigFreeTrialEnabled) {
          isFreeTrialEnabled = false;
          isWeeklySelected = false; // Switch to yearly when free trial is disabled
        } else {
          isFreeTrialEnabled = true;
          isWeeklySelected = true; // Default to weekly when free trial is available
        }
      });
      
      debugPrint('Remote Config free trial enabled: $_remoteConfigFreeTrialEnabled');
    } catch (e) {
      debugPrint('Error initializing Remote Config: $e - Defaulting to free trial enabled');
      // Fallback to default behavior with free trial enabled
      if (!mounted) return;
      setState(() {
        _remoteConfigFreeTrialEnabled = true;
        isFreeTrialEnabled = true;
        isWeeklySelected = true; // Default to weekly with free trial
      });
    }
  }

  Future<void> _loadOfferings() async {
    try {
      final offerings = await Purchases.getOfferings();

      if (offerings.current != null) {
        setState(() {
          _offerings = offerings;
          _packages = offerings.current!.availablePackages;
          _isLoading = false;
        });
        debugPrint('Loaded offering with ${_packages.length} packages');

        // Set up listener for purchase updates
        Purchases.addCustomerInfoUpdateListener(_onCustomerInfoUpdate);
      } else {
        debugPrint('No current offering found');
        setState(() {
          _isLoading = false;
        });
        _showError('Subscription plans not available');
      }
    } catch (e) {
      debugPrint('Error loading offerings: $e');
      setState(() {
        _isLoading = false;
      });
      _showError('Failed to load subscription plans');
    }
  }

  Future<void> _checkSubscriptionStatus() async {
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      final bool hasActiveSubscription =
          customerInfo.entitlements.active.isNotEmpty;

      if (hasActiveSubscription) {
        debugPrint('User has active subscription');
        await _updateUserStatus(true);
        _navigateToNextPage();
        return;
      }

      debugPrint('User does not have active subscription');
    } catch (e) {
      debugPrint('Error checking subscription status: $e');
    }
  }

  void _onCustomerInfoUpdate(CustomerInfo customerInfo) {
    final bool hasActiveSubscription =
        customerInfo.entitlements.active.isNotEmpty;

    if (hasActiveSubscription) {
      debugPrint('Subscription activated');
      _updateUserStatus(true);
      Future.delayed(const Duration(milliseconds: 2000), () {
        _navigateToNextPage();
      });
    }
  }

  Package? _getWeeklyPackage() {
    try {
      // Use the appropriate weekly package based on free trial settings
      String targetIdentifier;
      if (_remoteConfigFreeTrialEnabled) {
        targetIdentifier = '\$rc_weekly_free_trial'; // With free trial
      } else {
        targetIdentifier = '\$rc_weekly'; // Without free trial
      }
      
      return _packages.firstWhere(
        (package) => package.identifier == targetIdentifier,
        orElse: () {
          // Fallback to $rc_weekly (with free trial) if specific package not found
          try {
            return _packages.firstWhere(
              (package) => package.identifier == '\$rc_weekly',
            );
          } catch (e) {
            // Final fallback to any weekly package
            return _packages.firstWhere(
              (package) =>
                  package.identifier.contains('weekly') ||
                  package.packageType == PackageType.weekly,
            );
          }
        },
      );
    } catch (e) {
      debugPrint('Weekly package not found: $e');
      return null;
    }
  }

  Package? _getYearlyPackage() {
    try {
      return _packages.firstWhere(
        (package) => package.identifier == '\$rc_annual',
        orElse: () {
          // Fallback to any annual package
          return _packages.firstWhere(
            (package) =>
                package.identifier.contains('annual') ||
                package.packageType == PackageType.annual,
          );
        },
      );
    } catch (e) {
      debugPrint('Annual package not found: $e');
      return null;
    }
  }

  String _getWeeklyPrice() {
    final package = _getWeeklyPackage();
    return package?.storeProduct.priceString ?? '\$9.99';
  }

  String _getYearlyPrice() {
    final package = _getYearlyPackage();
    return package?.storeProduct.priceString ?? '\$19.99';
  }

  Package? _getSelectedPackage() {
    return isWeeklySelected ? _getWeeklyPackage() : _getYearlyPackage();
  }

  String _getWeeklySubtitle() {
    if (_remoteConfigFreeTrialEnabled) {
      return "3-day free trial included";
    } else {
      return "Try for 7 days, billed weekly";
    }
  }

  Future<void> _buyPackage() async {
    final package = _getSelectedPackage();

    if (package == null) {
      _showError('Selected subscription is not available');
      return;
    }

    if (_isPurchasePending) return;

    setState(() {
      _isPurchasePending = true;
    });

    try {
      HapticFeedback.lightImpact();

      final customerInfo =
          await Purchases.purchasePackage(package);

      // Check if any entitlements are now active
      if (customerInfo.customerInfo.entitlements.active.isNotEmpty) {
        debugPrint('Purchase successful - entitlements are active');
        await _updateUserStatus(true);
        _showSuccessMessage('🎉 Purchase successful! Welcome to Premium!');

        // Navigate to next page after delay
        await Future.delayed(const Duration(milliseconds: 2000));
        _navigateToNextPage();
      } else {
        debugPrint('Purchase completed but no active entitlements');
        _showError(
          'Purchase completed but access not granted. Please contact support.',
        );
      }
    } on PlatformException catch (e) {
      final errorCode = PurchasesErrorHelper.getErrorCode(e);
      debugPrint('Purchase error: ${e.message} (Code: $errorCode)');

      if (errorCode != PurchasesErrorCode.purchaseCancelledError) {
        _showError('Purchase failed: ${e.message}');
      }
    } catch (e) {
      debugPrint('Unexpected purchase error: $e');
      _showError('An unexpected error occurred');
    } finally {
      if (mounted) {
        setState(() {
          _isPurchasePending = false;
        });
      }
    }
  }

  Future<void> _restorePurchases() async {
    if (_isRestoringPurchases) return;

    setState(() {
      _isRestoringPurchases = true;
    });

    try {
      HapticFeedback.lightImpact();

      final customerInfo = await Purchases.restorePurchases();

      if (customerInfo.entitlements.active.isNotEmpty) {
        debugPrint('Restore successful - active entitlements found');
        await _updateUserStatus(true);
        _showSuccessMessage('🎉 Purchases restored successfully!');

        await Future.delayed(const Duration(milliseconds: 2000));
        _navigateToNextPage();
      } else {
        debugPrint('No active entitlements found after restore');
        _showError('No previous purchases found');
      }
    } on PlatformException catch (e) {
      debugPrint('Restore error: ${e.message}');
      _showError('Failed to restore purchases: ${e.message}');
    } catch (e) {
      debugPrint('Unexpected restore error: $e');
      _showError('An unexpected error occurred while restoring');
    } finally {
      if (mounted) {
        setState(() {
          _isRestoringPurchases = false;
        });
      }
    }
  }

  Future<void> _updateUserStatus(bool isPaidUser) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();

      await prefs.setBool('paid_user', isPaidUser);
      await prefs.setBool('has_completed_onboarding', isPaidUser);
      await prefs.setBool('subscription_active', isPaidUser);

      if (isPaidUser) {
        await prefs.setString('access_method', 'revenuecat_purchase');
        await prefs.setInt(
          'grant_timestamp',
          DateTime.now().millisecondsSinceEpoch,
        );
      }

      PurchaseService().updatePurchaseStatus(isPaidUser);

      debugPrint('User status updated: isPaidUser = $isPaidUser');
    } catch (e) {
      debugPrint('Error updating user status: $e');
    }
  }

  void _navigateToNextPage() {
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => AppFlow()),
        (route) => false,
      );
    }
  }

  void _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw 'Could not launch $url';
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccessMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    final deviceWidth = MediaQuery.of(context).size.width;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: Color.fromRGBO(243, 243, 243, 1),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: Color.fromRGBO(130, 140, 130, 1),
              ),
              const SizedBox(height: 20),
              Text(
                'Loading subscription plans...',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color.fromRGBO(130, 140, 130, 1),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Color.fromRGBO(243, 243, 243, 1),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(deviceWidth * 0.05),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Spacer(flex: 1),
              Image.asset('assets/logo_transparent.png', width: 100),
              Spacer(flex: 2),
              Text(
                "Identify mold anywhere, instantly.",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 35,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                  height: 1.2, 
                  letterSpacing: -0.5,
                ),
              ),
              Spacer(flex: 2),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    FontAwesomeIcons.camera,
                    color: Colors.black,
                    size: 20,
                  ),
                  SizedBox(width: 10),
                  Text(
                    "Instantly identify mold with camera",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                      height: 1.2,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    FontAwesomeIcons.exclamationTriangle,
                    color: Colors.black,
                    size: 20,
                  ),
                  SizedBox(width: 10),
                  Text(
                    "Detailed health risk assessments",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                      height: 1.2,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    FontAwesomeIcons.clipboardList,
                    color: Colors.black,
                    size: 20,
                  ),
                  SizedBox(width: 10),
                  Text(
                    "Receive remediation advice",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                      height: 1.2,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    FontAwesomeIcons.check,
                    color: Colors.black,
                    size: 20,
                  ),
                  SizedBox(width: 10),
                  Text(
                    "Cancel Anytime",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                      height: 1.2,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              Spacer(flex: 2),
              // Subscription Plan Options
              Column(
                children: [
                  // Yearly Plan
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        isWeeklySelected = false;
                        // When remote config disables free trial, local state should be false
                        isFreeTrialEnabled = false;
                      });
                    },
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(
                          color: !isWeeklySelected
                              ? Color.fromRGBO(130, 140, 130, 1)
                              : Colors.grey[300]!,
                          width: !isWeeklySelected ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  if (_remoteConfigFreeTrialEnabled) Text(
                                    "\$49.99 ",
                                    style: GoogleFonts.poppins(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: Color.fromRGBO(130, 130, 130, 1),
                                      decoration: TextDecoration.lineThrough
                                    ),
                                  ),
                                  Text(
                                    _remoteConfigFreeTrialEnabled == false ? "Yearly Plan" : "${_getYearlyPrice()} per year",
                                    style: GoogleFonts.poppins(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                _remoteConfigFreeTrialEnabled == false ? "\$19.99/year, billed annually" : "Billed yearly",
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Color.fromRGBO(130, 140, 130, 1),
                                ),
                              ),
                            ],
                          ),
                          if (isWeeklySelected == false) Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15),
                              color: Colors.black,
                            ),
                            child: Center(
                              child: FaIcon(FontAwesomeIcons.check, 
                                color: Colors.white, size: 10),
                              ),
                          )
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 15),
                  // Weekly Plan with Dynamic Free Trial
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        isWeeklySelected = true;
                        // Only enable free trial if remote config allows it
                        isFreeTrialEnabled = _remoteConfigFreeTrialEnabled;
                      });
                    },
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(
                          color: isWeeklySelected
                              ? Color.fromRGBO(130, 140, 130, 1)
                              : Colors.grey[300]!,
                          width: isWeeklySelected ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _remoteConfigFreeTrialEnabled == false ? "Weekly Plan" : "${_getWeeklyPrice()} per week",
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black,
                                ),
                              ),
                              Text(
                                _getWeeklySubtitle(),
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Color.fromRGBO(130, 140, 130, 1),
                                ),
                              ),
                            ],
                          ),
                          if (isWeeklySelected == true) Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15),
                              color: Colors.black,
                            ),
                            child: Center(
                              child: FaIcon(FontAwesomeIcons.check, 
                                color: Colors.white, size: 10),
                              ),
                          )
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  // Free Trial Toggle - Only show if remote config allows
                  if (_remoteConfigFreeTrialEnabled)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Free Trial Enabled",
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              isFreeTrialEnabled = !isFreeTrialEnabled;
                              // When turning off free trial, switch to yearly plan
                              // When turning on free trial, switch to weekly plan
                              isWeeklySelected = isFreeTrialEnabled;
                            });
                          },
                          child: Container(
                            width: 50,
                            height: 30,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15),
                              color: isFreeTrialEnabled
                                  ? Color.fromRGBO(130, 140, 130, 1)
                                  : Colors.grey[300],
                            ),
                            child: AnimatedAlign(
                              duration: Duration(milliseconds: 200),
                              alignment: isFreeTrialEnabled
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: Container(
                                width: 26,
                                height: 26,
                                margin: EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              Spacer(flex: 1),
              SizedBox(
                width: double.infinity,
                height: 65,
                child: ElevatedButton(
                  onPressed: _isPurchasePending || _isRestoringPurchases
                      ? null
                      : _buyPackage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(35),
                    ),
                  ),
                  child: _isPurchasePending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                         !_remoteConfigFreeTrialEnabled && isWeeklySelected ?
                          'Try for 7 days' : isWeeklySelected ? "Start Free Trial" : "Get Full Access",
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
              SizedBox(height: 15),
              // Footer links
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: _isRestoringPurchases || _isPurchasePending
                        ? null
                        : _restorePurchases,
                    child: Text(
                      _isRestoringPurchases ? "Restoring..." : "Restore",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color.fromRGBO(130, 140, 130, 1),
                      ),
                    ),
                  ),
                  Text(
                    " • ",
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color.fromRGBO(130, 140, 130, 1),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      _launchURL(
                        'https://www.apple.com/legal/internet-services/itunes/dev/stdeula/',
                      );
                    },
                    child: Text(
                      "Terms of Use",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color.fromRGBO(130, 140, 130, 1),
                      ),
                    ),
                  ),
                  Text(
                    " • ",
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color.fromRGBO(130, 140, 130, 1),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      _launchURL('https://moldai-website.vercel.app/privacy');
                    },
                    child: Text(
                      "Privacy Policy",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color.fromRGBO(130, 140, 130, 1),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}