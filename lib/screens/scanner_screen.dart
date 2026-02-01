import 'dart:io';

import 'package:camera/camera.dart';
import 'package:currency_scanner/screens/results_screen.dart';
import 'package:currency_scanner/services/thread_verifier_service.dart';
import 'package:currency_scanner/services/verifier_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vision/flutter_vision.dart';
import 'package:image/image.dart' as img;

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  late List<CameraDescription> cameras;
  late CameraController cameraController;
  late FlutterVision vision;
  late CurrencyVerifier currencyVerifier;
  late ThreadVerifierService threadVerifierService;

  bool isCameraInitialized = false;
  int verificationStep = 1;
  File? capturedImage;
  List<Map<String, dynamic>> yoloResults = [];
  bool isProcessing = false;
  String? videoVerdict;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
    ]);
    initialize();
  }

  Future<void> initialize() async {
    cameras = await availableCameras();
    cameraController = CameraController(cameras.first, ResolutionPreset.high, enableAudio: false);
    await cameraController.initialize();
    vision = FlutterVision();
    currencyVerifier = CurrencyVerifier();
    threadVerifierService = ThreadVerifierService();
    await vision.loadYoloModel(
        labels: 'assets/models/labels.txt',
        modelPath: 'assets/models/best_float32.tflite',
        modelVersion: "yolov8",
        numThreads: 1,
        useGpu: false);
    await currencyVerifier.loadModel();
    await threadVerifierService.loadYoloModel();
    setState(() {
      isCameraInitialized = true;
    });
  }

  @override
  void dispose() {
    vision.closeYoloModel();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    currencyVerifier.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!isCameraInitialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          CameraPreview(cameraController),
          if (isProcessing)
            const Center(
              child: CircularProgressIndicator(),
            ),
          Positioned(
            right: 20,
            bottom: 20,
            child: Column(
              children: [
                if (verificationStep == 1)
                  ElevatedButton(
                    onPressed: isProcessing ? null : _captureAndAnalyzeImage,
                    child: const Text('Step 1: Verify Image'),
                  ),
                if (verificationStep == 2)
                  ElevatedButton(
                    onPressed: isProcessing ? null : _startVideoVerification,
                    child: const Text('Step 2: Verify Thread'),
                  ),
              ],
            ),
          ),
          if (videoVerdict != null)
            Container(
              color: Colors.black54,
              padding: const EdgeInsets.all(16.0),
              child: Center(
                  child: Text(videoVerdict!,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 24))),
            ),
          Positioned(
            top: 20,
            left: 20,
            child: SafeArea(
              child: FloatingActionButton(
                onPressed: () => Navigator.of(context).pop(),
                backgroundColor: Colors.black.withOpacity(0.5),
                child: const Icon(Icons.arrow_back),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _captureAndAnalyzeImage() async {
    setState(() {
      isProcessing = true;
    });

    final imageFile = await cameraController.takePicture();
    final image = File(imageFile.path);

    final imageBytes = await image.readAsBytes();
    final decodedImage = await decodeImageFromList(imageBytes);

    final results = await vision.yoloOnImage(
        bytesList: imageBytes,
        imageHeight: decodedImage.height,
        imageWidth: decodedImage.width,
        iouThreshold: 0.4,
        confThreshold: 0.4,
        classThreshold: 0.5);

    img.Image? convertedImage = img.decodeImage(imageBytes);
    if (convertedImage == null) {
      setState(() {
        isProcessing = false;
      });
      return;
    }

    List<Map<String, dynamic>> verifiedResults = [];
    for (var result in results) {
      bool isGenuine = currencyVerifier.verifyFeature(
          convertedImage, List<double>.from(result['box']), result['tag']);
      result['isGenuine'] = isGenuine;
      verifiedResults.add(result);
    }

    // Set orientation to portrait before showing results
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    final shouldProceed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => ResultsScreen(
          imagePath: image.path,
          yoloResults: verifiedResults,
          isIntermediateResult: true,
        ),
      ),
    );

    // Set orientation back to landscape after returning from results
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
    ]);

    if (shouldProceed == true) {
      _startVideoVerification();
    } else {
      setState(() {
        isProcessing = false;
      });
    }
  }

  Future<void> _startVideoVerification() async {
    setState(() {
      verificationStep = 3;
    });
    await _captureAndAnalyzeVideo();
  }

  Future<void> _captureAndAnalyzeVideo() async {
    setState(() {
      isProcessing = true;
    });

    await cameraController.startVideoRecording();
    await Future.delayed(const Duration(seconds: 15));
    final videoFile = await cameraController.stopVideoRecording();

    final verdict = await threadVerifierService.analyzeVideo(videoFile.path);

    setState(() {
      videoVerdict = verdict;
      isProcessing = false;
      verificationStep = 4;
    });
  }

  List<Widget> displayBoxes(Size screen) {
    if (yoloResults.isEmpty || verificationStep != 2) return [];
    
    final double imageAspectRatio = cameraController.value.aspectRatio;
    final double screenAspectRatio = screen.width / screen.height;
    double scale = 1.0;
    double offsetX = 0;
    double offsetY = 0;

    if (imageAspectRatio > screenAspectRatio) {
      scale = screen.width / (cameraController.value.previewSize?.height ?? screen.width);
      offsetY = (screen.height - (cameraController.value.previewSize?.width ?? screen.height) * scale) / 2;
    } else {
      scale = screen.height / (cameraController.value.previewSize?.width ?? screen.height);
      offsetX = (screen.width - (cameraController.value.previewSize?.height ?? screen.width) * scale) / 2;
    }

    return yoloResults.map((result) {
      return Positioned(
        left: result["box"][0] * scale + offsetX,
        top: result["box"][1] * scale + offsetY,
        width: (result["box"][2] - result["box"][0]) * scale,
        height: (result["box"][3] - result["box"][1]) * scale,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
                color: result['isGenuine'] ? Colors.green : Colors.red,
                width: 2.0),
          ),
          child: Text(
            "${result['tag']} ${(result['box'][4] * 100).toStringAsFixed(0)}%",
            style: TextStyle(
              background: Paint()..color = result['isGenuine'] ? Colors.green : Colors.red,
              color: Colors.white,
            ),
          ),
        ),
      );
    }).toList();
  }
}