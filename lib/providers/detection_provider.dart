import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vision/flutter_vision.dart';

class DetectionProvider extends ChangeNotifier {
  late FlutterVision _vision;
  List<Map<String, dynamic>> _detections = [];
  bool _isRunning = false;

  List<Map<String, dynamic>> get detections => _detections;
  bool get isRunning => _isRunning;

  DetectionProvider() {
    _vision = FlutterVision();
  }

  Future<void> initialize() async {
    await _vision.loadYoloModel(
      labels: 'assets/models/labels.txt',
      modelPath: 'assets/models/best_float32.tflite',
      modelVersion: "yolov8",
      quantization: false,
      numThreads: 1,
      useGpu: false,
    );
  }

  Future<void> processFrame(CameraImage cameraImage) async {
    if (!_isRunning) return;

    final result = await _vision.yoloOnFrame(
        bytesList: cameraImage.planes.map((plane) => plane.bytes).toList(),
        imageHeight: cameraImage.height,
        imageWidth: cameraImage.width,
        iouThreshold: 0.4,
        confThreshold: 0.4,
        classThreshold: 0.5);

    if (result.isNotEmpty) {
      _detections = result;
      notifyListeners();
    }
  }

  void startDetection() {
    _isRunning = true;
    notifyListeners();
  }

  void stopDetection() {
    _isRunning = false;
    _detections = [];
    notifyListeners();
  }

  @override
  void dispose() {
    _vision.closeYoloModel();
    super.dispose();
  }
}
