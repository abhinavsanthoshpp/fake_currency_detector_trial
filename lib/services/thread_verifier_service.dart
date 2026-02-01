import 'dart:io';
import 'dart:math';

import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vision/flutter_vision.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:ffmpeg_kit_flutter_new_https_gpl/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_https_gpl/return_code.dart';
import 'package:flutter/foundation.dart'; // Import for debugPrint
import 'package:currency_scanner/services/thread_verifier_isolate.dart';

class ThreadVerifierService {
  late FlutterVision _vision;

  ThreadVerifierService() {
    _vision = FlutterVision();
  }

  Future<void> loadYoloModel() async {
    await _vision.loadYoloModel(
        labels: 'assets/models/labels.txt',
        modelPath: 'assets/models/best_float32.tflite',
        modelVersion: "yolov8",
        numThreads: 1,
        useGpu: false);
  }

  Future<String> analyzeVideo(String videoPath) async {
    final token = RootIsolateToken.instance!;
    return await compute(
        analyzeVideoInIsolate, {'path': videoPath, 'token': token});
  }
}
