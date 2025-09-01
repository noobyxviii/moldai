import 'package:flutter/material.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:totsy/screens/onboarding/decide.dart';
import 'package:totsy/screens/onboarding/effective.dart';
import 'package:totsy/screens/onboarding/get_started.dart';
import 'package:totsy/screens/onboarding/info.dart';
import 'package:totsy/screens/onboarding/parent.dart';
import 'package:totsy/screens/onboarding/paywall.dart';
import 'package:totsy/screens/onboarding/review.dart';
import 'package:totsy/screens/onboarding/thanks.dart';
import 'package:totsy/screens/onboarding/worries.dart';

class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({super.key});

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final FirebaseAnalytics analytics = FirebaseAnalytics.instance;

  // Your existing screen names
  final List<String> _screenNames = [
    'Get Started Screen',
    'Worries Screen',
    'Decide Screen',
    'Parent Screen',
    'Effective Screen',
    'Info Screen',
    'Review Screen',
    'Thanks Screen',
    'Paywall Screen',
  ];

  void _logScreenView(int index) {
    if (index >= 0 && index < _screenNames.length) {
      analytics.logEvent(
        name: 'onboarding_screen_opened',
        parameters: {
          'screen_name': _screenNames[index],
          'screen_index': index,
          'total_screens': _screenNames.length,
        },
      );

      analytics.logScreenView(
        screenName: _screenNames[index],
        screenClass: 'OnboardingFlow',
      );
    }
  }

  @override
  void initState() {
    super.initState();
    analytics.setAnalyticsCollectionEnabled(true);

    analytics.logEvent(name: 'Onboarding Started');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _logScreenView(0);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) async {
          setState(() {
            _currentPage = index;
          });
          _logScreenView(index);

          if (index == _screenNames.length - 1) {
            analytics.logEvent(
              name: 'Onboarding Completed',
              parameters: {'completion_rate': 100},
            );
          }
        },
        physics: const NeverScrollableScrollPhysics(),
        children: [
          GetStartedScreen(controller: _pageController, pageIndex: _currentPage),
          WorriesScreen(controller: _pageController, pageIndex: _currentPage),
          DecideScreen(controller: _pageController, pageIndex: _currentPage),
          ParentScreen(controller: _pageController, pageIndex: _currentPage),
          EffectiveScreen(controller: _pageController, pageIndex: _currentPage),
          InfoScreen(controller: _pageController, pageIndex: _currentPage),
          ReviewScreen(controller: _pageController, pageIndex: _currentPage),
          ThanksScreen(controller: _pageController, pageIndex: _currentPage),
          PaywallScreen(controller: _pageController, pageIndex: _currentPage)
        ],
      ),
    );
  }
}