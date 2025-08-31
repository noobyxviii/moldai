import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
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
          'allergies': allergiesJson != null ? json.decode(allergiesJson) : <String>[],
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
          _debugMessage = "Using default baby data (age: 12 months, weight: 10kg)";
        });
      }
    } catch (e) {
      print('Error loading baby data: $e');
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
    print("🔥 _captureAndAnalyze called!"); // Debug print
    
    // Check camera controller
    if (_cameraController == null) {
      print("❌ Camera controller is null");
      setState(() {
        _errorMessage = "Camera controller is null";
        _debugMessage = "Camera controller not initialized";
      });
      return;
    }

    if (!_cameraController!.value.isInitialized) {
      print("❌ Camera is not initialized");
      setState(() {
        _errorMessage = "Camera is not initialized";
        _debugMessage = "Camera not ready";
      });
      return;
    }

    // Check baby data
    if (_babyData == null) {
      print("❌ Baby data is null");
      setState(() {
        _errorMessage = 'Baby data not found. Please set up your baby profile first.';
        _debugMessage = "No baby data available";
      });
      return;
    }

    print("✅ All checks passed, starting capture process");
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
      _debugMessage = "Capturing image...";
    });

    try {
      // Capture image
      print("📸 Taking picture...");
      final XFile image = await _cameraController!.takePicture();
      print("✅ Picture taken: ${image.path}");

      // Add haptic feedback
      HapticFeedback.mediumImpact();

      setState(() {
        _debugMessage = "Image captured, analyzing...";
      });

      // Check if file exists
      final file = File(image.path);
      if (!await file.exists()) {
        throw Exception("Captured image file does not exist");
      }

      final fileSize = await file.length();
      print("📁 Image file size: $fileSize bytes");

      // Send to Cloudflare Worker for analysis
      print("🌐 Sending to API...");
      final results = await _analyzeBabyFood(file);
      print("✅ API response received");

      // Save the scan result and image
      await _saveScanResult(results, image.path);

      setState(() {
        _analysisResults = results;
        _showResults = true;
        _isProcessing = false;
        _debugMessage = "Analysis completed successfully";
      });

      print("✅ Analysis completed and UI updated");

    } catch (e) {
      print("❌ Error in capture and analyze: $e");
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
      print("🔗 Connecting to: $cloudflareWorkerUrl");
      
      // Validate image file first
      if (!await imageFile.exists()) {
        throw Exception('Image file does not exist at path: ${imageFile.path}');
      }
      
      final imageBytes = await imageFile.readAsBytes();
      print("📊 Image size: ${imageBytes.length} bytes");
      
      if (imageBytes.isEmpty) {
        throw Exception('Image file is empty');
      }
      
      if (imageBytes.length > 10 * 1024 * 1024) { // 10MB limit
        throw Exception('Image file too large: ${(imageBytes.length / (1024 * 1024)).toStringAsFixed(1)}MB');
      }

      // Validate image format by checking magic bytes
      String imageFormat = 'unknown';
      if (imageBytes.length >= 2) {
        if (imageBytes[0] == 0xFF && imageBytes[1] == 0xD8) {
          imageFormat = 'JPEG';
        } else if (imageBytes.length >= 8 && 
                   imageBytes[0] == 0x89 && imageBytes[1] == 0x50 && 
                   imageBytes[2] == 0x4E && imageBytes[3] == 0x47) {
          imageFormat = 'PNG';
        }
      }
      print("📷 Image format detected: $imageFormat");

      // Test connection first
      try {
        final testResponse = await http.get(Uri.parse(cloudflareWorkerUrl)).timeout(
          const Duration(seconds: 5),
        );
        print("🌐 Test connection status: ${testResponse.statusCode}");
        print("🌐 Test response body: ${testResponse.body}");
      } catch (e) {
        print("⚠️ Test connection failed: $e");
      }

      // Method 1: Try multipart/form-data (original approach)
      print("📤 Trying multipart/form-data request...");
      try {
        final multipartResult = await _sendMultipartRequest(cloudflareWorkerUrl, imageBytes, _babyData!);
        return multipartResult;
      } catch (e) {
        print("❌ Multipart request failed: $e");
      }

      // Method 2: Try Base64 encoded JSON request
      print("📤 Trying Base64 JSON request...");
      try {
        final base64Result = await _sendBase64Request(cloudflareWorkerUrl, imageBytes, _babyData!);
        return base64Result;
      } catch (e) {
        print("❌ Base64 request failed: $e");
      }

      // Method 3: Try simple JSON with smaller image
      print("📤 Trying compressed Base64 request...");
      try {
        // Compress image if it's too large
        Uint8List compressedBytes = imageBytes;
        if (imageBytes.length > 1024 * 1024) { // 1MB
          // Simple compression by reducing quality (this is a basic approach)
          print("🗜️ Compressing large image...");
          compressedBytes = imageBytes; // You might want to implement actual compression here
        }
        
        final compressedResult = await _sendBase64Request(cloudflareWorkerUrl, compressedBytes, _babyData!);
        return compressedResult;
      } catch (e) {
        print("❌ Compressed request failed: $e");
        throw Exception('All request methods failed. Last error: ${e.toString()}');
      }

    } catch (e) {
      print("❌ Network error: $e");
      throw Exception('Network error: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> _sendMultipartRequest(
    String url, 
    Uint8List imageBytes, 
    Map<String, dynamic> babyData
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
    print("👶 Baby data: $babyDataJson");
    request.fields['babyData'] = babyDataJson;

    // Log request details
    print("📋 Request fields: ${request.fields.keys.toList()}");
    print("📋 Request files: ${request.files.map((f) => '${f.field}: ${f.filename} (${f.length} bytes)').toList()}");

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
    Map<String, dynamic> babyData
  ) async {
    final base64Image = base64Encode(imageBytes);
    print("📊 Base64 image length: ${base64Image.length} characters");
    
    final requestBody = {
      'image': base64Image,
      'babyData': babyData,
      'imageFormat': 'jpeg', // or detect format
    };

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
      },
      body: json.encode(requestBody),
    ).timeout(const Duration(seconds: 30));
    
    return _processResponse(response);
  }

  Map<String, dynamic> _processResponse(http.Response response) {
    print("📥 Response status: ${response.statusCode}");
    print("📄 Response headers: ${response.headers}");
    print("📄 Response body length: ${response.body.length}");
    
    // Log first 500 characters of response for debugging
    final responsePreview = response.body.length > 500 
        ? response.body.substring(0, 500) + "..." 
        : response.body;
    print("📄 Response preview: $responsePreview");

    if (response.statusCode == 200) {
      try {
        final Map<String, dynamic> result = json.decode(response.body);
        print("✅ JSON parsed successfully");
        return result;
      } catch (e) {
        print("❌ JSON parsing failed: $e");
        print("Raw response: ${response.body}");
        throw Exception('Invalid JSON response: ${e.toString()}');
      }
    } else if (response.statusCode == 429) {
      throw Exception('Too many requests. Please wait a moment and try again.');
    } else {
      print("❌ API error: ${response.statusCode} - ${response.body}");
      throw Exception('API Error ${response.statusCode}: ${response.body}');
    }
  }

  Future<void> _saveScanResult(Map<String, dynamic> result, String imagePath) async {
    try {
      print("💾 Saving scan result...");
      final prefs = await SharedPreferences.getInstance();
      
      // Get existing scans
      final existingScansJson = prefs.getString('recent_scans');
      List<Map<String, dynamic>> recentScans = [];
      
      if (existingScansJson != null) {
        final decoded = json.decode(existingScansJson);
        recentScans = List<Map<String, dynamic>>.from(decoded);
      }

      // Save image to app directory
      final appDir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final savedImagePath = '${appDir.path}/scan_$timestamp.jpg';
      
      final imageFile = File(imagePath);
      await imageFile.copy(savedImagePath);

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
              print('Error deleting old image: $e');
            }
          }
        }
        recentScans = recentScans.take(3).toList();
      }

      // Save updated scans
      await prefs.setString('recent_scans', json.encode(recentScans));
      print("✅ Scan result saved");
    } catch (e) {
      print('Error saving scan result: $e');
    }
  }

  void _confirmResults() async {
    if (_analysisResults != null) {
      try {
        // Extract nutritional data if available
        final nutritionalInfo = _analysisResults!['nutritionalInfo'] as Map<String, dynamic>?;
        double protein = 0.0;
        double fiber = 0.0;

        if (nutritionalInfo != null) {
          // Parse protein value (e.g., "2-4 g" -> take average)
          final proteinStr = nutritionalInfo['protein']?.toString() ?? '0 g';
          protein = _parseNutritionalValue(proteinStr);
          
          // Parse fiber value
          final fiberStr = nutritionalInfo['fiber']?.toString() ?? '0 g';
          fiber = _parseNutritionalValue(fiberStr);
        }

        await _saveNutritionData(protein, fiber);

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
        });
      } catch (e) {
        setState(() {
          _errorMessage = e.toString();
        });
      }
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

  Future<void> _saveNutritionData(double protein, double fiber) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = DateTime.now();
      final todayWeekday = today.weekday % 7;
      final todayKey = 'day_$todayWeekday';

      Map<String, dynamic> todayData = {};
      final existingDataString = prefs.getString(todayKey);
      if (existingDataString != null) {
        todayData = json.decode(existingDataString);
      }

      double currentProtein = (todayData['protein'] ?? 0.0).toDouble();
      double currentFiber = (todayData['fiber'] ?? 0.0).toDouble();

      double newProtein = currentProtein + protein;
      double newFiber = currentFiber + fiber;

      todayData['protein'] = newProtein;
      todayData['fiber'] = newFiber;

      await prefs.setString(todayKey, json.encode(todayData));
      widget.onNutritionUpdate(newProtein, newFiber);
    } catch (e) {
      throw Exception('Failed to save nutrition data: ${e.toString()}');
    }
  }

  void _retakePhoto() {
    setState(() {
      _showResults = false;
      _analysisResults = null;
    });
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return const Color(0xFF4CAF50); // Green
    if (score >= 60) return const Color(0xFFFFC107); // Amber
    return const Color(0xFFF44336); // Red
  }

  String _getVerdictText(String verdict) {
    switch (verdict.toLowerCase()) {
      case 'excellent': return 'Excellent';
      case 'good': return 'Good';
      case 'okay': return 'Okay';
      case 'poor': return 'Poor';
      case 'unsafe': return 'Unsafe';
      default: return 'Unknown';
    }
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
            _buildResultsView()
          else if (_isCameraInitialized && _cameraController != null)
            _buildCameraView()
          else
            _buildLoadingOrErrorView(),

          // Debug Message Overlay
          if (_debugMessage != null && kDebugMode)
            Positioned(
              top: 120,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'DEBUG: $_debugMessage',
                  style: GoogleFonts.poppins(
                    color: Colors.yellow,
                    fontSize: 12,
                  ),
                ),
              ),
            ),

          // Top Bar
          SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
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
                  if (!_showResults)
                    Text(
                      'Totsy',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Capture Button or Results Actions
          if (_showResults) _buildResultsActions() else _buildCaptureButton(),

          // Test Button (debug mode only)
          _buildTestButton(),

          // Processing Overlay
          if (_isProcessing)
            Container(
              color: Colors.black.withOpacity(0.7),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(
                      color: Color.fromRGBO(255, 128, 140, 1),
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
            top: 100,
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
                      color: Colors.black.withOpacity(0.5),
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

  Widget _buildResultsView() {
    final score = _analysisResults!['score'] ?? 0;
    final productName = _analysisResults!['productName'] ?? 'Unknown Product';
    final manufacturer = _analysisResults!['manufacturer'] ?? '';
    final verdict = _analysisResults!['verdict'] ?? 'okay';
    final summary = _analysisResults!['summary'] ?? 'Analysis completed';
    final nutritionalInfo = _analysisResults!['nutritionalInfo'] as Map<String, dynamic>?;

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: const Color(0xFFF5F5F5),
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF34D399),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Scan Results',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Image Placeholder
                    Container(
                      width: double.infinity,
                      height: 120,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F4FD),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.baby_changing_station,
                        size: 48,
                        color: Color(0xFF64B5F6),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Product Name and Brand
                    Text(
                      productName,
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                    if (manufacturer.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        manufacturer,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),

                    // Score Circle
                    Center(
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _getScoreColor(score),
                            width: 6,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            score.toString(),
                            style: GoogleFonts.poppins(
                              fontSize: 32,
                              fontWeight: FontWeight.w700,
                              color: _getScoreColor(score),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Nutritional Info
                    if (nutritionalInfo != null) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildNutrientInfo(
                            'Protein',
                            nutritionalInfo['protein'] ?? '0g',
                          ),
                          _buildNutrientInfo(
                            'Fats',
                            nutritionalInfo['fat'] ?? '0g',
                          ),
                          _buildNutrientInfo(
                            'Carbs',
                            nutritionalInfo['carbs'] ?? '0g',
                          ),
                          _buildNutrientInfo(
                            'Fiber',
                            nutritionalInfo['fiber'] ?? '0g',
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Overview Section
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F9FA),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Overview',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '0 Risks',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            summary,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey[700],
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Spacer(),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildNutrientInfo(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ],
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
                color: const Color.fromRGBO(255, 128, 140, 1),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Text(
                'Retake',
                style: GoogleFonts.poppins(
                  color: Colors.white,
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
                color: const Color.fromRGBO(63, 177, 151, 1),
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
            print("🔥 Camera button tapped! Processing: $_isProcessing");
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
                    : Color.fromRGBO(63, 166, 66, 1),
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
                          Color.fromRGBO(63, 166, 66, 1),
                        ),
                      ),
                    )
                  : const FaIcon(
                      FontAwesomeIcons.camera,
                      size: 25,
                      color: Color.fromRGBO(63, 166, 66, 1),
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
                  backgroundColor: const Color.fromRGBO(255, 128, 140, 1),
                ),
                child: Text(
                  'Retry',
                  style: GoogleFonts.poppins(color: Colors.white),
                ),
              ),
            ] else ...[
              const CircularProgressIndicator(
                color: Color.fromRGBO(255, 128, 140, 1),
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
  Widget _buildTestButton() {
    if (!kDebugMode) return const SizedBox.shrink();
    
    return Positioned(
      top: 200,
      right: 20,
      child: ElevatedButton(
        onPressed: () async {
          print("🧪 Test button pressed");
          
          // Create a mock result for testing
          final mockResult = {
            'score': 85,
            'productName': 'Test Baby Food',
            'manufacturer': 'Test Brand',
            'verdict': 'excellent',
            'summary': 'This is a test analysis result for debugging purposes.',
            'nutritionalInfo': {
              'protein': '2.5g',
              'fat': '1.2g',
              'carbs': '8.5g',
              'fiber': '1.8g',
            }
          };
          
          setState(() {
            _analysisResults = mockResult;
            _showResults = true;
            _debugMessage = "Mock result loaded for testing";
          });
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        child: Text(
          'TEST',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

// Custom painter for grid overlay
class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.5)
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