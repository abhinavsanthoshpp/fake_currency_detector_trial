import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import '../utils/constants.dart';
import '../painters/edge_detection_painter.dart';
import 'results_screen.dart';

class ScannerScreen extends StatefulWidget {
  final CameraDescription camera;

  const ScannerScreen({super.key, required this.camera});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  bool _isDetected = false;
  bool _hasPermission = false;
  bool _isAnalyzing = false;
  String _detectedCurrency = 'USD \$100';
  double _confidenceLevel = 0.0;

  @override
  void initState() {
    super.initState();
    _requestCameraPermission();
  }

  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    setState(() {
      _hasPermission = status.isGranted;
    });

    if (_hasPermission) {
      _initializeCamera();
    }
  }

  void _initializeCamera() {
    _controller = CameraController(
      widget.camera,
      ResolutionPreset.high,
    );

    _initializeControllerFuture = _controller.initialize().then((_) {
      if (!mounted) return;
      setState(() {});

      // Start analyzing frames
      _controller.startImageStream((image) {
        if (!_isAnalyzing) {
          _isAnalyzing = true;
          _analyzeFrame(image);
        }
      });
    }).catchError((error) {
      // Handle camera initialization errors
      if (mounted) {
        setState(() {
          _hasPermission = false;
        });
      }
      debugPrint('Camera initialization error: $error');
    });
  }

  Future<void> _analyzeFrame(CameraImage image) async {
    // Simulate analysis process
    await Future.delayed(const Duration(milliseconds: 500));

    // Simulate detection after a few seconds
    if (_confidenceLevel < 0.9) {
      setState(() {
        _confidenceLevel += 0.1;
      });
    } else if (!_isDetected) {
      setState(() {
        _isDetected = true;
      });
    }

    _isAnalyzing = false;
  }

  @override
  void dispose() {
    // Stop the image stream before disposing the controller
    if (_controller.value.isStreamingImages) {
      _controller.stopImageStream();
    }
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasPermission) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.videocam_off, size: 64, color: Colors.white),
              const SizedBox(height: 16),
              const Text(
                AppStrings.cameraPermissionRequired,
                style: TextStyle(
                    fontSize: 20,
                    color: Colors.white,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                AppStrings.cameraPermissionMessage,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.white70),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _requestCameraPermission,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text(AppStrings.grantPermission),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera preview
          FutureBuilder<void>(
            future: _initializeControllerFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                return CameraPreview(_controller);
              } else {
                return const Center(
                    child: CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white)));
              }
            },
          ),

          // Edge detection overlay
          _buildEdgeDetectionOverlay(),

          // Scanning UI (only takes bottom portion)
          _buildScanningUI(),

          // App bar
          _buildAppBar(context),
        ],
      ),
    );
  }

  Widget _buildEdgeDetectionOverlay() {
    return IgnorePointer(
      child: Container(
        width: double.infinity,
        height: double.infinity,
        child: CustomPaint(
          painter: EdgeDetectionPainter(),
        ),
      ),
    );
  }

  Widget _buildScanningUI() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.35,
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_isDetected) _buildDetectionResult(),
            if (!_isDetected) _buildScanningInstructions(),
            const SizedBox(height: 24),
            if (_isDetected) _buildActionButtons(context),
            if (!_isDetected) _buildScanningProgress(),
          ],
        ),
      ),
    );
  }

  Widget _buildScanningInstructions() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.positionBanknote,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        SizedBox(height: 8),
        Text(
          AppStrings.positionInstructions,
          style: TextStyle(fontSize: 15, color: Colors.grey, height: 1.5),
        ),
      ],
    );
  }

  Widget _buildDetectionResult() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.successGreenLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.verified,
                color: AppColors.successGreen,
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _detectedCurrency,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${AppStrings.authentic} • ${(_confidenceLevel * 100).toStringAsFixed(0)}% Confidence',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        LinearProgressIndicator(
          value: _confidenceLevel,
          backgroundColor: Colors.grey[200],
          valueColor:
              const AlwaysStoppedAnimation<Color>(AppColors.successGreen),
          borderRadius: BorderRadius.circular(10),
        ),
      ],
    );
  }

  Widget _buildScanningProgress() {
    return Column(
      children: [
        LinearProgressIndicator(
          value: _confidenceLevel,
          backgroundColor: Colors.grey[200],
          valueColor:
              const AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
          borderRadius: BorderRadius.circular(10),
        ),
        const SizedBox(height: 16),
        const Text(
          AppStrings.analyzingFeatures,
          style: TextStyle(fontSize: 15, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () {
              setState(() {
                _isDetected = false;
                _confidenceLevel = 0.0;
              });
            },
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: const BorderSide(color: Colors.grey),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              AppStrings.scanAgain,
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ResultsScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              AppStrings.viewDetails,
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () {
          Navigator.pop(context);
        },
      ),
      title: const Text(
        AppStrings.banknoteScanner,
        style: TextStyle(color: Colors.white),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.flash_on, color: Colors.white),
          onPressed: () {},
        ),
      ],
    );
  }
}
