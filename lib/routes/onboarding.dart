import 'package:flutter/material.dart';
import 'package:tinytummies/screens/onboarding/get_started.dart';
import 'package:tinytummies/screens/onboarding/worries.dart';

class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({super.key});

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentPage = index;
          });
        },
        physics: const NeverScrollableScrollPhysics(),
        children: [
          GetStartedScreen(controller: _pageController, pageIndex: _currentPage),
          WorriesScreen(controller: _pageController, pageIndex: _currentPage)
        ],
      ),
    );
  }
}