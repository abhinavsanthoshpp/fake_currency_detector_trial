import 'dart:async';
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
import 'package:currency_scanner/services/thread_verifier_service.dart'; // Import the new service

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

  // New state variables
  File? _capturedImage;
  bool _isProcessingImage = false;
  bool _isProcessingVideo = false;
  Uint8List? _processedImageBytes;

  late CurrencyVerifier _currencyVerifier;
  late ThreadVerifierService _threadVerifierService;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    vision = FlutterVision();
    _currencyVerifier = CurrencyVerifier();
    _threadVerifierService = ThreadVerifierService();
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
      await _currencyVerifier.loadModel();
      await _threadVerifierService.loadYoloModel();
      if (mounted) {
        setState(() {
          isCameraInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Error initializing camera: $e');
    }
  }

  Future<void> loadYoloModel() async {
    await vision.loadYoloModel(
        labels: 'assets/models/labels.txt',
        modelPath: 'assets/models/best_float32.tflite',
        modelVersion: "yolov8",
        numThreads: 1,
        useGpu: false);
  }

  Future<void> _captureImage() async {
    if (!controller.value.isInitialized) {
      return;
    }
    setState(() {
      _isProcessingImage = true;
    });
    try {
      final imageFile = await controller.takePicture();
      final File image = File(imageFile.path);

      // Process the image
      final results = await yoloOnImage(image);

      // Draw boxes on the image
      final Uint8List processedImage = await _drawBoxesOnImage(image, results);

      if (mounted) {
        setState(() {
          _capturedImage = image;
          _processedImageBytes = processedImage;
          _isProcessingImage = false;
        });
      }
    } catch (e) {
      debugPrint('Error capturing or processing image: $e');
      if (mounted) {
        setState(() {
          _isProcessingImage = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error during image analysis'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }

  Future<Uint8List> _drawBoxesOnImage(
      File imageFile, List<Map<String, dynamic>> results) async {
    final Uint8List imageBytes = await imageFile.readAsBytes();
    img.Image? originalImage = img.decodeImage(imageBytes);

    if (originalImage == null) {
      throw Exception("Could not decode image");
    }

    for (var result in results) {
      bool isGenuine = result['isGenuine'] ?? true;
      img.Color color = isGenuine ? img.ColorRgb(0, 255, 0) : img.ColorRgb(255, 0, 0);

      // Convert double coordinates to int
      final int x1 = (result["box"][0] as double).toInt();
      final int y1 = (result["box"][1] as double).toInt();
      final int x2 = (result["box"][2] as double).toInt();
      final int y2 = (result["box"][3] as double).toInt();

      // Draw the rectangle using drawPixel
      for (int x = x1; x < x2; x++) {
        for (int y = y1; y < y2; y++) {
          if (x == x1 || x == x2 - 1 || y == y1 || y == y2 - 1) {
            img.drawPixel(originalImage, x, y, color);
          }
        }
      }
    }
    // Encode the image back to Uint8List
    return Uint8List.fromList(img.encodeJpg(originalImage));
  }

  Future<List<Map<String, dynamic>>> yoloOnImage(File imageFile) async {
    final imageBytes = await imageFile.readAsBytes();
    final decodedImage = await decodeImageFromList(imageBytes);

    final result = await vision.yoloOnFrame(
        bytesList: [imageBytes],
        imageHeight: decodedImage.height,
        imageWidth: decodedImage.width,
        iouThreshold: 0.4,
        confThreshold: 0.4,
        classThreshold: 0.5);

    // Convert File to img.Image for CurrencyVerifier
    img.Image? convertedImage = img.decodeImage(imageBytes);
    if (convertedImage == null) {
      debugPrint("Failed to convert File for verification.");
      return [];
    }

    List<Map<String, dynamic>> verifiedYoloResults = [];

    if (result.isNotEmpty) {
      for (var yoloDetection in result) {
        String featureName = yoloDetection['tag'];
        List<double> bbox = List<double>.from(yoloDetection['box']);

        bool isGenuine =
            _currencyVerifier.verifyFeature(convertedImage, bbox, featureName);

        yoloDetection['isGenuine'] = isGenuine;
        verifiedYoloResults.add(yoloDetection);
      }
    }
    return verifiedYoloResults;
  }

  Future<void> _captureVideo() async {
    if (!controller.value.isInitialized || controller.value.isRecordingVideo) {
      return;
    }
    setState(() {
      _isProcessingVideo = true;
    });

    try {
      await controller.startVideoRecording();
      // Show a recording indicator on the UI
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Recording video for 15 seconds...'),
          backgroundColor: Colors.blue,
          duration: Duration(seconds: 15),
        ),
      );

      await Future.delayed(const Duration(seconds: 15));
      final XFile videoFile = await controller.stopVideoRecording();

      // Now analyze the video
      await _analyzeVideo(videoFile.path);
    } catch (e) {
      debugPrint('Error during video recording or analysis: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error during video analysis'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingVideo = false;
        });
      }
    }
  }

  Future<void> _analyzeVideo(String videoPath) async {
    debugPrint('Video recorded to: $videoPath');

    // The loading indicator is already handled by _isProcessingVideo state
    try {
      // Analyze the recorded video
      final String verdict =
          await _threadVerifierService.analyzeVideo(videoPath);

      // Show the verdict in a popup
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Thread Verification Result'),
          content: Text(verdict),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Reset the state to allow for a new scan
                setState(() {
                  _capturedImage = null;
                  _processedImageBytes = null;
                });
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      debugPrint('Error analyzing video: $e');
      // Optionally, show an error message to the user
    }
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
        children: [
          // Add CameraPreview so the user can see what they are capturing
          Positioned.fill(
            child: AspectRatio(
              aspectRatio: controller.value.aspectRatio,
              child: CameraPreview(controller),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (_processedImageBytes != null)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Image.memory(_processedImageBytes!),
                    ),
                  ),
                if (_capturedImage == null && _processedImageBytes == null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 32.0),
                    child: ElevatedButton(
                      onPressed: _captureImage,
                      style: ElevatedButton.styleFrom(
                        shape: const CircleBorder(),
                        padding: const EdgeInsets.all(24),
                      ),
                      child: const Icon(Icons.camera_alt),
                    ),
                  ),
                if (_capturedImage != null && !_isProcessingVideo)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 32.0),
                    child: ElevatedButton(
                      onPressed: _captureVideo,
                      style: ElevatedButton.styleFrom(
                        shape: const CircleBorder(),
                        padding: const EdgeInsets.all(24),
                      ),
                      child: const Icon(Icons.videocam),
                    ),
                  ),
              ],
            ),
          ),
          if (_isProcessingImage || _isProcessingVideo)
            Container(
              color: Colors.black.withOpacity(0.7),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 20),
                    Text(
                      'Verifying... Please wait.',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
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
        ],
      ),
    );
  }


}
