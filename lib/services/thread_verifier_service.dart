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

  Future<Map<String, dynamic>> analyzeVideo(String videoPath) async {
    print("🎬 Service: Starting frame extraction in main isolate...");
    
    // 1. Setup temporary directory for frames
    final Directory tempDir = await getTemporaryDirectory();
    final String framesDirPath = '${tempDir.path}/video_frames';
    if (await Directory(framesDirPath).exists()) {
      await Directory(framesDirPath).delete(recursive: true);
    }
    await Directory(framesDirPath).create(recursive: true);

    // 2. Extract frames using FFmpeg (Must be in main isolate)
    // Adjusted FPS to 1.5 for 10s video = 15 frames total
    final String ffmpegCommand =
        '-i "$videoPath" -vf "fps=1.5,scale=640:-1" -q:v 2 "$framesDirPath/frame_%04d.jpg"';
    
    final session = await FFmpegKit.execute(ffmpegCommand);
    final returnCode = await session.getReturnCode();

    if (!ReturnCode.isSuccess(returnCode)) {
      print("🎬 Service: FFmpeg extraction failed ❌");
      return {
        "score": 0.0,
        "label": "ERROR",
        "message": "Error: Video processing failed."
      };
    }
    print("🎬 Service: Extraction complete. Offloading ML to background isolate...");

    final token = RootIsolateToken.instance!;
    return await compute(
        analyzeVideoInIsolate, {
          'framesPath': framesDirPath, 
          'token': token
        }) as Map<String, dynamic>;
  }
}
