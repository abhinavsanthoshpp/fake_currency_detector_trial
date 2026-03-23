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
  bool isRecording = false;
  XFile? recordedVideoFile;

  // Store results between steps
  List<Map<String, dynamic>> _stage1FrontResults = [];
  List<Map<String, dynamic>> _stage1BackResults = [];
  String? _stage1FrontImagePath;
  String? _stage1BackImagePath;
  
  bool get _hasFront => _stage1FrontImagePath != null;
  bool get _hasBack => _stage1BackImagePath != null;

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
                if (verificationStep == 1) ...[
                  if (!_hasFront)
                    ElevatedButton(
                      onPressed: isProcessing ? null : () => _captureAndAnalyzeSide(true),
                      child: const Text('Capture Front Side'),
                    ),
                  if (_hasFront && !_hasBack)
                    ElevatedButton(
                      onPressed: isProcessing ? null : () => _captureAndAnalyzeSide(false),
                      child: const Text('Capture Back Side'),
                    ),
                  if (_hasFront && _hasBack)
                    ElevatedButton(
                      onPressed: isProcessing ? null : _showCombinedResults,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      child: const Text('See Step 1 Results'),
                    ),
                ],
                if (verificationStep == 2 && !isRecording)
                  ElevatedButton(
                    onPressed: isProcessing ? null : _startRecording,
                    child: const Text('Step 2: Record Thread Video'),
                  ),
                if (isRecording)
                  ElevatedButton(
                    onPressed: _stopRecording,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    child: const Text('Stop Recording'),
                  ),
                if (verificationStep == 3 && recordedVideoFile != null)
                  ElevatedButton(
                    onPressed: isProcessing ? null : _processRecordedVideo,
                    child: isProcessing 
                      ? const SizedBox(
                          height: 20, 
                          width: 20, 
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
                        )
                      : const Text('Step 3: Analyze Thread Video'),
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

  Future<void> _captureAndAnalyzeSide(bool isFront) async {
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

    setState(() {
      if (isFront) {
        _stage1FrontResults = verifiedResults;
        _stage1FrontImagePath = image.path;
      } else {
        _stage1BackResults = verifiedResults;
        _stage1BackImagePath = image.path;
      }
      isProcessing = false;
    });
  }

  Future<void> _showCombinedResults() async {
    // Combine all YOLO features from both sides for scoring
    final List<Map<String, dynamic>> combinedResults = [
      ..._stage1FrontResults,
      ..._stage1BackResults,
    ];

    // Set orientation to portrait before showing results
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    if (!mounted) return;
    
    final shouldProceed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => ResultsScreen(
          imagePath: _stage1FrontImagePath,
          backImagePath: _stage1BackImagePath,
          yoloResults: combinedResults,
          frontResults: _stage1FrontResults,
          backResults: _stage1BackResults,
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
      setState(() {
        verificationStep = 2; // Move to video step
        isProcessing = false;
      });
    } else {
      setState(() {
        isProcessing = false;
      });
    }
  }

  Future<void> _startRecording() async {
    setState(() {
      isRecording = true;
    });
    await cameraController.startVideoRecording();
    // Auto-stop after 10 seconds as requested
    Future.delayed(const Duration(seconds: 10), () {
      if (isRecording) {
        _stopRecording();
      }
    });
  }

  Future<void> _stopRecording() async {
    final videoFile = await cameraController.stopVideoRecording();
    setState(() {
      isRecording = false;
      recordedVideoFile = videoFile;
      verificationStep = 3; // Ready to process
    });
  }

  Future<void> _processRecordedVideo() async {
    if (recordedVideoFile == null) return;

    setState(() {
      isProcessing = true;
    });

    final threadResult = await threadVerifierService.analyzeVideo(recordedVideoFile!.path);

    setState(() {
      videoVerdict = threadResult['message'];
      isProcessing = false;
      verificationStep = 4;
    });

    // Navigate to FINAL Results Screen
    if (mounted) {
      // Combine all Stage 1 features again
      final List<Map<String, dynamic>> combinedResults = [
        ..._stage1FrontResults,
        ..._stage1BackResults,
      ];

      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ResultsScreen(
            imagePath: _stage1FrontImagePath,
            backImagePath: _stage1BackImagePath,
            yoloResults: combinedResults,
            frontResults: _stage1FrontResults,
            backResults: _stage1BackResults,
            threadVerificationResult: threadResult,
            isIntermediateResult: false,
          ),
        ),
      );

      // Return to landscape if they come back
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeRight,
        DeviceOrientation.landscapeLeft,
      ]);
    }
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