import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class InfoScreen extends StatefulWidget {
  final PageController controller;
  final int pageIndex;
  const InfoScreen({
    super.key,
    required this.controller,
    required this.pageIndex,
  });

  @override
  State<InfoScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<InfoScreen> {
  String? _selectedWeight;
  String? _selectedAge;
  List<String> _selectedAllergies = [];

  // Weight options (in pounds and kg)
  final List<String> _weightOptions = [
    '5-7 lbs (2.3-3.2 kg)',
    '8-10 lbs (3.6-4.5 kg)',
    '11-13 lbs (5.0-5.9 kg)',
    '14-16 lbs (6.4-7.3 kg)',
    '17-19 lbs (7.7-8.6 kg)',
    '20-22 lbs (9.1-10.0 kg)',
    '23-25 lbs (10.4-11.3 kg)',
    '26-28 lbs (11.8-12.7 kg)',
    '29-31 lbs (13.2-14.1 kg)',
    '32+ lbs (14.5+ kg)',
  ];

  // Age options
  final List<String> _ageOptions = [
    '0-2 months',
    '3-5 months',
    '6-8 months',
    '9-11 months',
    '12-18 months',
    '19-24 months',
    '2-3 years',
    '3-4 years',
    '4-5 years',
    '5+ years',
  ];

  // Common baby/child allergies
  final List<String> _allergyOptions = [
    'Milk/Dairy',
    'Eggs',
    'Peanuts',
    'Tree nuts',
    'Soy',
    'Wheat/Gluten',
    'Fish',
    'Shellfish',
    'Sesame',
    'No known allergies',
  ];

  bool _isFormComplete() {
    return _selectedWeight != null && 
           _selectedAge != null && 
           _selectedAllergies.isNotEmpty;
  }

  Future<void> _saveBabyData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Parse weight (extract first number from range like "5-7 lbs (2.3-3.2 kg)")
      double weight = 10.0; // default
      if (_selectedWeight != null) {
        final weightMatch = RegExp(r'\(([0-9.]+)-?[0-9.]*\s*kg\)').firstMatch(_selectedWeight!);
        if (weightMatch != null) {
          weight = double.tryParse(weightMatch.group(1)!) ?? 10.0;
        }
      }
      
      // Parse age (convert to months)
      int ageInMonths = 12; // default
      if (_selectedAge != null) {
        if (_selectedAge!.contains('months')) {
          final monthMatch = RegExp(r'(\d+)-?(\d+)?\s*months').firstMatch(_selectedAge!);
          if (monthMatch != null) {
            final minMonths = int.tryParse(monthMatch.group(1)!) ?? 12;
            final maxMonths = int.tryParse(monthMatch.group(2) ?? monthMatch.group(1)!) ?? minMonths;
            ageInMonths = ((minMonths + maxMonths) / 2).round();
          }
        } else if (_selectedAge!.contains('years')) {
          final yearMatch = RegExp(r'(\d+)-?(\d+)?\s*years').firstMatch(_selectedAge!);
          if (yearMatch != null) {
            final minYears = int.tryParse(yearMatch.group(1)!) ?? 1;
            final maxYears = int.tryParse(yearMatch.group(2) ?? yearMatch.group(1)!) ?? minYears;
            ageInMonths = ((minYears + maxYears) / 2 * 12).round();
          }
        }
      }
      
      // Save individual values that the FoodScannerScreen expects
      await prefs.setInt('age', ageInMonths);
      await prefs.setDouble('weight', weight);
      await prefs.setString('allergies', json.encode(_selectedAllergies));
      
      // Also save the raw selections for future reference
      await prefs.setString('selected_weight', _selectedWeight ?? '');
      await prefs.setString('selected_age', _selectedAge ?? '');
      
      print('Baby data saved: age=$ageInMonths months, weight=$weight kg, allergies=$_selectedAllergies');
      
    } catch (e) {
      print('Error saving baby data: $e');
      throw Exception('Failed to save baby data: $e');
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
                        height: 7.5,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.all(Radius.circular(20)),
                          color: Color.fromRGBO(230, 230, 230, 1),
                        ),
                      ),
                      Container(
                        width: (deviceWidth * 0.9 - 120) * (6 / 7),
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
              Text(
                "Provide some info about your little one.",
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
                "This data is stored securely and will only be used to personalize your experience.",
                textAlign: TextAlign.left,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w400,
                  color: Colors.black,
                  height: 1.2,
                  letterSpacing: -0.5,
                ),
              ),
              
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(top: 40, bottom: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Weight Dropdown
                      Text(
                        "Baby's Weight",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: 10),
                      Container(
                        width: deviceWidth * 0.9,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Color.fromRGBO(255, 255, 255, 1),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: Color.fromRGBO(230, 230, 230, 1),
                            width: 1,
                          ),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedWeight,
                            hint: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 15),
                              child: Text(
                                'Select weight range',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),
                            isExpanded: true,
                            dropdownColor: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            icon: Padding(
                              padding: EdgeInsets.only(right: 15),
                              child: Icon(Icons.keyboard_arrow_down, color: Colors.grey[600]),
                            ),
                            selectedItemBuilder: (BuildContext context) {
                              return _weightOptions.map<Widget>((String item) {
                                return Align(
                                  alignment: Alignment.centerLeft,
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 15),
                                    child: Text(
                                      item,
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        color: Colors.black,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList();
                            },
                            items: _weightOptions.map((String weight) {
                              return DropdownMenuItem<String>(
                                value: weight,
                                child: Container(
                                  padding: EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                                  child: Text(
                                    weight,
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      color: Colors.black,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                HapticFeedback.lightImpact();
                                _selectedWeight = newValue;
                              });
                            },
                          ),
                        ),
                      ),

                      SizedBox(height: 25),
                      
                      // Age Dropdown
                      Text(
                        "Baby's Age",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: 10),
                      Container(
                        width: deviceWidth * 0.9,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Color.fromRGBO(255, 255, 255, 1),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: Color.fromRGBO(230, 230, 230, 1),
                            width: 1,
                          ),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedAge,
                            hint: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 15),
                              child: Text(
                                'Select age range',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),
                            isExpanded: true,
                            dropdownColor: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            icon: Padding(
                              padding: EdgeInsets.only(right: 15),
                              child: Icon(Icons.keyboard_arrow_down, color: Colors.grey[600]),
                            ),
                            selectedItemBuilder: (BuildContext context) {
                              return _ageOptions.map<Widget>((String item) {
                                return Align(
                                  alignment: Alignment.centerLeft,
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 15),
                                    child: Text(
                                      item,
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        color: Colors.black,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList();
                            },
                            items: _ageOptions.map((String age) {
                              return DropdownMenuItem<String>(
                                value: age,
                                child: Container(
                                  padding: EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                                  child: Text(
                                    age,
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      color: Colors.black,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                HapticFeedback.lightImpact();
                                _selectedAge = newValue;
                              });
                            },
                          ),
                        ),
                      ),

                      SizedBox(height: 25),
                      
                      // Allergies Section
                      Text(
                        "Known Allergies (Select all that apply)",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: 10),
                      
                      // Allergies multi-select
                      Container(
                        width: deviceWidth * 0.9,
                        decoration: BoxDecoration(
                          color: Color.fromRGBO(255, 255, 255, 1),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: Color.fromRGBO(230, 230, 230, 1),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          children: _allergyOptions.map((allergy) {
                            final isSelected = _selectedAllergies.contains(allergy);
                            final isNoAllergies = allergy == 'No known allergies';
                            
                            return InkWell(
                              onTap: () {
                                setState(() {
                                  HapticFeedback.lightImpact();
                                  if (isNoAllergies) {
                                    // If "No known allergies" is selected, clear all others
                                    if (isSelected) {
                                      _selectedAllergies.remove(allergy);
                                    } else {
                                      _selectedAllergies.clear();
                                      _selectedAllergies.add(allergy);
                                    }
                                  } else {
                                    // If any specific allergy is selected, remove "No known allergies"
                                    if (isSelected) {
                                      _selectedAllergies.remove(allergy);
                                    } else {
                                      _selectedAllergies.remove('No known allergies');
                                      _selectedAllergies.add(allergy);
                                    }
                                  }
                                });
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                                decoration: BoxDecoration(
                                  border: _allergyOptions.indexOf(allergy) < _allergyOptions.length - 1
                                      ? Border(bottom: BorderSide(color: Color.fromRGBO(240, 240, 240, 1)))
                                      : null,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 20,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: isSelected ? Colors.black : Colors.grey[400]!,
                                          width: 2,
                                        ),
                                        borderRadius: BorderRadius.circular(3),
                                        color: isSelected ? Colors.black : Colors.transparent,
                                      ),
                                      child: isSelected
                                          ? Icon(
                                              Icons.check,
                                              size: 14,
                                              color: Colors.white,
                                            )
                                          : null,
                                    ),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        allergy,
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(
                width: double.infinity,
                height: 75,
                child: ElevatedButton(
                  onPressed: () async {
                    if (_isFormComplete()) {
                      HapticFeedback.lightImpact();
                      
                      try {
                        // Save baby data to SharedPreferences
                        await _saveBabyData();
                        
                        // Navigate to next page
                        widget.controller.animateToPage(
                          widget.pageIndex + 1,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      } catch (e) {
                        // Show error message if saving fails
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Error saving data: ${e.toString()}',
                                style: GoogleFonts.poppins(),
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isFormComplete()
                        ? Colors.black
                        : Color.fromRGBO(120, 120, 120, 1),
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