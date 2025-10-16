import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../utils/constants.dart';
import './results_screen.dart';
import 'home_screen.dart';
import '../database/database_service.dart';
import '../database/scan_result.dart';

class ScannerScreen extends StatefulWidget {
  final CameraDescription? camera;
  final VoidCallback? onBack;
  final ValueChanged<String>? onCaptured;

  const ScannerScreen({Key? key, this.camera, this.onBack, this.onCaptured})
      : super(key: key);

  @override
  _ScannerScreenState createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  late CameraController _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      final CameraDescription selected = widget.camera ?? cameras.first;
      _controller = CameraController(selected, ResolutionPreset.high);
      await _controller.initialize();
      if (mounted) setState(() => _isInitialized = true);
    } catch (e) {
      debugPrint('Error initializing camera: $e');
    }
  }

  @override
  void dispose() {
    try {
      if (_controller.value.isInitialized) _controller.dispose();
    } catch (e) {
      debugPrint('Error disposing camera controller: $e');
    }
    super.dispose();
  }

  Future<void> _processScanResult(String imagePath) async {
    // Simulate detection process
    await Future.delayed(const Duration(seconds: 2));

    // Simulate random detection results
    final List<String> currencies = [
      'INR ₹100',
      'INR ₹200',
      'INR ₹500',
      'INR ₹2000'
    ];
    final List<String> statuses = ['Authentic', 'Suspicious'];
    final List<double> confidences = [0.987, 0.654, 0.923, 0.889, 0.991];

    final random = DateTime.now().millisecond;
    final currency = currencies[random % currencies.length];
    final status = statuses[random % statuses.length];
    final confidence = confidences[random % confidences.length];

    // Create and save scan result
    final scanResult = ScanResult(
      currencyType: currency,
      resultStatus: status,
      confidenceLevel: confidence,
      dateTime: DateTime.now(),
      imagePath: imagePath,
    );

    await DatabaseService.addScanResult(scanResult);

    // Show success message
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Scan saved: $currency - $status'),
          backgroundColor: status == 'Authentic'
              ? AppColors.successGreen
              : AppColors.errorRed,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera preview
          CameraPreview(_controller),

          // Back button
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 8,
            child: SafeArea(
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () {
                  if (widget.onBack != null) {
                    widget.onBack!();
                    return;
                  }
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                    return;
                  }
                  if (widget.camera != null) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => HomeScreen(camera: widget.camera!),
                      ),
                    );
                  }
                },
              ),
            ),
          ),

          // Capture button
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 32.0),
              child: FloatingActionButton(
                heroTag: 'captureButton',
                backgroundColor: AppColors.primaryBlue,
                child:
                    const Icon(Icons.camera_alt, size: 28, color: Colors.white),
                onPressed: () async {
                  try {
                    final image = await _controller.takePicture();
                    if (!mounted) return;

                    // Process and save scan result
                    await _processScanResult(image.path);

                    // Navigate to results screen
                    if (widget.onCaptured != null) {
                      widget.onCaptured!(image.path);
                      return;
                    }

                    // Fallback: push results route
                    await Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ResultsScreen(
                          imagePath: image.path,
                          onBack: widget.onBack,
                        ),
                      ),
                    );
                  } catch (e) {
                    debugPrint('Error taking picture: $e');
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Error taking picture'),
                          backgroundColor: AppColors.errorRed,
                        ),
                      );
                    }
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
