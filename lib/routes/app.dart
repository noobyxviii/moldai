import 'package:flutter/material.dart';
import 'package:tinytummies/screens/home.dart';
import 'package:tinytummies/screens/scan.dart';
import 'package:tinytummies/screens/profile.dart';

class AppFlow extends StatefulWidget {
  const AppFlow({super.key});

  @override
  State<AppFlow> createState() => _AppFlowState();
}

class _AppFlowState extends State<AppFlow> {
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
        children: [
          HomeScreen(controller: _pageController, pageIndex: _currentPage),
          FoodScannerScreen(onNutritionUpdate: (double protein, double fiber) {  },controller: _pageController, pageIndex: _currentPage),
          ProfileScreen(controller: _pageController, pageIndex: _currentPage)
        ],
      ),
    );
  }
}