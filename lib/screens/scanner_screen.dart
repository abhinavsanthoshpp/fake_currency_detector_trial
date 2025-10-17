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

  int _popupIndex = 0;

  final List<Map<String, String>> _popups = [
    {
      "title": "Step 1: Capture Front Side",
      "content":
          "1.Align the currency note well within the frame.\n2.Ensure the entire note is visible.\n3.Keep camera steady.\n4.keep note as flat as possible.\nTry to capture input in landscape mode for better results."
    },
    {
      "title": "Step 2: Capture Back Side",
      "content":
          "1.Align the currency note well within the frame.\n2.Ensure the entire note is visible.\n3.Keep camera steady.\n4.keep note as flat as possible."
    },
    {
      "title": "Step 3: Capture security thread",
      "content":
          "1.Keep the camer near to the security thread in low angle.\n2.Make sure whole security thread is visible.\n4.Move the camera slowly to capture the thread color change"
    },
  ];

  @override
  void initState() {
    super.initState();
    _initializeCamera();

    // Show popups sequentially once first frame is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showPopup();
    });
  }

  // Initialize camera safely
  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      final CameraDescription selected = widget.camera ?? cameras.first;
      _controller = CameraController(selected, ResolutionPreset.high);
      await _controller.initialize();
      if (mounted) setState(() => _isInitialized = true);
    } catch (e) {
      debugPrint('Error initializing camera: $e');
      // You might want to show an error UI or message here
    }
  }

  // Recursive popup display with 5 seconds delay after Next pressed
  void _showPopup() {
    if (_popupIndex >= _popups.length) {
      Future.delayed(const Duration(seconds: 3), _goToResult);
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text(_popups[_popupIndex]["title"]!),
        content: Text(_popups[_popupIndex]["content"]!),
        actions: [
          TextButton(
            child: const Text("Next"),
            onPressed: () {
              Navigator.of(context).pop();
              _popupIndex++;

              // Delay 5 seconds before showing next popup or going to result
              Future.delayed(const Duration(seconds: 3), () {
                if (mounted) _showPopup();
              });
            },
          ),
        ],
      ),
    );
  }

  // Navigate to ResultsScreen (can be improved to pass image)
  void _goToResult() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => ResultsScreen(
          imagePath:
              null, // You may replace with actual image path if available
          onBack: widget.onBack,
        ),
      ),
    );
  }

  // Dispose camera controller properly
  @override
  void dispose() {
    try {
      if (_controller.value.isInitialized) _controller.dispose();
    } catch (e) {
      debugPrint('Error disposing camera controller: $e');
    }
    super.dispose();
  }

  // Simulate detection and save scan result with random values
  Future<void> _processScanResult(String imagePath) async {
    await Future.delayed(const Duration(seconds: 2));

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

    final scanResult = ScanResult(
      currencyType: currency,
      resultStatus: status,
      confidenceLevel: confidence,
      dateTime: DateTime.now(),
      imagePath: imagePath,
    );

    await DatabaseService.addScanResult(scanResult);

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

  // Build camera preview and UI
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
          CameraPreview(_controller),
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
          Positioned(
            bottom: 24,
            left: 0,
            right: 0,
            child: Center(
              child: FloatingActionButton(
                heroTag: 'captureButton',
                backgroundColor: AppColors.primaryBlue,
                child:
                    const Icon(Icons.camera_alt, size: 28, color: Colors.white),
                onPressed: () async {
                  try {
                    final image = await _controller.takePicture();
                    if (!mounted) return;

                    await _processScanResult(image.path);

                    if (widget.onCaptured != null) {
                      widget.onCaptured!(image.path);
                      return;
                    }

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
