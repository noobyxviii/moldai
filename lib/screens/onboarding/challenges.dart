import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class MoldChallengeScreen extends StatefulWidget {
  final PageController controller;
  final int pageIndex;
  const MoldChallengeScreen({
    super.key,
    required this.controller,
    required this.pageIndex,
  });

  @override
  State<MoldChallengeScreen> createState() => _MoldChallengeScreenState();
}

class _MoldChallengeScreenState extends State<MoldChallengeScreen> {
  int _selectedAnswer = 0;
  @override
  Widget build(BuildContext context) {
    final deviceWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color.fromRGBO(243, 243, 243, 1),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(deviceWidth * 0.05),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 25),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Image.asset('assets/logo_transparent.png', width: 80),
                  Stack(
                    children: [
                      Container(
                        width: deviceWidth * 0.9 - 120,
                        height: 7.5,
                        decoration: const BoxDecoration(
                          borderRadius: BorderRadius.all(Radius.circular(20)),
                          color: Color.fromRGBO(230, 230, 230, 1),
                        ),
                      ),
                      Container(
                        width: (deviceWidth * 0.9 - 120) * (3 / 7),
                        height: 7.5,
                        decoration: const BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.all(Radius.circular(20)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 25),
              Text(
                "What's the hardest part when dealing with mold?",
                textAlign: TextAlign.left,
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                  height: 1.2,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 15),
              Text(
                "I struggle most with...",
                textAlign: TextAlign.left,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w400,
                  color: Colors.black,
                  height: 1.2,
                  letterSpacing: -0.5,
                ),
              ),
              const Spacer(),

              // Option 1
              _buildOption(
                context,
                deviceWidth,
                1,
                "Knowing whether the mold is harmful",
              ),
              const SizedBox(height: 15),

              // Option 2
              _buildOption(
                context,
                deviceWidth,
                2,
                "Finding the right way to remove it safely",
              ),
              const SizedBox(height: 15),

              // Option 3
              _buildOption(
                context,
                deviceWidth,
                3,
                "Preventing mold from coming back",
              ),
              const SizedBox(height: 15),

              // Option 4
              _buildOption(
                context,
                deviceWidth,
                4,
                "Determining the seriousness of the mold",
              ),

              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 75,
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
                        ? const Color.fromRGBO(120, 120, 120, 1)
                        : Colors.black,
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

  Widget _buildOption(
      BuildContext context, double deviceWidth, int value, String text) {
    return GestureDetector(
      onTap: () {
        setState(() {
          HapticFeedback.lightImpact();
          _selectedAnswer = value;
        });
      },
      child: Container(
        width: deviceWidth * 0.9,
        height: 75,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _selectedAnswer == value ? Colors.black : Colors.transparent,
            width: 2,
          ),
        ),
        child: Center(
          child: Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
        ),
      ),
    );
  }
}
