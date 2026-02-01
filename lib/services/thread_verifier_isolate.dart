import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vision/flutter_vision.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:ffmpeg_kit_flutter_new_https_gpl/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_https_gpl/return_code.dart';

Future<String> analyzeVideoInIsolate(Map<String, dynamic> context) async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    BackgroundIsolateBinaryMessenger.ensureInitialized(
        context['token'] as RootIsolateToken);
  } catch (e) {
    // This is expected to throw an exception if already initialized.
  }

  final String videoPath = context['path'];
  final FlutterVision vision = FlutterVision();
  await vision.loadYoloModel(
      labels: 'assets/models/labels.txt',
      modelPath: 'assets/models/best_float32.tflite',
      modelVersion: "yolov8",
      numThreads: 1,
      useGpu: false);

  // 1. Setup temporary directory for frames
  final Directory tempDir = await getTemporaryDirectory();
  final String framesDirPath = '${tempDir.path}/video_frames';
  if (await Directory(framesDirPath).exists()) {
    await Directory(framesDirPath).delete(recursive: true);
  }
  await Directory(framesDirPath).create(recursive: true);

  // 2. Extract frames using FFmpeg
  final String ffmpegCommand =
      '-i "$videoPath" -vf "fps=5" "$framesDirPath/frame_%04d.jpg"';
  final session = await FFmpegKit.execute(ffmpegCommand);
  final returnCode = await session.getReturnCode();

  if (ReturnCode.isSuccess(returnCode)) {
    // Frame extraction successful
  } else {
    // Frame extraction failed
    await Directory(framesDirPath).delete(recursive: true); // Clean up
    return "Error: Video processing failed.";
  }

  // 3. Process each extracted frame
  final List<Map<String, dynamic>> records = [];
  List<double>? lastBbox; // To persist bounding box if YOLO flickers
  int frameId = 0;

  final List<FileSystemEntity> frameFiles = Directory(framesDirPath)
      .listSync()
      .where((entity) => entity.path.endsWith('.jpg'))
      .toList();
  frameFiles.sort((a, b) => a.path.compareTo(b.path)); // Sort frames by name

  for (final FileSystemEntity fileEntity in frameFiles) {
    final File frameFile = File(fileEntity.path);
    final img.Image? currentFrame =
        img.decodeImage(frameFile.readAsBytesSync());

    if (currentFrame == null) {
      continue;
    }

    bool detectedThisFrame = false;
    final List<Map<String, dynamic>> results = await vision.yoloOnFrame(
      bytesList: [
        currentFrame.getBytes(order: img.ChannelOrder.rgb).buffer.asUint8List()
      ], // Wrap in List
      imageHeight: currentFrame.height,
      imageWidth: currentFrame.width,
      iouThreshold: 0.4,
      confThreshold: 0.30, // Using TARGET_CLASS's threshold
      classThreshold: 0.5,
    );

    for (var r in results) {
      String className = r['tag']; // Assuming 'tag' is the class name
      if (r['box'][4] < 0.30) {
        // Confidence threshold
        continue;
      }

      if (className != "security_thread") {
        // TARGET_CLASS
        continue;
      }

      double x1 = (r['box'][0] as num).toDouble();
      double y1 = (r['box'][1] as num).toDouble();
      double x2 = (r['box'][2] as num).toDouble();
      double y2 = (r['box'][3] as num).toDouble();

      lastBbox = [x1, y1, x2, y2];
      detectedThisFrame = true;
      break;
    }

    if (!detectedThisFrame && lastBbox != null) {
      detectedThisFrame = true; // Assume detection, use last bbox
    }

    if (detectedThisFrame && lastBbox != null) {
      int x = lastBbox[0].toInt();
      int y = lastBbox[1].toInt();
      int width = (lastBbox[2] - lastBbox[0]).toInt();
      int height = (lastBbox[3] - lastBbox[1]).toInt();

      if (x < 0) x = 0;
      if (y < 0) y = 0;
      if (x + width > currentFrame.width) width = currentFrame.width - x;
      if (y + height > currentFrame.height) height = currentFrame.height - y;
      if (width < 10 || height < 10) continue;

      img.Image crop =
          img.copyCrop(currentFrame, x: x, y: y, width: width, height: height);

      double avgH = 0, avgS = 0, avgV = 0;
      int pixelCount = 0;
      
      for (int py = 0; py < crop.height; py++) {
        for (int px = 0; px < crop.width; px++) {
          final p = crop.getPixel(px, py);
          final r = p.rNormalized;
          final g = p.gNormalized;
          final b = p.bNormalized;

          double h = 0, s = 0, v = 0;

          double maxVal = max(r.toDouble(), max(g.toDouble(), b.toDouble()));
          double minVal = min(r.toDouble(), min(g.toDouble(), b.toDouble()));

          v = maxVal;

          if (maxVal == 0) {
            s = 0;
          } else {
            s = (maxVal - minVal) / maxVal;
          }

          if (s > 20/255 && v > 30/255) {
             if (s == 0) {
              h = 0;
            } else {
              double delta = maxVal - minVal;
              if (r == maxVal) {
                h = (g - b) / delta;
              } else if (g == maxVal) {
                h = 2 + (b - r) / delta;
              } else {
                h = 4 + (r - g) / delta;
              }
              h *= 60;
              if (h < 0) h += 360;
            }
            avgH += h;
            avgS += s * 100;
            avgV += v * 100;
            pixelCount++;
          }
        }
      }

      if (pixelCount > 15) {
        avgH /= pixelCount;
        avgS /= pixelCount;
        avgV /= pixelCount;
        records.add({"H": avgH, "S": avgS, "V": avgV});
      }
    }
    frameId++;
  }

  await Directory(framesDirPath).delete(recursive: true);

  return generateVerdict(records);
}

String generateVerdict(List<Map<String, dynamic>> records) {
  if (records.length < 10) {
    return "❌ Not enough data collected for thread verification.";
  }

  // Convert to lists for easier processing (simulating pandas DataFrame)
  List<double> hues = records.map((e) => (e["H"] as num).toDouble()).toList();
  List<double> saturations =
      records.map((e) => (e["S"] as num).toDouble()).toList();
  List<double> values = records.map((e) => (e["V"] as num).toDouble()).toList();

  // Calculate metrics
  double satVar = saturations.reduce(max) - saturations.reduce(min);
  double valVar = values.reduce(max) - values.reduce(min);
  double hueMin = hues.reduce(min);
  double hueMax = hues.reduce(max);
  double hueRange = hueMax - hueMin;
  double hueStd = calculateStdDev(hues);

  // ---- FINAL DECISION (FIXED LOGIC from Python script) ----
  if (satVar > 18 &&
      valVar > 15 &&
      hueRange > 12 && // must really change color
      hueMax > 85 && // must enter blue/cyan
      hueStd > 3 // reject flat green strips
  ) {
    return "✅ AUTHENTIC (Optical + chromatic shift detected)";
  } else if (satVar > 12 && valVar > 10 && hueRange > 6) {
    return "⚠️ LIKELY AUTHENTIC (Weak optical response)";
  } else {
    return "❌ STATIC / PRINTED INK (FAKE)";
  }
}

double calculateStdDev(List<double> data) {
  if (data.isEmpty) return 0.0;
  double mean = data.reduce((a, b) => a + b) / data.length;
  double variance =
      data.map((x) => pow(x - mean, 2)).reduce((a, b) => a + b) / data.length;
  return sqrt(variance);
}