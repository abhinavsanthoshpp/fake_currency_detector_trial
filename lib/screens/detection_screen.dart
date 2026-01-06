import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../painters/detection_painter.dart';
import '../providers/detection_provider.dart';

class DetectionScreen extends StatefulWidget {
  final List<CameraDescription> cameras;

  const DetectionScreen({
    Key? key,
    required this.cameras,
  }) : super(key: key);

  @override
  State<DetectionScreen> createState() => _DetectionScreenState();
}

class _DetectionScreenState extends State<DetectionScreen> {
  late CameraController _cameraController;
  late DetectionProvider _detectionProvider;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    _detectionProvider = context.read<DetectionProvider>();

    final camera = widget.cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.back,
      orElse: () => widget.cameras.first,
    );

    _cameraController = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
    );

    await _cameraController.initialize();

    print('📹 Initializing currency detector model...');
    await _detectionProvider.initialize();
    print('✓ Currency detector ready!');

    if (!mounted) return;

    // Start streaming camera frames to the detector
    print('📸 Starting camera frame stream...');
    _cameraController.startImageStream((CameraImage cameraImage) async {
      await _detectionProvider.processFrame(cameraImage);
    });

    // Auto-start detection
    _detectionProvider.startDetection();
    print('▶ Live detection started');

    setState(() {});
  }

  @override
  void dispose() {
    _cameraController.dispose();
    _detectionProvider.stopDetection();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_cameraController.value.isInitialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Live Currency Detection',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                blurRadius: 3.0,
                color: Colors.black87,
              ),
            ],
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Full screen camera preview
          CameraPreview(_cameraController),

          // Live detection overlay
          Consumer<DetectionProvider>(
            builder: (context, detectionProvider, _) {
              return CustomPaint(
                painter: DetectionPainter(
                  detections: detectionProvider.detections,
                  imageSize: Size(
                    _cameraController.value.previewSize?.height ?? 640,
                    _cameraController.value.previewSize?.width ?? 480,
                  ),
                  canvasSize: MediaQuery.of(context).size,
                ),
                child: SizedBox.expand(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        if (_detectionProvider.isRunning) {
                          _detectionProvider.stopDetection();
                        } else {
                          _detectionProvider.startDetection();
                        }
                      });
                    },
                  ),
                ),
              );
            },
          ),

          // Bottom stats panel - minimal, transparent
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Consumer<DetectionProvider>(
              builder: (context, detectionProvider, _) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black87,
                        Colors.black54,
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '🔍 Detections: ${detectionProvider.detections.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        detectionProvider.isRunning
                            ? '● LIVE Detection: ON'
                            : '⊙ Detection: OFF',
                        style: TextStyle(
                          color: detectionProvider.isRunning
                              ? Colors.greenAccent
                              : Colors.redAccent,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            if (_detectionProvider.isRunning) {
                              _detectionProvider.stopDetection();
                            } else {
                              _detectionProvider.startDetection();
                            }
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: detectionProvider.isRunning
                              ? Colors.red
                              : Colors.green,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                        ),
                        child: Text(
                          detectionProvider.isRunning
                              ? 'Stop Detection'
                              : 'Start Detection',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
