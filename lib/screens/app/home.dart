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
  List<Map<String, dynamic>> _recentScans = [];
  Map<String, int> _scanStatistics = {'totalScans': 0, 'highRiskScans': 0};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await _loadRecentMoldScans();
    await _loadScanStatistics();
    setState(() {
      _isLoading = false;
    });
  }

  // Updated to load mold scans from the correct key
  Future<void> _loadRecentMoldScans() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existingScansJson = prefs.getString('recent_mold_scans'); // Changed key

      if (existingScansJson != null) {
        final decoded = json.decode(existingScansJson);
        _recentScans = List<Map<String, dynamic>>.from(decoded);
        
        if (kDebugMode) {
          print('Loaded ${_recentScans.length} mold scans');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading recent mold scans: $e');
      }
      _recentScans = [];
    }
  }

  // New method to load scan statistics
  Future<void> _loadScanStatistics() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final totalScans = prefs.getInt('total_scans_count') ?? 0;
      final highRiskScans = prefs.getInt('high_risk_scans_count') ?? 0;
      
      _scanStatistics = {
        'totalScans': totalScans,
        'highRiskScans': highRiskScans,
      };
      
      if (kDebugMode) {
        print('Loaded scan statistics: Total: $totalScans, High-Risk: $highRiskScans');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading scan statistics: $e');
      }
      _scanStatistics = {'totalScans': 0, 'highRiskScans': 0};
    }
  }

  // Updated to display mold scan data correctly
  Widget _buildMoldScanItem(Map<String, dynamic> scan) {
    final moldName = scan['moldName'] ?? 'Unknown Mold';
    final harmScale = scan['harmScale'] ?? 0;
    final isHarmful = scan['isHarmful'] ?? false;
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
                      : Container(
                          height: 95,
                          width: 95,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            FontAwesomeIcons.bacterium,
                            color: Colors.grey[400],
                            size: 40,
                          ),
                        ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 115,
                      child: Text(
                        moldName,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                    ),
                    SizedBox(height: 5),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: isHarmful ? Colors.red[100] : Colors.green[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isHarmful ? 'Harmful' : 'Safe',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: isHarmful ? Colors.red[700] : Colors.green[700],
                        ),
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      timeText,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: Colors.grey[600],
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
                    value: harmScale / 100,
                    color: _getHarmScaleColor(harmScale),
                    strokeWidth: 8,
                    backgroundColor: Color.fromRGBO(230, 230, 230, 1),
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      harmScale.toString(),
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: _getHarmScaleColor(harmScale),
                        height: 1.0,
                      ),
                    ),
                    Text(
                      'Risk',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: _getHarmScaleColor(harmScale),
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

  // Updated color scheme for harm scale
  Color _getHarmScaleColor(int harmScale) {
    if (harmScale >= 80) return const Color(0xFFD32F2F); // Red - Dangerous
    if (harmScale >= 60) return const Color(0xFFFF5722); // Deep Orange - High Risk
    if (harmScale >= 40) return const Color(0xFFF57C00); // Orange - Medium Risk
    if (harmScale >= 20) return const Color(0xFFFBC02D); // Yellow - Low Risk
    return const Color(0xFF4CAF50); // Green - Minimal Risk
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
              FontAwesomeIcons.bacterium,
              size: 40,
              color: Colors.grey[400],
            ),
            SizedBox(height: 10),
            Text(
              'No mold scans yet',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
            Text(
              'Tap "MoldAI" to get started',
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }

  // New method to build statistics cards
  Widget _buildStatisticsCard(BuildContext context, String value, String label, IconData icon, Color color) {
    double deviceWidth = MediaQuery.of(context).size.width;
    return Container(
      height: 80,
      width: (deviceWidth * 0.85) / 3,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        color: Colors.white,
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FaIcon(icon, size: 16, color: color),
                SizedBox(width: 6),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ],
            ),
            SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
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
              child: Container(
                color: Colors.transparent,
                width: 100, 
                height: 100,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      FontAwesomeIcons.house,
                      size: 20,
                      color: Color.fromRGBO(26, 188, 156, 1),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Home",
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: Color.fromRGBO(26, 188, 156, 1),
                      ),
                    ),
                  ],
                ),
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
              child: Container(
                color: Colors.transparent,
                width: 100, 
                height: 100,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Icon(
                      FontAwesomeIcons.bacterium,
                      size: 20,
                      color: Colors.black,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "MoldAI",
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
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
              child: Container(
                color: Colors.transparent,
                width: 100, 
                height: 100,
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
                            height: 20,
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
                      
                      // Scan Statistics Section
                      Text(
                        "Scan Statistics >",
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 10),
                      if (_isLoading)
                        SizedBox(
                          height: 80,
                          child: Center(
                            child: CircularProgressIndicator(
                              color: Color.fromRGBO(26, 188, 156, 1),
                            ),
                          ),
                        )
                      else
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildStatisticsCard(
                              context,
                              _scanStatistics['totalScans'].toString(),
                              "Total Scans",
                              FontAwesomeIcons.bacterium,
                              Color.fromRGBO(26, 188, 156, 1),
                            ),
                            _buildStatisticsCard(
                              context,
                              _scanStatistics['highRiskScans'].toString(),
                              "High Risk",
                              FontAwesomeIcons.triangleExclamation,
                              Color.fromRGBO(244, 67, 54, 1),
                            ),
                            _buildStatisticsCard(
                              context,
                              ((_scanStatistics['totalScans']! - _scanStatistics['highRiskScans']!)).toString(),
                              "Safe Scans",
                              FontAwesomeIcons.shieldHalved,
                              Color.fromRGBO(76, 175, 80, 1),
                            ),
                          ],
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
                                FaIcon(FontAwesomeIcons.bacterium),
                                Text(
                                  "Scan & identify mold",
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
                        "Recent Mold Scans >",
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
                              color: Color.fromRGBO(26, 188, 156, 1),
                            ),
                          ),
                        )
                      else if (_recentScans.isEmpty)
                        _buildEmptyScansPlaceholder()
                      else
                        Column(
                          children: _recentScans
                              .map((scan) => _buildMoldScanItem(scan))
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