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

class MoldScannerScreen extends StatefulWidget {
  final PageController controller;
  final int pageIndex;

  const MoldScannerScreen({
    super.key,
    required this.controller,
    required this.pageIndex,
  });

  @override
  State<MoldScannerScreen> createState() => _MoldScannerScreenState();
}

class _MoldScannerScreenState extends State<MoldScannerScreen> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  bool _isProcessing = false;
  String? _errorMessage;
  String? _debugMessage;

  // Mold analysis results
  Map<String, dynamic>? _analysisResults;
  bool _showResults = false;
  String? _capturedImagePath;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
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
        enableAudio: false
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
              'Camera permission is required to scan mold. Please grant permission and try again.';
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
        _debugMessage = "Image saved, analyzing mold...";
      });

      // Send the permanent file for analysis
      if (kDebugMode) {
        print("🌐 Sending to API...");
      }
      final results = await _analyzeMold(permanentFile);
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
        _errorMessage = 'Failed to analyze mold: ${e.toString()}';
        _isProcessing = false;
        _debugMessage = "Error: $e";
      });
    }
  }

  Future<Map<String, dynamic>> _analyzeMold(File imageFile) async {
    const String cloudflareWorkerUrl =
        'https://falling-wave-38ac.xviii2008.workers.dev/analyze-mold';

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
          if (kDebugMode) {
            print("🗜️ Compressing large image...");
          }
          compressedBytes = imageBytes; // You might want to implement actual compression here
        }

        final compressedResult = await _sendBase64Request(
          cloudflareWorkerUrl,
          compressedBytes,
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
  ) async {
    final request = http.MultipartRequest('POST', Uri.parse(url));

    // Add headers
    request.headers['Content-Type'] = 'multipart/form-data';

    // Add image file
    final multipartFile = http.MultipartFile.fromBytes(
      'image',
      imageBytes,
      filename: 'mold_image.jpg',
    );
    request.files.add(multipartFile);

    // Log request details
    if (kDebugMode) {
      print("📋 Request files: ${request.files.map((f) => '${f.field}: ${f.filename} (${f.length} bytes)').toList()}");
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
  ) async {
    final base64Image = base64Encode(imageBytes);
    if (kDebugMode) {
      print("📊 Base64 image length: ${base64Image.length} characters");
    }

    final requestBody = {
      'image': base64Image,
      'imageFormat': 'jpeg',
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

  // NEW: Method to update scan statistics
  Future<void> _updateScanStatistics(int harmScale) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get current total scans count
      final totalScans = prefs.getInt('total_scans_count') ?? 0;
      
      // Get current high-risk scans count (75+ rating)
      final highRiskScans = prefs.getInt('high_risk_scans_count') ?? 0;
      
      // Increment total scans
      final newTotalScans = totalScans + 1;
      await prefs.setInt('total_scans_count', newTotalScans);
      
      // Increment high-risk scans if harm scale is 75 or higher
      if (harmScale >= 75) {
        final newHighRiskScans = highRiskScans + 1;
        await prefs.setInt('high_risk_scans_count', newHighRiskScans);
        
        if (kDebugMode) {
          print("📊 Updated statistics: Total: $newTotalScans, High-Risk: $newHighRiskScans");
        }
      } else {
        if (kDebugMode) {
          print("📊 Updated statistics: Total: $newTotalScans, High-Risk: $highRiskScans (no change)");
        }
      }
      
    } catch (e) {
      if (kDebugMode) {
        print("❌ Error updating scan statistics: $e");
      }
      // Don't throw error here as it's not critical to the main functionality
    }
  }

  // NEW: Method to get scan statistics
  Future<Map<String, int>> getScanStatistics() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final totalScans = prefs.getInt('total_scans_count') ?? 0;
      final highRiskScans = prefs.getInt('high_risk_scans_count') ?? 0;
      
      return {
        'totalScans': totalScans,
        'highRiskScans': highRiskScans,
      };
    } catch (e) {
      if (kDebugMode) {
        print("❌ Error getting scan statistics: $e");
      }
      return {
        'totalScans': 0,
        'highRiskScans': 0,
      };
    }
  }

  // NEW: Method to reset scan statistics (useful for testing or user preference)
  Future<void> resetScanStatistics() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('total_scans_count');
      await prefs.remove('high_risk_scans_count');
      
      if (kDebugMode) {
        print("🔄 Scan statistics reset");
      }
    } catch (e) {
      if (kDebugMode) {
        print("❌ Error resetting scan statistics: $e");
      }
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

      // Get harm scale for statistics update
      final harmScale = (result['harmScale'] ?? 0) as int;

      // Update scan statistics BEFORE saving the result
      await _updateScanStatistics(harmScale);

      // Get existing scans
      final existingScansJson = prefs.getString('recent_mold_scans');
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
      final savedImagePath = '${appDir.path}/mold_scan_$timestamp.jpg';

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
        'moldName': result['moldName'] ?? 'Unknown Mold',
        'harmScale': result['harmScale'] ?? 0,
        'isHarmful': result['isHarmful'] ?? false,
        'confidence': result['confidence'] ?? 'low',
        'location': result['location'] ?? 'Unknown',
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
      await prefs.setString('recent_mold_scans', json.encode(recentScans));
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
        // Show success message with statistics
        final stats = await getScanStatistics();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Mold analysis saved! Total scans: ${stats['totalScans']}, High-risk: ${stats['highRiskScans']}',
                style: GoogleFonts.poppins(),
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
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

  void _retakePhoto() {
    setState(() {
      _showResults = false;
      _analysisResults = null;
      _capturedImagePath = null;
    });
  }

  Color _getHarmScaleColor(int harmScale) {
    if (harmScale >= 80) return const Color(0xFFD32F2F); // Red - Dangerous
    if (harmScale >= 60) return const Color(0xFFFF5722); // Deep Orange - High Risk
    if (harmScale >= 40) return const Color(0xFFF57C00); // Orange - Medium Risk
    if (harmScale >= 20) return const Color(0xFFFBC02D); // Yellow - Low Risk
    return const Color(0xFF4CAF50); // Green - Minimal Risk
  }

  String _getHarmScaleText(int harmScale) {
    if (harmScale >= 80) return 'Dangerous';
    if (harmScale >= 60) return 'High Risk';
    if (harmScale >= 40) return 'Medium Risk';
    if (harmScale >= 20) return 'Low Risk';
    return 'Minimal Risk';
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
                      'MoldAI',
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
              color: Colors.black.withOpacity(0.7),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(
                      color: Color.fromRGBO(26, 188, 156, 1),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _debugMessage ?? 'Analyzing mold...',
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
                'Align the suspected mold with the frame',
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
    final moldName = _analysisResults!['moldName'] ?? 'Unknown Mold';
    final commonName = _analysisResults!['commonName'] ?? '';
    final harmScale = (_analysisResults!['harmScale'] ?? 0) as int;
    final isHarmful = _analysisResults!['isHarmful'] ?? false;
    final confidence = _analysisResults!['confidence'] ?? 'low';
    final location = _analysisResults!['location'] ?? 'Unknown';
    final summary = _analysisResults!['summary'] ?? 'Analysis completed';
    final healthRisks = List<String>.from(_analysisResults!['healthRisks'] ?? []);
    final removalInstructions = _analysisResults!['removalInstructions'] as Map<String, dynamic>?;

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
                  Image.asset(
                            'assets/logo_transparent.png',
                            height: 30,
                          ),
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
                        moldName,
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),
                      ),
                      if (commonName.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          commonName,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey[600],
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
                                "Harmful",
                                textAlign: TextAlign.left,
                                style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  color: Colors.black,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: 5),
                              Text(
                                "Confidence",
                                textAlign: TextAlign.left,
                                style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  color: Colors.black,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: 5),
                              Text(
                                "Location",
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
                                isHarmful ? "Yes" : "No",
                                textAlign: TextAlign.left,
                                style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  color: isHarmful ? Colors.red : Colors.green,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(height: 5),
                              Text(
                                confidence.toUpperCase(),
                                textAlign: TextAlign.left,
                                style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  color: Colors.black,
                                ),
                              ),
                              SizedBox(height: 5),
                              Container(
                                width: 75,
                                child: Expanded(
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Text(
                                      location,
                                      textAlign: TextAlign.left,
                                      style: GoogleFonts.poppins(
                                        fontSize: 15,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
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
                                  value: harmScale / 100,
                                  color: _getHarmScaleColor(harmScale),
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
                                    harmScale.toString(),
                                    style: GoogleFonts.poppins(
                                      fontSize: 30,
                                      fontWeight: FontWeight.w700,
                                      color: _getHarmScaleColor(harmScale),
                                      height: 1.0,
                                    ),
                                  ),
                                  Text(
                                    _getHarmScaleText(harmScale),
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: _getHarmScaleColor(harmScale),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      // Summary Section
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Analysis Summary:',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                summary,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.black,
                                  height: 1.5,
                                ),
                              ),
                              
                              // Removal Instructions
                              if (removalInstructions != null) ...[
                                const SizedBox(height: 20),
                                Text(
                                  'Removal Instructions:',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                
                                if (removalInstructions['professionalRecommended'] == true) ...[
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.red[50],
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.red[200]!),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.warning, color: Colors.red[700], size: 20),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Professional remediation recommended',
                                            style: GoogleFonts.poppins(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.red[700],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                ],
                                
                                if (removalInstructions['diyApproach'] != null) ...[
                                  Text(
                                    'DIY Approach:',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    removalInstructions['diyApproach'],
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: Colors.black,
                                      height: 1.5,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                ],
                                
                                if (removalInstructions['whenToCallProfessionals'] != null) ...[
                                  Text(
                                    'When to Call Professionals:',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    removalInstructions['whenToCallProfessionals'],
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: Colors.black,
                                      height: 1.5,
                                    ),
                                  ),
                                ],
                              ],
                            ],
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
    return Row(
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
              color: const Color.fromRGBO(26, 188, 156, 1),
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
                    : Color.fromRGBO(26, 188, 156, 1),
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
                          Color.fromRGBO(26, 188, 156, 1),
                        ),
                      ),
                    )
                  : const FaIcon(
                      FontAwesomeIcons.camera,
                      size: 25,
                      color: Color.fromRGBO(26, 188, 156, 1),
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
                  backgroundColor: const Color.fromRGBO(26, 188, 156, 1),
                ),
                child: Text(
                  'Retry',
                  style: GoogleFonts.poppins(color: Colors.white),
                ),
              ),
            ] else ...[
              const CircularProgressIndicator(
                color: Color.fromRGBO(26, 188, 156, 1),
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