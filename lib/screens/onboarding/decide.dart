import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class DecideScreen extends StatefulWidget {
  final PageController controller;
  final int pageIndex;
  const DecideScreen({
    super.key,
    required this.controller,
    required this.pageIndex,
  });

  @override
  State<DecideScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<DecideScreen> {
  int _selectedAnswer = 0;
  @override
  Widget build(BuildContext context) {
    final deviceWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(deviceWidth * 0.05),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 25),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Image.asset('assets/logo_transparent.png', width: 80),
                  Stack(
                    children: [
                      Container(
                        width: deviceWidth * 0.9 - 120,
                        height: 5,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.all(Radius.circular(20)),
                          color: Color.fromRGBO(246, 246, 246, 1),
                        ),
                      ),
                      Container(
                        width: (deviceWidth * 0.9 - 120) * (9 / 10),
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.all(Radius.circular(20)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              SizedBox(height: 25),
              Text(
                'What are your motivations behind your journey?',
                textAlign: TextAlign.left,
                style: GoogleFonts.poppins(
                  fontSize: 25,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                  height: 1.2,
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: 15),
              Text(
                "I want to...",
                textAlign: TextAlign.left,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: Colors.black,
                  height: 1.2,
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: 30),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    spacing: 15,
                    children: [
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            HapticFeedback.lightImpact();
                            _selectedAnswer = 1;
                          });
                        },
                        child: Container(
                          width: deviceWidth * 0.9,
                          height: 75,
                          decoration: BoxDecoration(
                            color: Color.fromRGBO(246, 246, 246, 1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _selectedAnswer == 1
                                  ? Colors.black
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              "...increase my energy and strength",
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            HapticFeedback.lightImpact();
                            _selectedAnswer = 2;
                          });
                        },
                        child: Container(
                          width: deviceWidth * 0.9,
                          height: 75,
                          decoration: BoxDecoration(
                            color: Color.fromRGBO(246, 246, 246, 1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _selectedAnswer == 2
                                  ? Colors.black
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              "...improve my health",
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            HapticFeedback.lightImpact();
                            _selectedAnswer = 3;
                          });
                        },
                        child: Container(
                          width: deviceWidth * 0.9,
                          height: 75,
                          decoration: BoxDecoration(
                            color: Color.fromRGBO(246, 246, 246, 1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _selectedAnswer == 3
                                  ? Colors.black
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              "...feel more confident",
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            HapticFeedback.lightImpact();
                            _selectedAnswer = 4;
                          });
                        },
                        child: Container(
                          width: deviceWidth * 0.9,
                          height: 75,
                          decoration: BoxDecoration(
                            color: Color.fromRGBO(246, 246, 246, 1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _selectedAnswer == 4
                                  ? Colors.black
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              "...feel good about what i'm wearing",
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            HapticFeedback.lightImpact();
                            _selectedAnswer = 5;
                          });
                        },
                        child: Container(
                          width: deviceWidth * 0.9,
                          height: 75,
                          decoration: BoxDecoration(
                            color: Color.fromRGBO(246, 246, 246, 1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _selectedAnswer == 5
                                  ? Colors.black
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              "...have a new start",
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            HapticFeedback.lightImpact();
                            _selectedAnswer = 6;
                          });
                        },
                        child: Container(
                          width: deviceWidth * 0.9,
                          height: 75,
                          decoration: BoxDecoration(
                            color: Color.fromRGBO(246, 246, 246, 1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _selectedAnswer == 6
                                  ? Colors.black
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              "Other",
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 65,
                child: ElevatedButton(
                  onPressed: () {
                    if (_selectedAnswer != 0) {
                      HapticFeedback.lightImpact();
                      widget.controller.animateToPage(
                        widget.pageIndex + 1,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedAnswer == 0
                        ? Color.fromRGBO(120, 120, 120, 1)
                        : Colors.black,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: Text(
                    'Continue',
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
}