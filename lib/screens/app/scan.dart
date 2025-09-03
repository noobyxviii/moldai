// ignore_for_file: unnecessary_import

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';

class FoodScannerScreen extends StatefulWidget {
  final Function(double protein, double fiber) onNutritionUpdate;
  final PageController controller;
  final int pageIndex;

  const FoodScannerScreen({
    super.key,
    required this.onNutritionUpdate,
    required this.controller,
    required this.pageIndex,
  });

  @override
  State<FoodScannerScreen> createState() => _FoodScannerScreenState();
}

class _FoodScannerScreenState extends State<FoodScannerScreen> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  bool _isProcessing = false;
  String? _errorMessage;
  String? _debugMessage; // Add debug message

  // Baby food analysis results
  Map<String, dynamic>? _analysisResults;
  bool _showResults = false;
  String? _capturedImagePath;

  // Baby data
  Map<String, dynamic>? _babyData;

  @override
  void initState() {
    super.initState();
    _loadBabyData();
    _initializeCamera();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _loadBabyData() async {
    try {
      setState(() {
        _debugMessage = "Loading baby data...";
      });

      final prefs = await SharedPreferences.getInstance();
      final allergiesJson = prefs.getString('allergies');
      final age = prefs.getInt('age');
      final weight = prefs.getDouble('weight');

      if (age != null && weight != null) {
        _babyData = {
          'age': age,
          'weight': weight,
          'allergies': allergiesJson != null
              ? json.decode(allergiesJson)
              : <String>[],
          'gender': 'not_specified',
          'height': 70.0,
          'healthConditions': <String>[],
        };
        setState(() {
          _debugMessage = "Baby data loaded successfully";
        });
      } else {
        // Create default baby data for testing
        _babyData = {
          'age': 12, // 12 months default
          'weight': 10.0, // 10kg default
          'allergies': <String>[],
          'gender': 'not_specified',
          'height': 70.0,
          'healthConditions': <String>[],
        };
        setState(() {
          _debugMessage =
              "Using default baby data (age: 12 months, weight: 10kg)";
        });
      }
    } catch (e) {
      if (kDebugMode) {
        if (kDebugMode) {
        print('Error loading baby data: $e');
      }
      }
      // Create fallback data
      _babyData = {
        'age': 12,
        'weight': 10.0,
        'allergies': <String>[],
        'gender': 'not_specified',
        'height': 70.0,
        'healthConditions': <String>[],
      };
      setState(() {
        _debugMessage = "Error loading baby data, using defaults: $e";
      });
    }
  }

  Future<void> _initializeCamera() async {
    try {
      setState(() {
        _debugMessage = "Initializing camera...";
      });

      _cameras = await availableCameras();

      if (_cameras == null || _cameras!.isEmpty) {
        setState(() {
          _errorMessage = 'No cameras available on this device';
          _debugMessage = "No cameras found";
        });
        return;
      }

      final backCamera = _cameras!.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras!.first,
      );

      _cameraController = CameraController(
        backCamera,
        ResolutionPreset.high,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _cameraController!.initialize();

      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
          _debugMessage = "Camera initialized successfully";
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        if (e.toString().contains('permission') ||
            e.toString().contains('Permission')) {
          _errorMessage =
              'Camera permission is required to scan food. Please grant permission and try again.';
        } else {
          _errorMessage = 'Failed to initialize camera: ${e.toString()}';
        }
        _debugMessage = "Camera initialization failed: $e";
      });
    }
  }

