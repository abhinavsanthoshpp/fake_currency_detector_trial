import 'dart:io';
import 'dart:typed_data'; // Needed for image processing

import 'package:camera/camera.dart';
import 'package:currency_scanner/database/database_service.dart';
import 'package:currency_scanner/database/scan_result.dart';
import 'package:currency_scanner/screens/results_screen.dart';
import 'package:currency_scanner/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vision/flutter_vision.dart';
import 'package:currency_scanner/services/verifier_service.dart';
import 'package:image/image.dart' as img;

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
  late CurrencyVerifier _currencyVerifier;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    vision = FlutterVision();
    _currencyVerifier = CurrencyVerifier(); // Initialize here
    _initializeCamera(); // Call after initializing _currencyVerifier
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
      await _currencyVerifier.loadModel(); // Await model loading here
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
    _currencyVerifier.close(); // Call the new close method 
    super.dispose();
  }

  img.Image _convertCameraImage(CameraImage cameraImage) {
    if (cameraImage.format.group == ImageFormatGroup.yuv420) {
      return _convertYUV420ToImage(cameraImage);
    } else if (cameraImage.format.group == ImageFormatGroup.bgra8888) {
      return _convertBGRA8888ToImage(cameraImage);
    }
    throw Exception("Unsupported image format");
  }

  img.Image _convertYUV420ToImage(CameraImage cameraImage) {
    final int width = cameraImage.width;
    final int height = cameraImage.height;

    final img.Image image = img.Image(width: width, height: height); // Create Image buffer

    final Plane planeY = cameraImage.planes[0];
    final Plane planeU = cameraImage.planes[1];
    final Plane planeV = cameraImage.planes[2];

    final Uint8List yData = planeY.bytes;
    final Uint8List uData = planeU.bytes;
    final Uint8List vData = planeV.bytes;

    final int yRowStride = planeY.bytesPerRow;
    final int uRowStride = planeU.bytesPerRow;
    final int vRowStride = planeV.bytesPerRow;
    final int uPixelStride = planeU.bytesPerPixel!;
    final int vPixelStride = planeV.bytesPerPixel!;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final int uvX = (x / 2).floor();
        final int uvY = (y / 2).floor();

        final int yIndex = y * yRowStride + x;
        final int uIndex = uvY * uRowStride + uvX * uPixelStride;
        final int vIndex = uvY * vRowStride + uvX * vPixelStride;

        final int Y = yData[yIndex];
        final int U = uData[uIndex];
        final int V = vData[vIndex];

        // YUV to RGB conversion
        int R = (Y + V * 1.402).round();
        int G = (Y - U * 0.344136 - V * 0.714136).round();
        int B = (Y + U * 1.772).round();

        R = R.clamp(0, 255);
        G = G.clamp(0, 255);
        B = B.clamp(0, 255);

        image.setPixelRgb(x, y, R, G, B);
      }
    }
    return image;
  }

  img.Image _convertBGRA8888ToImage(CameraImage cameraImage) {
    final int width = cameraImage.width;
    final int height = cameraImage.height;
    final Uint8List bgraBytes = cameraImage.planes[0].bytes;

    // BGRA to RGBA conversion using image package
    final img.Image image = img.Image.fromBytes(
      width: width,
      height: height,
      bytes: bgraBytes.buffer,
      order: img.ChannelOrder.bgra,
    );
    return image;
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

    // Convert CameraImage to img.Image for CurrencyVerifier
    final img.Image? convertedImage = _convertCameraImage(cameraImage);
    if (convertedImage == null) {
      debugPrint("Failed to convert CameraImage for verification.");
      return;
    }

    List<Map<String, dynamic>> verifiedYoloResults = [];

    if (result.isNotEmpty) {
      for (var yoloDetection in result) {
        String featureName = yoloDetection['tag'];
        // Ensure bbox is a List<int>
        List<double> bbox = List<double>.from(yoloDetection['box']);

        bool isGenuine = _currencyVerifier.verifyFeature(convertedImage, bbox, featureName);
        
        // Add verification status to the result map
        yoloDetection['isGenuine'] = isGenuine;
        verifiedYoloResults.add(yoloDetection);
      }
      if (mounted) {
        setState(() {
          yoloResults = verifiedYoloResults;
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
      bool isGenuine = result['isGenuine'] ?? true; // Default to true if not set
      Color boxColor = isGenuine ? Colors.green : Colors.red;
      String verificationText = isGenuine ? "Genuine" : "Fake";

      return Positioned(
        left: result["box"][0] * factorX,
        top: result["box"][1] * factorY,
        width: (result["box"][2] - result["box"][0]) * factorX,
        height: (result["box"][3] - result["box"][1]) * factorY,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(Radius.circular(10.0)),
            border: Border.all(color: boxColor, width: 2.0), // Use dynamic color
          ),
          child: Text(
            "${result['tag']} ${(result['box'][4] * 100).toStringAsFixed(0)}% $verificationText", // Add verification text
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

                    await Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ResultsScreen(
                          imagePath: image.path,
                          yoloResults: yoloResults, // Pass the yoloResults
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
