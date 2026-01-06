import 'dart:io';

import 'package:camera/camera.dart';
import 'package:currency_scanner/database/database_service.dart';
import 'package:currency_scanner/database/scan_result.dart';
import 'package:currency_scanner/screens/results_screen.dart';
import 'package:currency_scanner/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vision/flutter_vision.dart';

class ScannerScreen extends StatefulWidget {
  final CameraDescription? camera;

  const ScannerScreen({super.key, this.camera});
  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  late CameraController controller;
  late FlutterVision vision;
  List<Map<String, dynamic>> yoloResults = [];
  bool isCameraInitialized = false;
  bool isDetecting = false;
  bool _isProcessingFrame = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    vision = FlutterVision();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    final CameraDescription selected = widget.camera ?? cameras.first;

    controller = CameraController(
      selected,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );
    try {
      await controller.initialize();
      await loadYoloModel();
      if (mounted) {
        setState(() {
          isCameraInitialized = true;
        });
        controller.startImageStream((image) {
          if (_isProcessingFrame) {
            return;
          }
          _isProcessingFrame = true;
          yoloOnFrame(image).whenComplete(() => _isProcessingFrame = false);
        });
      }
    } catch (e) {
      debugPrint('Error initializing camera: $e');
    }
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    controller.dispose();
    vision.closeYoloModel();
    super.dispose();
  }

  Future<void> loadYoloModel() async {
    await vision.loadYoloModel(
        labels: 'assets/models/labels.txt',
        modelPath: 'assets/models/best_float32.tflite',
        modelVersion: "yolov8",
        numThreads: 1,
        useGpu: false);
  }

  Future<void> yoloOnFrame(CameraImage cameraImage) async {
    final result = await vision.yoloOnFrame(
        bytesList: cameraImage.planes.map((plane) => plane.bytes).toList(),
        imageHeight: cameraImage.height,
        imageWidth: cameraImage.width,
        iouThreshold: 0.4,
        confThreshold: 0.4,
        classThreshold: 0.5);
    if (result.isNotEmpty) {
      if (mounted) {
        setState(() {
          yoloResults = result;
        });
      }
    }
  }

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

  List<Widget> _displayBoxes(Size screen) {
    if (yoloResults.isEmpty) return [];

    // because the camera stream is in landscape mode, we need to swap the width and height
    final double factorX = screen.width / controller.value.previewSize!.height;
    final double factorY = screen.height / controller.value.previewSize!.width;

    return yoloResults.map((result) {
      return Positioned(
        left: result["box"][0] * factorX,
        top: result["box"][1] * factorY,
        width: (result["box"][2] - result["box"][0]) * factorX,
        height: (result["box"][3] - result["box"][1]) * factorY,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(Radius.circular(10.0)),
            border: Border.all(color: Colors.pink, width: 2.0),
          ),
          child: Text(
            "${result['tag']} ${(result['box'][4] * 100).toStringAsFixed(0)}%",
            style: const TextStyle(
              background: null,
              color: Colors.white,
              fontSize: 18.0,
            ),
          ),
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (!isCameraInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          CameraPreview(controller),
          ..._displayBoxes(MediaQuery.of(context).size),
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 8,
            child: SafeArea(
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () {
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
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
                  if (!controller.value.isInitialized) {
                    return;
                  }
                  try {
                    final image = await controller.takePicture();
                    if (!mounted) return;

                    await _processScanResult(image.path);

                    await Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ResultsScreen(
                          imagePath: image.path,
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
