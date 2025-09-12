import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class ThanksScreen extends StatefulWidget {
  final PageController controller;
  final int pageIndex;
  const ThanksScreen({
    super.key,
    required this.controller,
    required this.pageIndex,
  });

  @override
  State<ThanksScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<ThanksScreen> {
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
            mainAxisAlignment: MainAxisAlignment.center,
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
                        height: 7.5,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.all(Radius.circular(20)),
                          color: Color.fromRGBO(246, 246, 246, 1),
                        ),
                      ),
                      Container(
                        width: (deviceWidth * 0.9 - 120) * (10 / 10),
                        height: 7.5,
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.all(Radius.circular(20)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset('assets/thanks_visual.png', width: 200),
                  SizedBox(height: 15),
                  Text(
                    "All Done!",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 35,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                      height: 1.2,
                      letterSpacing: -0.5,
                    ),
                  ),
                  SizedBox(height: 15),
                  Text(
                    "Thank you for\ntrusting us.",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 35,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                      height: 1.2,
                      letterSpacing: -0.5,
                    ),
                  ),
                  SizedBox(height: 15),
                  Text(
                    "Continue to identify\nmold with confidence.",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                      height: 1.2,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              Spacer(),
              SizedBox(
                width: double.infinity,
                height: 75,
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
                      borderRadius: BorderRadius.circular(37.5),
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