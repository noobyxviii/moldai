import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class GetStartedScreen extends StatefulWidget {
  final PageController controller;
  final int pageIndex;
  const GetStartedScreen({
    super.key,
    required this.controller,
    required this.pageIndex,
  });

  @override
  State<GetStartedScreen> createState() => _GetStartedScreenState();
}

class _GetStartedScreenState extends State<GetStartedScreen> {
  int currentSlideIndex = 0;
  final PageController _slideController = PageController();

  final List<SlideData> slides = [
    SlideData(
      image: 'assets/visual_1.png',
      title: 'Scan Baby Food Instantly',
      subtitle:
          "Quickly check if a product is healthy and safe\nfor your little one with just a scan.",
    ),
    SlideData(
      image: 'assets/visual_2.png',
      title: 'Trusted & Unbiased Results',
      subtitle:
          "Get clear, independent insights—no brand\ninfluence, only what's best for your baby.",
    ),
    SlideData(
      image: 'assets/visual_3.png',
      title: "Understand\nWhat's Inside",
      subtitle:
          "Understand ingredients, nutrition, and\nhow each food impacts your baby's health.",
    ),
    SlideData(
      image: 'assets/visual_4.png',
      title: 'Track Daily\nNutrition',
      subtitle:
          'Monitor protein, carbs, fats, and vitamins\nto ensure balanced growth every day.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final deviceWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Color.fromRGBO(243, 243, 243, 1),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(deviceWidth * 0.05),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 25),
              Expanded(
                flex: 20,
                child: PageView.builder(
                  controller: _slideController,
                  onPageChanged: (index) {
                    setState(() {
                      currentSlideIndex = index;
                    });
                  },
                  itemCount: slides.length,
                  itemBuilder: (context, index) {
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        //Image.asset(
                        // slides[index].image,
                        //  width: deviceWidth * 0.45,
                        //),
                        Stack(
                          alignment: Alignment.centerLeft,
                          children: [
                            Container(
                              width: deviceWidth * 0.8,
                              height: 10,
                              decoration: BoxDecoration(
                                color: Color.fromRGBO(230, 230, 230, 1),
                                borderRadius: BorderRadius.all(
                                  Radius.circular(5),
                                ),
                              ),
                            ),
                            Container(
                              width: (deviceWidth * 0.8) * ((index + 1) / 4),
                              height: 10,
                              decoration: BoxDecoration(
                                color: Colors.black,
                                borderRadius: BorderRadius.all(
                                  Radius.circular(5),
                                ),
                              ),
                            ),
                          ],
                        ),
                        Spacer(),
                        Text(
                          slides[index].title,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 30,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                            height: 1.2,
                            letterSpacing: -0.5,
                          ),
                        ),
                        SizedBox(height: 15),
                        Text(
                          slides[index].subtitle,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                            color: const Color.fromRGBO(140, 140, 140, 1),
                            height: 1.2,
                            letterSpacing: -0.5,
                          ),
                        ),
                        Spacer(),
                        Container(
                          width: 325,
                          height: 350,
                          decoration: BoxDecoration(
                            image: DecorationImage(
                              image: AssetImage(slides[index].image),
                              fit: BoxFit.contain,
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        Spacer(),
                      ],
                    );
                  },
                ),
              ),

              // Page indicators
              SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  slides.length,
                  (index) => Container(
                    margin: EdgeInsets.symmetric(horizontal: 4),
                    width: currentSlideIndex == index ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: currentSlideIndex == index
                          ? Colors.black
                          : Colors.grey.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 25),
              SizedBox(
                width: deviceWidth * 0.9,
                height: 75,
                child: ElevatedButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    if (currentSlideIndex < slides.length - 1) {
                      // Move to next slide
                      _slideController.animateToPage(
                        currentSlideIndex + 1,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    } else {
                      // Navigate to next screen
                      widget.controller.animateToPage(
                        widget.pageIndex + 1,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(37.5),
                    ),
                  ),
                  child: Text(
                    currentSlideIndex < slides.length - 1
                        ? "Continue"
                        : "Get Started",
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }
}

class SlideData {
  final String image;
  final String title;
  final String subtitle;

  SlideData({required this.image, required this.title, required this.subtitle});
}
