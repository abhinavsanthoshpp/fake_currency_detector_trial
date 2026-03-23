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

Future<Map<String, dynamic>> analyzeVideoInIsolate(Map<String, dynamic> context) async {
  print("🧵 Isolate: Starting ML analysis...");
  final RootIsolateToken token = context['token'] as RootIsolateToken;
  BackgroundIsolateBinaryMessenger.ensureInitialized(token);
  
  try {
    WidgetsFlutterBinding.ensureInitialized();
  } catch (e) {}

  final String framesDirPath = context['framesPath'];
  print("🧵 Isolate: Loading YOLO model...");
  final FlutterVision vision = FlutterVision();
  await vision.loadYoloModel(
      labels: 'assets/models/labels.txt',
      modelPath: 'assets/models/best_float32.tflite',
      modelVersion: "yolov8",
      numThreads: 1,
      useGpu: false);

  // 3. Process each extracted frame
  final List<Map<String, dynamic>> records = [];
  List<double>? lastBbox; 
  
  final List<FileSystemEntity> frameFiles = Directory(framesDirPath)
      .listSync()
      .where((entity) => entity.path.endsWith('.jpg'))
      .toList();
  frameFiles.sort((a, b) => a.path.compareTo(b.path)); 

  print("🧵 Isolate: Starting YOLO analysis on ${frameFiles.length} frames...");

  for (int frameIdx = 0; frameIdx < frameFiles.length; frameIdx++) {
    final DateTime frameStart = DateTime.now();
    final File frameFile = File(frameFiles[frameIdx].path);
    final Uint8List frameBytes = frameFile.readAsBytesSync();
    
    bool detectedThisFrame = false;
    
    // OPTIMIZATION 1: Only run YOLO if we don't have a bbox OR every 4th frame to "re-anchor"
    bool shouldRunYolo = lastBbox == null || (frameIdx % 4 == 0);
    
    if (shouldRunYolo) {
      final List<Map<String, dynamic>> results = await vision.yoloOnImage(
        bytesList: frameBytes,
        imageHeight: 0, 
        imageWidth: 0,
        iouThreshold: 0.4,
        confThreshold: 0.20, 
        classThreshold: 0.5,
      );

      for (var r in results) {
        if (r['tag'] != "security_thread") continue;
        lastBbox = [
          (r['box'][0] as num).toDouble(),
          (r['box'][1] as num).toDouble(),
          (r['box'][2] as num).toDouble(),
          (r['box'][3] as num).toDouble(),
        ];
        detectedThisFrame = true;
        break;
      }
    } else if (lastBbox != null) {
      detectedThisFrame = true; 
    }

    if (detectedThisFrame && lastBbox != null) {
      // OPTIMIZATION 2: Decode only if we have a crop ROI
      final img.Image? currentFrame = img.decodeImage(frameBytes);
      if (currentFrame == null) continue;

      int x = lastBbox[0].toInt();
      int y = lastBbox[1].toInt();
      int width = (lastBbox[2] - lastBbox[0]).toInt();
      int height = (lastBbox[3] - lastBbox[1]).toInt();

      if (x < 0) x = 0;
      if (y < 0) y = 0;
      if (x + width > currentFrame.width) width = currentFrame.width - x;
      if (y + height > currentFrame.height) height = currentFrame.height - y;
      
      if (width < 5 || height < 5) continue;

      img.Image crop = img.copyCrop(currentFrame, x: x, y: y, width: width, height: height);

      double avgH = 0, avgS = 0, avgV = 0;
      int pixelCount = 0;

      // OPTIMIZATION 3: Sample pixels (every 4th pixel) - 16x faster
      for (int py = 0; py < crop.height; py += 4) {
        for (int px = 0; px < crop.width; px += 4) {
          final p = crop.getPixel(px, py);
          final r = p.rNormalized.toDouble();
          final g = p.gNormalized.toDouble();
          final b = p.bNormalized.toDouble();

          double h = 0, s = 0, v = 0;
          double maxVal = max(r, max(g, b));
          double minVal = min(r, min(g, b));
          v = maxVal;
          s = (maxVal == 0) ? 0 : (maxVal - minVal) / maxVal;

          if (s > 0.08 && v > 0.12) {
            double delta = maxVal - minVal;
            if (delta != 0) {
              if (r == maxVal) h = (g - b) / delta;
              else if (g == maxVal) h = 2 + (b - r) / delta;
              else h = 4 + (r - g) / delta;
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

      if (pixelCount > 5) {
        records.add({
          "H": avgH / pixelCount, 
          "S": avgS / pixelCount, 
          "V": avgV / pixelCount
        });
      }
    }
    final int elapsed = DateTime.now().difference(frameStart).inMilliseconds;
    print("🧵 Isolate: Frame ${frameIdx + 1}/${frameFiles.length} took ${elapsed}ms");
  }

  await Directory(framesDirPath).delete(recursive: true);

  return generateVerdict(records);
}

Map<String, dynamic> generateVerdict(List<Map<String, dynamic>> records) {
  if (records.length < 5) { // Reduced requirement slightly for better UX
    return {
      "score": 0.0,
      "label": "NOT_DETECTED",
      "message": "❌ Security thread not detected in enough frames."
    };
  }

  // Convert to lists for easier processing
  List<double> hues = records.map((e) => (e["H"] as num).toDouble()).toList();
  List<double> saturations = records.map((e) => (e["S"] as num).toDouble()).toList();
  List<double> values = records.map((e) => (e["V"] as num).toDouble()).toList();

  // Calculate metrics
  double satVar = saturations.reduce(max) - saturations.reduce(min);
  double valVar = values.reduce(max) - values.reduce(min);
  double hueMin = hues.reduce(min);
  double hueMax = hues.reduce(max);
  double hueRange = hueMax - hueMin;
  double hueStd = calculateStdDev(hues);

  // LOGGING (Visible in debug console)
  print("THREAD ANALYSIS: SatVar: $satVar, ValVar: $valVar, HueRange: $hueRange, HueMax: $hueMax, HueStd: $hueStd");

  // ---- FINAL DECISION LOGIC (Improved for "Big Score" weighting) ----
  Map<String, dynamic> verdict;
  if (satVar > 15 && valVar > 12 && hueRange > 10 && hueMax > 80 && hueStd > 2.5) {
    verdict = {
      "score": 1.0,
      "label": "AUTHENTIC",
      "message": "AUTHENTIC (Optical + chromatic shift detected)"
    };
  } else if (satVar > 10 && valVar > 8 && hueRange > 5) {
    verdict = {
      "score": 0.6,
      "label": "LIKELY_AUTHENTIC",
      "message": "LIKELY AUTHENTIC (Weak optical response)"
    };
  } else {
    verdict = {
      "score": 0.2,
      "label": "FAKE",
      "message": "STATIC / PRINTED INK (FAKE)"
    };
  }

  // Add raw metrics for UI display
  verdict["metrics"] = {
    "saturation_shift": satVar.toStringAsFixed(1),
    "value_shift": valVar.toStringAsFixed(1),
    "hue_range": hueRange.toStringAsFixed(1),
  };
  
  return verdict;
}

double calculateStdDev(List<double> data) {
  if (data.isEmpty) return 0.0;
  double mean = data.reduce((a, b) => a + b) / data.length;
  double variance =
      data.map((x) => pow(x - mean, 2)).reduce((a, b) => a + b) / data.length;
  return sqrt(variance);
}
