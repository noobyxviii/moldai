import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class EffectiveScreen extends StatefulWidget {
  final PageController controller;
  final int pageIndex;
  const EffectiveScreen({
    super.key,
    required this.controller,
    required this.pageIndex,
  });

  @override
  State<EffectiveScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<EffectiveScreen> {
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
                        width: (deviceWidth * 0.9 - 120) * (5 / 10),
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
                'Achieve faster results by managing your GLP-1 effectively with Glupi.',
                textAlign: TextAlign.left,
                style: GoogleFonts.poppins(
                  fontSize: 25,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                  height: 1.2,
                  letterSpacing: -0.5,
                ),
              ),
              Spacer(),
              Container(
                width: deviceWidth * 0.9,
                decoration: BoxDecoration(
                  color: Color.fromRGBO(246, 246, 246, 1),
                  borderRadius: BorderRadius.all(Radius.circular(20)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: 50),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      spacing: 15,
                      children: [
                        Stack(
                          alignment: AlignmentDirectional.bottomCenter,
                          children: [
                            Container(
                              width: 125,
                              height: 200,
                              decoration: BoxDecoration(
                                color: Color.fromRGBO(255, 255, 255, 1),
                                borderRadius: BorderRadius.all(
                                  Radius.circular(20),
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  SizedBox(height: 15),
                                  Text(
                                    "Without",
                                    style: GoogleFonts.poppins(
                                      color: Colors.black,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: 125,
                              height: 50,
                              decoration: BoxDecoration(
                                color: const Color.fromRGBO(225, 225, 225, 1),
                                borderRadius: BorderRadius.all(
                                  Radius.circular(20),
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  "1+ Years",
                                  style: GoogleFonts.poppins(
                                    color: Colors.black,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        Stack(
                          alignment: AlignmentDirectional.bottomCenter,
                          children: [
                            Container(
                              width: 125,
                              height: 200,
                              decoration: BoxDecoration(
                                color: Color.fromRGBO(255, 255, 255, 1),
                                borderRadius: BorderRadius.all(
                                  Radius.circular(20),
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  SizedBox(height: 15),
                                  Text(
                                    "Glupi",
                                    style: GoogleFonts.poppins(
                                      color: Colors.black,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: 125,
                              height: 150,
                              decoration: BoxDecoration(
                                color: const Color.fromRGBO(255, 128, 140, 1),
                                borderRadius: BorderRadius.all(
                                  Radius.circular(20),
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  "See results within months",
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 25),
                    Text(
                      "Understand your side effects, track\nyour shots, and hit your weight-loss\ngoals effectively.",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        color: Colors.black,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 25),
                  ],
                ),
              ),
              Spacer(),
              SizedBox(
                width: double.infinity,
                height: 65,
                child: ElevatedButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    widget.controller.animateToPage(
                      widget.pageIndex + 1,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
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