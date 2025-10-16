import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../utils/constants.dart';
import './results_screen.dart';
import 'home_screen.dart'; // keep for fallback if needed

class ScannerScreen extends StatefulWidget {
  final CameraDescription? camera;
  final VoidCallback? onBack; // called when back pressed
  final ValueChanged<String>? onCaptured; // called with image path when capture

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
          // Camera preview only
          CameraPreview(_controller),

          // Top-left back button on black background
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 8,
            child: SafeArea(
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () {
                  if (widget.onBack != null) {
                    widget.onBack!(); // return to Home tab
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

          // Only one capture button (bottom center)
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 32.0),
              child: FloatingActionButton(
                heroTag: 'captureButton',
                backgroundColor: AppColors.primaryBlue,
                child: const Icon(Icons.camera_alt, size: 28),
                onPressed: () async {
                  try {
                    final image = await _controller.takePicture();
                    if (!mounted) return;

                    // If parent provided onCaptured, use it so ResultsScreen shows inside HomeScreen
                    if (widget.onCaptured != null) {
                      widget.onCaptured!(image.path);
                      return;
                    }

                    // Fallback: push results route (legacy behavior)
                    await Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ResultsScreen(imagePath: image.path),
                      ),
                    );
                  } catch (e) {
                    debugPrint('Error taking picture: $e');
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
