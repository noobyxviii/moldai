import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  final PageController controller;
  final int pageIndex;

  const HomeScreen({
    super.key,
    required this.controller,
    required this.pageIndex,
  });
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? _todayNutrition;
  List<Map<String, dynamic>> _recentScans = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await _loadTodayNutrition();
    await _loadRecentScans();
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loadTodayNutrition() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = DateTime.now();
      final todayDateString = "${today.year}-${today.month}-${today.day}";
      const dataKey = 'daily_nutrition_data';
      const dateKey = 'last_saved_date';

      String? lastSavedDate = prefs.getString(dateKey);

      if (lastSavedDate == todayDateString) {
        final existingDataString = prefs.getString(dataKey);
        if (existingDataString != null) {
          _todayNutrition = json.decode(existingDataString);
        }
      }

      // If no data for today, initialize with zeros
      _todayNutrition ??= {'protein': 0.0, 'carbs': 0.0, 'fats': 0.0};
    } catch (e) {
      if (kDebugMode) {
        print('Error loading today nutrition: $e');
      }
      _todayNutrition = {'protein': 0.0, 'carbs': 0.0, 'fats': 0.0};
    }
  }

  Future<void> _loadRecentScans() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existingScansJson = prefs.getString('recent_scans');

      if (existingScansJson != null) {
        final decoded = json.decode(existingScansJson);
        _recentScans = List<Map<String, dynamic>>.from(decoded);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading recent scans: $e');
      }
      _recentScans = [];
    }
  }

  String _formatNutritionValue(dynamic value) {
    if (value == null) return "0g";
    double doubleValue = value is double
        ? value
        : double.tryParse(value.toString()) ?? 0.0;
    return "${doubleValue.round()}g";
  }

  Widget _buildNutritionCard(
    String value,
    String label,
    IconData icon,
    Color iconColor,
  ) {
    return Container(
      height: 100,
      width: 175,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(15)),
        color: Colors.white,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(25.0, 15.0, 25.0, 15.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            FaIcon(icon, size: 50, color: iconColor),
          ],
        ),
      ),
    );
  }

  Widget _buildScanItem(Map<String, dynamic> scan) {
    final score = scan['score'] ?? 0;
    final productName = scan['productName'] ?? 'Unknown Product';
    final imagePath = scan['imagePath'] as String?;
    final timestamp = scan['timestamp'] as int?;

    // Format timestamp
    String timeText = 'Recently';
    if (timestamp != null) {
      final scanTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      final now = DateTime.now();
      final difference = now.difference(scanTime);

      if (difference.inDays > 0) {
        timeText = '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        timeText = '${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        timeText = '${difference.inMinutes}m ago';
      } else {
        timeText = 'Just now';
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      height: 125,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(15)),
        color: Colors.white,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(15.0, 15.0, 15.0, 15.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              spacing: 15.0,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                  child: imagePath != null && File(imagePath).existsSync()
                      ? Image.file(
                          File(imagePath),
                          height: 95,
                          width: 95,
                          fit: BoxFit.cover,
                        )
                      : Image.asset(
                          'assets/baby_food.png',
                          height: 95,
                          width: 95,
                          fit: BoxFit.cover,
                        ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 115,
                      child: Text(
                        productName,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                    ),
                    SizedBox(height: 5),
                    SizedBox(
                      width: 115,
                      child: Text(
                        timeText,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Stack(
              alignment: AlignmentDirectional.center,
              children: [
                SizedBox(
                  width: 75,
                  height: 75,
                  child: CircularProgressIndicator(
                    value: score / 100,
                    color: _getScoreColor(score),
                    strokeWidth: 8,
                    backgroundColor: Color.fromRGBO(230, 230, 230, 1),
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      score.toString(),
                      style: GoogleFonts.poppins(
                        fontSize: 25,
                        fontWeight: FontWeight.w700,
                        color: _getScoreColor(score),
                        height: 1.0,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return const Color(0xFF4CAF50); // Green
    if (score >= 60) return const Color(0xFFFFC107); // Amber
    return const Color(0xFFF44336); // Red
  }

  Widget _buildEmptyScansPlaceholder() {
    return Container(
      height: 125,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(15)),
        color: Colors.white,
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(
              FontAwesomeIcons.magnifyingGlass,
              size: 40,
              color: Colors.grey[400],
            ),
            SizedBox(height: 10),
            Text(
              'No scans yet',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
            Text(
              'Tap "Scan" to get started',
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double deviceWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: const Color.fromRGBO(243, 243, 243, 1),
      resizeToAvoidBottomInset: true,
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
                    widget.pageIndex + 0,
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
                    color: Color.fromRGBO(63, 114, 66, 1),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Home",
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: Color.fromRGBO(63, 114, 66, 1),
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
                    widget.pageIndex + 1,
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
              onTap: () {
                setState(() {
                  HapticFeedback.lightImpact();
                  widget.controller.animateToPage(
                    widget.pageIndex + 2,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                });
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    FontAwesomeIcons.solidUser,
                    size: 20,
                    color: Colors.black,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Profile",
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: Colors.black,
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
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.all(deviceWidth * 0.05),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: deviceWidth * 0.05),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Image.asset(
                            'assets/logo_transparent.png',
                            height: 30,
                          ),
                          GestureDetector(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              widget.controller.animateToPage(
                                widget.pageIndex + 2,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            },
                            child: FaIcon(
                              FontAwesomeIcons.gear,
                              size: 25,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 25),
                      Text(
                        "Today's nutrition >",
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 10),
                      if (_isLoading)
                        SizedBox(
                          height: 100,
                          child: Center(
                            child: CircularProgressIndicator(
                              color: Color.fromRGBO(63, 114, 66, 1),
                            ),
                          ),
                        )
                      else
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            spacing: 15.0,
                            children: [
                              _buildNutritionCard(
                                _formatNutritionValue(
                                  _todayNutrition?['protein'],
                                ),
                                "Protein",
                                FontAwesomeIcons.egg,
                                Color.fromRGBO(131, 131, 213, 1),
                              ),
                              _buildNutritionCard(
                                _formatNutritionValue(
                                  _todayNutrition?['carbs'],
                                ),
                                "Carbs",
                                FontAwesomeIcons.breadSlice,
                                Color.fromRGBO(217, 193, 115, 1),
                              ),
                              _buildNutritionCard(
                                _formatNutritionValue(_todayNutrition?['fats']),
                                "Fats",
                                FontAwesomeIcons.fish,
                                Color.fromRGBO(103, 185, 205, 1),
                              ),
                            ],
                          ),
                        ),
                      SizedBox(height: 25),
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          widget.controller.animateToPage(
                            widget.pageIndex + 1,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                        child: Container(
                          height: 65,
                          width: deviceWidth,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.all(
                              Radius.circular(32.5),
                            ),
                            color: Color.fromRGBO(230, 230, 230, 1),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.25),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              spacing: 16.25,
                              children: [
                                FaIcon(FontAwesomeIcons.magnifyingGlass),
                                Text(
                                  "Scan & track baby food",
                                  style: GoogleFonts.poppins(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 25),
                      Text(
                        "Your Products >",
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 15),
                      if (_isLoading)
                        SizedBox(
                          height: 125,
                          child: Center(
                            child: CircularProgressIndicator(
                              color: Color.fromRGBO(63, 114, 66, 1),
                            ),
                          ),
                        )
                      else if (_recentScans.isEmpty)
                        _buildEmptyScansPlaceholder()
                      else
                        Column(
                          children: _recentScans
                              .map((scan) => _buildScanItem(scan))
                              .toList(),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
