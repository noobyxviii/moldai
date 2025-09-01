import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileScreen extends StatefulWidget {
  final PageController controller;
  final int pageIndex;
  const ProfileScreen({
    super.key,
    required this.controller,
    required this.pageIndex,
  });
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _deleteAllData() async {
    // Show confirmation dialog
    final bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          title: Text(
            'Delete All Data',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          content: Text(
            'Are you sure you want to delete all your data? This action cannot be undone.',
            style: GoogleFonts.poppins(
              color: Colors.black,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
                widget.controller.animateToPage(
                0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
              },
              child: Text(
                'Delete',
                style: GoogleFonts.poppins(
                  color: const Color.fromRGBO(255, 128, 140, 1),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      setState(() {
        isLoading = true;
      });

      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();
        
        if (mounted) {
          HapticFeedback.lightImpact();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'All data deleted successfully',
                style: GoogleFonts.poppins(),
              ),
              backgroundColor: const Color.fromRGBO(63, 177, 151, 1),
            ),
          );
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Error deleting data: $e',
                style: GoogleFonts.poppins(),
              ),
              backgroundColor: const Color.fromRGBO(255, 128, 140, 1),
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    double deviceWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color.fromRGBO(243, 243, 243, 1),
      bottomNavigationBar: Container(
        width: deviceWidth,
        height: 100,
        decoration: BoxDecoration(
          color: Color.fromRGBO(255, 255, 255, 1),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(25),
            topRight: Radius.circular(25),
          ),
          boxShadow: [
            BoxShadow(
              color: Color.fromRGBO(0, 0, 0, 0.1),
              spreadRadius: 5,
              blurRadius: 15,
              offset: Offset(0, -3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            GestureDetector(
              onTap: () {
                setState(() {
                  HapticFeedback.lightImpact();
                  widget.controller.animateToPage(
                    widget.pageIndex - 2,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                });
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    FontAwesomeIcons.house,
                    size: 20,
                    color: Colors.black,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Home",
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () {
                setState(() {
                  HapticFeedback.lightImpact();
                  widget.controller.animateToPage(
                    widget.pageIndex - 1,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                });
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    FontAwesomeIcons.magnifyingGlass,
                    size: 20,
                    color: Colors.black,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Scan",
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () { HapticFeedback.lightImpact();},
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    FontAwesomeIcons.solidUser,
                    size: 20,
                    color: Color.fromRGBO(63, 114, 66, 1),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Profile",
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: Color.fromRGBO(63, 114, 66, 1),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(deviceWidth * 0.05),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: deviceWidth * 0.05),
                    
                    // Header with close button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Image.asset('assets/logo_transparent.png', height: 30),
                      ],
                    ),
                    
                    SizedBox(height: deviceWidth * 0.08),
                    
                    // Profile Title
                    Text(
                      "Profile Settings",
                      style: GoogleFonts.poppins(
                        color: Colors.black,
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    
                    SizedBox(height: deviceWidth * 0.06),
                    
                      GestureDetector(
                        onTap: _deleteAllData,
                        child: Container(
                            height: 100,
                            decoration: BoxDecoration(
                              color: const Color.fromRGBO(255, 255, 255, 1),
                              borderRadius: BorderRadius.all(Radius.circular(25)),
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(deviceWidth * 0.05),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                spacing: deviceWidth * 0.05,
                                children: [
                                  Icon(
                                    FontAwesomeIcons.solidTrashCan,
                                    size: 35,
                                    color: Color.fromRGBO(255, 125, 125, 1),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        "Delete Data",
                                        style: GoogleFonts.poppins(
                                          color: Color.fromRGBO(255, 125, 125, 1),
                                          fontSize: 15,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      Text(
                                        "Deletes all progress & data\nfrom your device.",
                                        style: GoogleFonts.poppins(
                                          color: Color.fromRGBO(255, 125, 125, 1),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ),
                    const Spacer(),
                    
                    // App Info Container
                    Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: Color.fromRGBO(255, 255, 255, 1),
                        borderRadius: BorderRadius.all(Radius.circular(25)),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(deviceWidth * 0.05),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "About Totsy",
                              style: GoogleFonts.poppins(
                                color: Colors.black,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              "Get peace of mind with Totsy. Share and receive real feedback on baby food, helping parents make safer, healthier choices for their little ones.",
                              style: GoogleFonts.poppins(
                                color: Colors.grey[600],
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            const SizedBox(height: 15),
                            Text(
                              "Version 1.0.0",
                              style: GoogleFonts.poppins(
                                color: Colors.grey[500],
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    SizedBox(height: deviceWidth * 0.05),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}