Future<void> _captureAndAnalyze() async {
  if (kDebugMode) {
    print("🔥 _captureAndAnalyze called!");
  }

  // Check camera controller
  if (_cameraController == null) {
    if (kDebugMode) {
      print("❌ Camera controller is null");
    }
    setState(() {
      _errorMessage = "Camera controller is null";
      _debugMessage = "Camera controller not initialized";
    });
    return;
  }

  if (!_cameraController!.value.isInitialized) {
    if (kDebugMode) {
      print("❌ Camera is not initialized");
    }
    setState(() {
      _errorMessage = "Camera is not initialized";
      _debugMessage = "Camera not ready";
    });
    return;
  }

  // Check baby data
  if (_babyData == null) {
    if (kDebugMode) {
      print("❌ Baby data is null");
    }
    setState(() {
      _errorMessage = 'Baby data not found. Please set up your baby profile first.';
      _debugMessage = "No baby data available";
    });
    return;
  }

  if (kDebugMode) {
    print("✅ All checks passed, starting capture process");
  }
  
  setState(() {
    _isProcessing = true;
    _errorMessage = null;
    _debugMessage = "Capturing image...";
  });

  XFile? capturedImage;
  String? permanentImagePath;

  try {
    // Capture image
    if (kDebugMode) {
      print("📸 Taking picture...");
    }
    capturedImage = await _cameraController!.takePicture();
    if (kDebugMode) {
      print("✅ Picture taken: ${capturedImage.path}");
    }

    // Add haptic feedback
    HapticFeedback.mediumImpact();

    setState(() {
      _debugMessage = "Image captured, copying to permanent location...";
    });

    // Immediately copy the image to a permanent location
    final appDir = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    permanentImagePath = '${appDir.path}/temp_scan_$timestamp.jpg';

    // Ensure source file exists
    final sourceFile = File(capturedImage.path);
    if (!await sourceFile.exists()) {
      throw Exception("Captured image file does not exist at ${capturedImage.path}");
    }

    // Copy to permanent location immediately
    final permanentFile = File(permanentImagePath);
    await sourceFile.copy(permanentImagePath);

    if (!await permanentFile.exists()) {
      throw Exception("Failed to create permanent copy of image");
    }

    final fileSize = await permanentFile.length();
    if (kDebugMode) {
      print("📁 Permanent image file size: $fileSize bytes at $permanentImagePath");
    }

    setState(() {
      _debugMessage = "Image saved, analyzing...";
    });

    // Send the permanent file for analysis
    if (kDebugMode) {
      print("🌐 Sending to API...");
    }
    final results = await _analyzeBabyFood(permanentFile);
    if (kDebugMode) {
      print("✅ API response received");
    }

    // Save the scan result using the permanent image path
    final finalImagePath = await _saveScanResult(results, permanentImagePath);

    setState(() {
      _analysisResults = results;
      _capturedImagePath = finalImagePath;
      _showResults = true;
      _isProcessing = false;
      _debugMessage = "Analysis completed successfully";
    });

    if (kDebugMode) {
      print("✅ Analysis completed and UI updated");
    }

  } catch (e) {
    if (kDebugMode) {
      print("❌ Error in capture and analyze: $e");
    }
    
    // Clean up temporary file if it was created
    if (permanentImagePath != null) {
      try {
        final tempFile = File(permanentImagePath);
        if (await tempFile.exists()) {
          await tempFile.delete();
        }
      } catch (cleanupError) {
        if (kDebugMode) {
          print("Warning: Failed to cleanup temp file: $cleanupError");
        }
      }
    }

    setState(() {
      _errorMessage = 'Failed to analyze food: ${e.toString()}';
      _isProcessing = false;
      _debugMessage = "Error: $e";
    });
  }
}
  Future<Map<String, dynamic>> _analyzeBabyFood(File imageFile) async {
    const String cloudflareWorkerUrl =
        'https://curly-morning-0115.xviii2008.workers.dev/analyze-baby-food';

    try {
      if (kDebugMode) {
        print("🔗 Connecting to: $cloudflareWorkerUrl");
      }

      // Validate image file first
      if (!await imageFile.exists()) {
        throw Exception('Image file does not exist at path: ${imageFile.path}');
      }

      final imageBytes = await imageFile.readAsBytes();
      if (kDebugMode) {
        print("📊 Image size: ${imageBytes.length} bytes");
      }

      if (imageBytes.isEmpty) {
        throw Exception('Image file is empty');
      }

      if (imageBytes.length > 10 * 1024 * 1024) {
        // 10MB limit
        throw Exception(
          'Image file too large: ${(imageBytes.length / (1024 * 1024)).toStringAsFixed(1)}MB',
        );
      }

      // Validate image format by checking magic bytes
      String imageFormat = 'unknown';
      if (imageBytes.length >= 2) {
        if (imageBytes[0] == 0xFF && imageBytes[1] == 0xD8) {
          imageFormat = 'JPEG';
        } else if (imageBytes.length >= 8 &&
            imageBytes[0] == 0x89 &&
            imageBytes[1] == 0x50 &&
            imageBytes[2] == 0x4E &&
            imageBytes[3] == 0x47) {
          imageFormat = 'PNG';
        }
      }
      if (kDebugMode) {
        print("📷 Image format detected: $imageFormat");
      }

      // Test connection first
      try {
        final testResponse = await http
            .get(Uri.parse(cloudflareWorkerUrl))
            .timeout(const Duration(seconds: 5));
        if (kDebugMode) {
          print("🌐 Test connection status: ${testResponse.statusCode}");
        }
        if (kDebugMode) {
          print("🌐 Test response body: ${testResponse.body}");
        }
      } catch (e) {
        if (kDebugMode) {
          print("⚠️ Test connection failed: $e");
        }
      }

      // Method 1: Try multipart/form-data (original approach)
      if (kDebugMode) {
        print("📤 Trying multipart/form-data request...");
      }
      try {
        final multipartResult = await _sendMultipartRequest(
          cloudflareWorkerUrl,
          imageBytes,
          _babyData!,
        );
        return multipartResult;
      } catch (e) {
        if (kDebugMode) {
          print("❌ Multipart request failed: $e");
        }
      }

      // Method 2: Try Base64 encoded JSON request
      if (kDebugMode) {
        print("📤 Trying Base64 JSON request...");
      }
      try {
        final base64Result = await _sendBase64Request(
          cloudflareWorkerUrl,
          imageBytes,
          _babyData!,
        );
        return base64Result;
      } catch (e) {
        if (kDebugMode) {
          print("❌ Base64 request failed: $e");
        }
      }

      // Method 3: Try simple JSON with smaller image
      if (kDebugMode) {
        print("📤 Trying compressed Base64 request...");
      }
      try {
        // Compress image if it's too large
        Uint8List compressedBytes = imageBytes;
        if (imageBytes.length > 1024 * 1024) {
          // 1MB
          // Simple compression by reducing quality (this is a basic approach)
          if (kDebugMode) {
            print("🗜️ Compressing large image...");
          }
          compressedBytes =
              imageBytes; // You might want to implement actual compression here
        }

        final compressedResult = await _sendBase64Request(
          cloudflareWorkerUrl,
          compressedBytes,
          _babyData!,
        );
        return compressedResult;
      } catch (e) {
        if (kDebugMode) {
          print("❌ Compressed request failed: $e");
        }
        throw Exception(
          'All request methods failed. Last error: ${e.toString()}',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print("❌ Network error: $e");
      }
      throw Exception('Network error: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> _sendMultipartRequest(
    String url,
    Uint8List imageBytes,
    Map<String, dynamic> babyData,
  ) async {
    final request = http.MultipartRequest('POST', Uri.parse(url));

    // Add headers
    request.headers['Content-Type'] = 'multipart/form-data';

    // Add image file
    final multipartFile = http.MultipartFile.fromBytes(
      'image',
      imageBytes,
      filename: 'baby_food_image.jpg',
    );
    request.files.add(multipartFile);

    // Add baby data
    final babyDataJson = json.encode(babyData);
    if (kDebugMode) {
      print("👶 Baby data: $babyDataJson");
    }
    request.fields['babyData'] = babyDataJson;

    // Log request details
    if (kDebugMode) {
      print("📋 Request fields: ${request.fields.keys.toList()}");
    }
    if (kDebugMode) {
      print(
        "📋 Request files: ${request.files.map((f) => '${f.field}: ${f.filename} (${f.length} bytes)').toList()}",
      );
    }

    // Send request with timeout
    final streamedResponse = await request.send().timeout(
      const Duration(seconds: 30),
    );

    final response = await http.Response.fromStream(streamedResponse);
    return _processResponse(response);
  }

  Future<Map<String, dynamic>> _sendBase64Request(
    String url,
    Uint8List imageBytes,
    Map<String, dynamic> babyData,
  ) async {
    final base64Image = base64Encode(imageBytes);
    if (kDebugMode) {
      print("📊 Base64 image length: ${base64Image.length} characters");
    }

    final requestBody = {
      'image': base64Image,
      'babyData': babyData,
      'imageFormat': 'jpeg', // or detect format
    };

    final response = await http
        .post(
          Uri.parse(url),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(requestBody),
        )
        .timeout(const Duration(seconds: 30));

    return _processResponse(response);
  }

  Map<String, dynamic> _processResponse(http.Response response) {
    if (kDebugMode) {
      print("📥 Response status: ${response.statusCode}");
    }
    if (kDebugMode) {
      print("📄 Response headers: ${response.headers}");
    }
    if (kDebugMode) {
      print("📄 Response body length: ${response.body.length}");
    }

    // Log first 500 characters of response for debugging
    final responsePreview = response.body.length > 500
        ? "${response.body.substring(0, 500)}..."
        : response.body;
    if (kDebugMode) {
      print("📄 Response preview: $responsePreview");
    }

    if (response.statusCode == 200) {
      try {
        final Map<String, dynamic> result = json.decode(response.body);
        if (kDebugMode) {
          print("✅ JSON parsed successfully");
        }
        return result;
      } catch (e) {
        if (kDebugMode) {
          print("❌ JSON parsing failed: $e");
        }
        if (kDebugMode) {
          print("Raw response: ${response.body}");
        }
        throw Exception('Invalid JSON response: ${e.toString()}');
      }
    } else if (response.statusCode == 429) {
      throw Exception('Too many requests. Please wait a moment and try again.');
    } else {
      if (kDebugMode) {
        print("❌ API error: ${response.statusCode} - ${response.body}");
      }
      throw Exception('API Error ${response.statusCode}: ${response.body}');
    }
  }

Future<String> _saveScanResult(
  Map<String, dynamic> result,
  String imagePath,
) async {
  try {
    if (kDebugMode) {
      print("💾 Saving scan result...");
    }
    final prefs = await SharedPreferences.getInstance();

    // Get existing scans
    final existingScansJson = prefs.getString('recent_scans');
    List<Map<String, dynamic>> recentScans = [];

    if (existingScansJson != null) {
      final decoded = json.decode(existingScansJson);
      recentScans = List<Map<String, dynamic>>.from(decoded);
    }

    // Check if source image file exists
    final sourceFile = File(imagePath);
    if (!await sourceFile.exists()) {
      if (kDebugMode) {
        print("❌ Source image file does not exist: $imagePath");
      }
      throw Exception('Source image file no longer exists');
    }

    // Save image to app directory
    final appDir = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final savedImagePath = '${appDir.path}/scan_$timestamp.jpg';

    // Ensure the destination directory exists
    final destinationDir = Directory(appDir.path);
    if (!await destinationDir.exists()) {
      await destinationDir.create(recursive: true);
    }

    // Copy the file
    try {
      await sourceFile.copy(savedImagePath);
      if (kDebugMode) {
        print("✅ Image copied successfully to: $savedImagePath");
      }
    } catch (e) {
      if (kDebugMode) {
        print("❌ Failed to copy image: $e");
      }
      // Alternative approach: Read bytes and write to new file
      try {
        final imageBytes = await sourceFile.readAsBytes();
        final destinationFile = File(savedImagePath);
        await destinationFile.writeAsBytes(imageBytes);
        if (kDebugMode) {
          print("✅ Image saved using bytes approach: $savedImagePath");
        }
      } catch (bytesError) {
        if (kDebugMode) {
          print("❌ Bytes approach also failed: $bytesError");
        }
        throw Exception('Failed to save image: $bytesError');
      }
    }

    // Verify the saved file exists
    final savedFile = File(savedImagePath);
    if (!await savedFile.exists()) {
      throw Exception('Saved image file was not created successfully');
    }

    // Create new scan entry
    final newScan = {
      'score': result['score'] ?? 0,
      'productName': result['productName'] ?? 'Unknown Product',
      'manufacturer': result['manufacturer'] ?? '',
      'imagePath': savedImagePath,
      'timestamp': timestamp,
    };

    // Add to beginning of list
    recentScans.insert(0, newScan);

    // Keep only last 3 scans
    if (recentScans.length > 3) {
      // Delete old image files
      for (int i = 3; i < recentScans.length; i++) {
        final oldImagePath = recentScans[i]['imagePath'];
        if (oldImagePath != null) {
          try {
            final oldFile = File(oldImagePath);
            if (await oldFile.exists()) {
              await oldFile.delete();
            }
          } catch (e) {
            if (kDebugMode) {
              print('Error deleting old image: $e');
            }
          }
        }
      }
      recentScans = recentScans.take(3).toList();
    }

    // Save updated scans
    await prefs.setString('recent_scans', json.encode(recentScans));
    if (kDebugMode) {
      print("✅ Scan result saved");
    }
    return savedImagePath;
  } catch (e) {
    if (kDebugMode) {
      print('Error saving scan result: $e');
    }
    throw Exception('Failed to save scan result: ${e.toString()}');
  }
}
  void _confirmResults() async {
    if (_analysisResults != null) {
      try {
        // Extract nutritional data if available
        final nutritionalInfo =
            _analysisResults!['nutritionalInfo'] as Map<String, dynamic>?;
        double protein = 0.0;
        double carbs = 0.0;
        double fats = 0.0;

        if (nutritionalInfo != null) {
          // Parse protein value (e.g., "2-4 g" -> take average)
          final proteinStr = nutritionalInfo['protein']?.toString() ?? '0 g';
          protein = _parseNutritionalValue(proteinStr);

          // Parse carbs value
          final carbsStr = nutritionalInfo['carbs']?.toString() ?? '0 g';
          carbs = _parseNutritionalValue(carbsStr);

          // Parse fats value
          final fatsStr = nutritionalInfo['fat']?.toString() ?? '0 g';
          fats = _parseNutritionalValue(fatsStr);
        }

        await _saveNutritionData(protein, carbs, fats);

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Baby food analysis saved successfully!',
                style: GoogleFonts.poppins(),
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }

        // Reset results and go back to camera
        setState(() {
          _showResults = false;
          _analysisResults = null;
          _capturedImagePath = null;
        });
      } catch (e) {
        setState(() {
          _errorMessage = e.toString();
        });
      }
    }
  }

  Future<void> _saveNutritionData(double protein, double carbs, double fats) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = DateTime.now();
      final todayDateString = "${today.year}-${today.month}-${today.day}";
      const dataKey = 'daily_nutrition_data';
      const dateKey = 'last_saved_date';

      String? lastSavedDate = prefs.getString(dateKey);

      Map<String, dynamic> todayData = {};

      if (lastSavedDate == todayDateString) {
        // Same day, get current values
        final existingDataString = prefs.getString(dataKey);
        if (existingDataString != null) {
          todayData = json.decode(existingDataString);
        }
      }
      // If it's a new day, todayData will be empty, effectively resetting.

      double currentProtein = (todayData['protein'] ?? 0.0).toDouble();
      double currentCarbs = (todayData['carbs'] ?? 0.0).toDouble();
      double currentFats = (todayData['fats'] ?? 0.0).toDouble();

      double newProtein = currentProtein + protein;
      double newCarbs = currentCarbs + carbs;
      double newFats = currentFats + fats;

      todayData['protein'] = newProtein;
      todayData['carbs'] = newCarbs;
      todayData['fats'] = newFats;

      await prefs.setString(dataKey, json.encode(todayData));
      await prefs.setString(dateKey, todayDateString);

      // Update the callback to pass the correct values
      widget.onNutritionUpdate(newProtein, newCarbs); // Or adjust as needed
    } catch (e) {
      throw Exception('Failed to save nutrition data: ${e.toString()}');
    }
  }
  double _parseNutritionalValue(String value) {
    try {
      // Remove 'g' and other units, handle ranges like "2-4 g"
      final cleanValue = value.replaceAll(RegExp(r'[^\d.-]'), '');
      if (cleanValue.contains('-')) {
        final parts = cleanValue.split('-');
        if (parts.length == 2) {
          final min = double.tryParse(parts[0]) ?? 0.0;
          final max = double.tryParse(parts[1]) ?? 0.0;
          return (min + max) / 2; // Return average
        }
      }
      return double.tryParse(cleanValue) ?? 0.0;
    } catch (e) {
      return 0.0;
    }
  }

  void _retakePhoto() {
    setState(() {
      _showResults = false;
      _analysisResults = null;
      _capturedImagePath = null;
    });
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return const Color(0xFF4CAF50); // Green
    if (score >= 60) return const Color(0xFFFFC107); // Amber
    return const Color(0xFFF44336); // Red
  }


  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera Preview or Results
          if (_showResults && _analysisResults != null)
            _buildResultsView(size)
          else if (_isCameraInitialized && _cameraController != null)
            _buildCameraView()
          else
            _buildLoadingOrErrorView(),

          // Top Bar
          SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (!_showResults) ...[
                    GestureDetector(
                      onTap: () {
                        widget.controller.animateToPage(
                          widget.pageIndex - 1,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: Color.fromRGBO(0, 0, 0, 0.5),
                          shape: BoxShape.circle,
                        ),
                        child: FaIcon(
                          FontAwesomeIcons.xmark,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                    Text(
                      'Totsy',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Capture Button or Results Actions
          if (!_showResults) _buildCaptureButton(),

          // Processing Overlay
          if (_isProcessing)
            Container(
              // ignore: deprecated_member_use
              color: Colors.black.withOpacity(0.7),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(
                      color: Color.fromRGBO(63, 114, 66, 1),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _debugMessage ?? 'Analyzing baby food...',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCameraView() {
    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: Stack(
        children: [
          CameraPreview(_cameraController!),
          // Grid overlay
          CustomPaint(painter: GridPainter(), size: Size.infinite),
          // Instruction text
          Positioned(
            top: 175,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'Align your baby food with the frame',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  shadows: [
                    Shadow(
                      offset: const Offset(0, 1),
                      blurRadius: 3,
                      color: Color.fromRGBO(0, 0, 0, 0.5),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsView(size) {
    final score = _analysisResults!['score'] ?? 0;
    final productName = _analysisResults!['productName'] ?? 'Unknown Product';
    final manufacturer = _analysisResults!['manufacturer'] ?? '';
    final summary = _analysisResults!['summary'] ?? 'Analysis completed';
    final nutritionalInfo =
        _analysisResults!['nutritionalInfo'] as Map<String, dynamic>?;

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Color.fromRGBO(243, 243, 243, 1),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(size.width * 0.05),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: size.width * 0.05),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Image.asset('assets/logo_transparent.png', height: 30),
                ],
              ),
              const SizedBox(height: 25),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_capturedImagePath != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        File(_capturedImagePath!),
                        width: 150,
                        height: 150,
                        fit: BoxFit.cover,
                      ),
                    )
                  else
                    Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.image_not_supported,
                        color: Colors.grey[400],
                        size: 48,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 25),
              Text(
                'Scan Results >',
                textAlign: TextAlign.left,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        productName,
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),
                      ),
                      if (manufacturer.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          manufacturer,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.black,
                          ),
                        ),
                      ],

                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Protein",
                                textAlign: TextAlign.left,
                                style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  color: Colors.black,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: 5),
                              Text(
                                "Fat",
                                textAlign: TextAlign.left,
                                style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  color: Colors.black,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: 5),
                              Text(
                                "Carbs",
                                textAlign: TextAlign.left,
                                style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  color: Colors.black,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: 5),
                              Text(
                                "Fiber",
                                textAlign: TextAlign.left,
                                style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  color: Colors.black,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                nutritionalInfo?["protein"] ?? "0g",
                                textAlign: TextAlign.left,
                                style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  color: Colors.black,
                                ),
                              ),
                              SizedBox(height: 5),
                              Text(
                                nutritionalInfo?["fat"] ?? "0g",
                                textAlign: TextAlign.left,
                                style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  color: Colors.black,
                                ),
                              ),
                              SizedBox(height: 5),
                              Text(
                                nutritionalInfo?["carbs"] ?? "0g",
                                textAlign: TextAlign.left,
                                style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  color: Colors.black,
                                ),
                              ),
                              SizedBox(height: 5),
                              Text(
                                nutritionalInfo?["fiber"] ?? "0g",
                                textAlign: TextAlign.left,
                                style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                width: 120,
                                height: 120,
                                child: CircularProgressIndicator(
                                  value: score / 100,
                                  color: _getScoreColor(score),
                                  strokeWidth: 8,
                                  backgroundColor: Color.fromRGBO(
                                    230,
                                    230,
                                    230,
                                    1,
                                  ),
                                ),
                              ),
                              Column(
                                children: [
                                  Text(
                                    score.toString(),
                                    style: GoogleFonts.poppins(
                                      fontSize: 30,
                                      fontWeight: FontWeight.w700,
                                      color: _getScoreColor(score),
                                      height: 1.0,
                                    ),
                                  ),
                                  Text(
                                    "out of 100",
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: _getScoreColor(score),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: 20,),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Text(
                            summary,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 25),
              _buildResultsActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultsActions() {
    return Positioned(
      bottom: 50,
      left: 20,
      right: 20,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Retake Button
          GestureDetector(
            onTap: _retakePhoto,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(50),
              ),
              child: Text(
                'Retake',
                style: GoogleFonts.poppins(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          // Confirm Button
          GestureDetector(
            onTap: _confirmResults,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              decoration: BoxDecoration(
                color: const Color.fromRGBO(63, 114, 66, 1),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Text(
                'Save Results',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCaptureButton() {
    return Positioned(
      bottom: 50,
      left: 0,
      right: 0,
      child: Center(
        child: GestureDetector(
          onTap: () {
            if (kDebugMode) {
              print("🔥 Camera button tapped! Processing: $_isProcessing");
            }
            if (!_isProcessing) {
              _captureAndAnalyze();
            }
          },
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _isProcessing ? Colors.grey : Colors.white,
              border: Border.all(
                color: _isProcessing
                    ? Colors.grey
                    : Color.fromRGBO(63, 114, 66, 1),
                width: 4,
              ),
            ),
            child: Center(
              child: _isProcessing
                  ? const SizedBox(
                      width: 25,
                      height: 25,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color.fromRGBO(63, 114, 66, 1)
                        ),
                      ),
                    )
                  : const FaIcon(
                      FontAwesomeIcons.camera,
                      size: 25,
                      color: Color.fromRGBO(63, 114, 66, 1),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingOrErrorView() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_errorMessage != null) ...[
              Icon(Icons.error_outline, color: Colors.red, size: 64),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 16),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _initializeCamera,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromRGBO(63, 114, 66, 1),
                ),
                child: Text(
                  'Retry',
                  style: GoogleFonts.poppins(color: Colors.white),
                ),
              ),
            ] else ...[
              const CircularProgressIndicator(
                color: Color.fromRGBO(63, 114, 66, 1)
              ),
              const SizedBox(height: 20),
              Text(
                _debugMessage ?? 'Initializing camera...',
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 16),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Add test button for debugging (only in debug mode)
}

// Custom painter for grid overlay
class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Color.fromRGBO(255, 255, 255, 0.5)
      ..strokeWidth = 1;

    // Draw grid lines
    final double cellWidth = size.width / 3;
    final double cellHeight = size.height / 3;

    // Vertical lines
    for (int i = 1; i < 3; i++) {
      canvas.drawLine(
        Offset(i * cellWidth, 0),
        Offset(i * cellWidth, size.height),
        paint,
      );
    }

    // Horizontal lines
    for (int i = 1; i < 3; i++) {
      canvas.drawLine(
        Offset(0, i * cellHeight),
        Offset(size.width, i * cellHeight),
        paint,
      );
    }

    // Center focus frame
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final frameSize = size.width * 0.6;
    final frameRect = Rect.fromCenter(
      center: Offset(centerX, centerY),
      width: frameSize,
      height: frameSize * 0.75,
    );

    final framePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    canvas.drawRRect(
      RRect.fromRectAndRadius(frameRect, const Radius.circular(15)),
      framePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
