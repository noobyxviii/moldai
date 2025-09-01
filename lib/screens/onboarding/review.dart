import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:in_app_review/in_app_review.dart';

class ReviewScreen extends StatefulWidget {
  final PageController controller;
  final int pageIndex;
  const ReviewScreen({
    super.key,
    required this.controller,
    required this.pageIndex,
  });

  @override
  State<ReviewScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<ReviewScreen> {
  final InAppReview inAppReview = InAppReview.instance;

  @override
  void initState() {
    super.initState();
    _requestReview();
  }

  void _requestReview() async {
    try {
      if (await inAppReview.isAvailable()) {
        inAppReview.requestReview();
      }
    } catch (e) {
      // Handle any errors silently - don't disrupt user experience
      print('Error requesting review: $e');
    }
  }
  @override
  Widget build(BuildContext context) {
    final deviceWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Color.fromRGBO(243, 243, 243, 1),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(deviceWidth * 0.05),
          child: Column(
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
                        width: (deviceWidth * 0.9 - 120) * (7 / 7),
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

              SizedBox(height: 25),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Give us a rating',
                    textAlign: TextAlign.left,
                    style: GoogleFonts.poppins(
                      fontSize: 30,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                      height: 1.2,
                      letterSpacing: -0.5,
                    ),
                  ),
                  SizedBox(height: 15),
                  Text(
                    "Your feedback helps us improve and reach more parents like you.",
                    textAlign: TextAlign.left,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w400,
                      color: Colors.black,
                      height: 1.2,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 50),
              Image.asset('assets/rating.png', height: 85),
              SizedBox(height: 35),
              Text(
                "Totsy is backed by people like you.",
                textAlign: TextAlign.left,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                  height: 1.2,
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: 35),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Review 1
                      Container(
                        width: deviceWidth,
                        height: 205,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.all(Radius.circular(20)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(25.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Life changing!",
                                    textAlign: TextAlign.left,
                                    style: GoogleFonts.poppins(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black,
                                      height: 1.2,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  Row(children: [
                                    FaIcon( FontAwesomeIcons.solidStar, color: Colors.amber, size: 18),
                                    FaIcon( FontAwesomeIcons.solidStar, color: Colors.amber, size: 18),
                                    FaIcon( FontAwesomeIcons.solidStar, color: Colors.amber, size: 18),
                                    FaIcon( FontAwesomeIcons.solidStar, color: Colors.amber, size: 18),
                                    FaIcon( FontAwesomeIcons.solidStar, color: Colors.amber, size: 18),
                                  ],)
                                ],
                              ),
                              SizedBox(height: 5),
                              Text(
                                    "Sarah M.",
                                    textAlign: TextAlign.left,
                                    style: GoogleFonts.poppins(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w400,
                                      color: Color.fromRGBO(130, 130, 130, 1),
                                      height: 1.2,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  SizedBox(height: 15),
                                  Text(
                                    "As a first-time mom, I was so overwhelmed by all the baby food options. This app is amazing - I just scan and instantly know if something has harmful ingredients.",
                                    textAlign: TextAlign.left,
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w400,
                                      color: Colors.black,
                                      height: 1.2,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      
                      // Review 2
                      Container(
                        width: deviceWidth,
                        height: 205,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.all(Radius.circular(20)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(25.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Perfect for parents",
                                    textAlign: TextAlign.left,
                                    style: GoogleFonts.poppins(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black,
                                      height: 1.2,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  Row(children: [
                                    FaIcon( FontAwesomeIcons.solidStar, color: Colors.amber, size: 18),
                                    FaIcon( FontAwesomeIcons.solidStar, color: Colors.amber, size: 18),
                                    FaIcon( FontAwesomeIcons.solidStar, color: Colors.amber, size: 18),
                                    FaIcon( FontAwesomeIcons.solidStar, color: Colors.amber, size: 18),
                                    FaIcon( FontAwesomeIcons.solidStar, color: Colors.amber, size: 18),
                                  ],)
                                ],
                              ),
                              SizedBox(height: 5),
                              Text(
                                    "Mike R.",
                                    textAlign: TextAlign.left,
                                    style: GoogleFonts.poppins(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w400,
                                      color: Color.fromRGBO(130, 130, 130, 1),
                                      height: 1.2,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  SizedBox(height: 15),
                                  Text(
                                    "Shopping for baby food used to take forever reading every label. Now I just scan with Totsy and know immediately what's safe. Highly recommend to all parents!",
                                    textAlign: TextAlign.left,
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w400,
                                      color: Colors.black,
                                      height: 1.2,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      
                      // Review 3
                      Container(
                        width: deviceWidth,
                        height: 205,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.all(Radius.circular(20)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(25.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Finally feel confident",
                                    textAlign: TextAlign.left,
                                    style: GoogleFonts.poppins(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black,
                                      height: 1.2,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  Row(children: [
                                    FaIcon( FontAwesomeIcons.solidStar, color: Colors.amber, size: 18),
                                    FaIcon( FontAwesomeIcons.solidStar, color: Colors.amber, size: 18),
                                    FaIcon( FontAwesomeIcons.solidStar, color: Colors.amber, size: 18),
                                    FaIcon( FontAwesomeIcons.solidStar, color: Colors.amber, size: 18),
                                    FaIcon( FontAwesomeIcons.solidStar, color: Colors.amber, size: 18),
                                  ],)
                                ],
                              ),
                              SizedBox(height: 5),
                              Text(
                                    "Jessica L.",
                                    textAlign: TextAlign.left,
                                    style: GoogleFonts.poppins(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w400,
                                      color: Color.fromRGBO(130, 130, 130, 1),
                                      height: 1.2,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  SizedBox(height: 15),
                                  Text(
                                    "I love how this app explains why certain ingredients might be harmful and suggests better alternatives. It's not just scanning - it's educating me to be a better parent. Worth every penny!",
                                    textAlign: TextAlign.left,
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w400,
                                      color: Colors.black,
                                      height: 1.2,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
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