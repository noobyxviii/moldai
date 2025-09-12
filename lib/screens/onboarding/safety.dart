import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class MoldScreen extends StatefulWidget {
  final PageController controller;
  final int pageIndex;
  const MoldScreen({
    super.key,
    required this.controller,
    required this.pageIndex,
  });

  @override
  State<MoldScreen> createState() => _MoldScreenState();
}

class _MoldScreenState extends State<MoldScreen> {
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
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.all(Radius.circular(20)),
                          color: const Color.fromRGBO(230, 230, 230, 1),
                        ),
                      ),
                      Container(
                        width: (deviceWidth * 0.9 - 120) * (4 / 7),
                        height: 7.5,
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: const BorderRadius.all(Radius.circular(20)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 25),
              Text(
                "What matters most for your home's safety?",
                textAlign: TextAlign.left,
                style: GoogleFonts.poppins(
                  fontSize: 30,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                  height: 1.2,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 15),
              Text(
                "When dealing with mold, I would feel most secure if I...",
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
              ..._buildOptions(deviceWidth),
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

  List<Widget> _buildOptions(double deviceWidth) {
    final options = [
      "Knew exactly which mold is harmful",
      "Received step-by-step removal guidance",
      "Understood proper disposal methods",
      "Could prevent mold from coming back",
    ];

    return List.generate(options.length, (index) {
      final i = index + 1;
      return Padding(
        padding: const EdgeInsets.only(bottom: 15),
        child: GestureDetector(
          onTap: () {
            setState(() {
              HapticFeedback.lightImpact();
              _selectedAnswer = i;
            });
          },
          child: Container(
            width: deviceWidth * 0.9,
            height: 75,
            decoration: BoxDecoration(
              color: const Color.fromRGBO(255, 255, 255, 1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _selectedAnswer == i ? Colors.black : Colors.transparent,
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                options[index],
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
            ),
          ),
        ),
      );
    });
  }
}
