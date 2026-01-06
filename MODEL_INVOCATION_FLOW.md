# Model Invocation Flow

## How the Currency Detection Model is Invoked

This document explains how `best_float32.tflite` is loaded and executed in the app.

### 1. Model Initialization (Startup)

**When:** App starts, DetectionScreen loads
**Where:** `lib/screens/detection_screen.dart` → `_initializeCamera()`

```
_initializeCamera()
  ├─ Read: _detectionProvider = context.read<DetectionProvider>()
  ├─ Create: CameraController
  ├─ Initialize camera
  ├─ Log: "📹 Initializing currency detector model..."
  ├─ Call: await _detectionProvider.initialize()
  │   └─ Call: await detector.initialize()
  │       └─ Load: Interpreter.fromAsset('assets/models/best_float32.tflite')
  │       │   └─ TensorFlow Lite loads the trained model into memory
  │       │   └─ Model is ready for inference
  │       └─ Log: "✓ Currency detector model loaded successfully"
  ├─ Log: "✓ Currency detector ready!"
  ├─ Log: "📸 Starting camera frame stream..."
  ├─ Call: _cameraController.startImageStream()
  │   └─ Camera begins capturing frames
  │   └─ Each frame passed to callback
  ├─ Call: _detectionProvider.startDetection()
  │   └─ Set _isRunning = true
  └─ Log: "▶ Live detection started"
```

### 2. Real-Time Frame Processing (~30 FPS)

**When:** Every camera frame (approximately 30 times per second)
**Where:** `lib/providers/detection_provider.dart` → `processFrame()`

```
CameraFrame (from camera)
  │
  ├─ startImageStream() callback receives CameraImage
  │
  ├─ Call: _detectionProvider.processFrame(cameraImage)
  │   │
  │   ├─ Check: if (!_isRunning || !_isInitialized) return
  │   │
  │   ├─ Call: detector.detect(cameraImage)
  │   │   │
  │   │   ├─ STEP 1: Prepare Input Tensor
  │   │   │   Call: _prepareInput(cameraImage)
  │   │   │   │
  │   │   │   ├─ Create: List<List<List<List<double>>>> [1, 640, 640, 3]
  │   │   │   │
  │   │   │   ├─ Get: camera dimensions (width, height)
  │   │   │   ├─ Log: "🖼️  Camera frame: {width}x{height}, Format: {format}"
  │   │   │   │
  │   │   │   ├─ Check: if (format == yuv420)
  │   │   │   │   └─ Call: _fillInputFromYUV()
  │   │   │   │       ├─ Extract Y, U, V planes from camera frame
  │   │   │   │       ├─ Resize to 640x640
  │   │   │   │       ├─ Convert YUV to RGB using: _yuv420ToRgb()
  │   │   │   │       └─ Normalize: r/255.0, g/255.0, b/255.0
  │   │   │   │
  │   │   │   ├─ Check: else if (format == bgra8888)
  │   │   │   │   └─ Call: _fillInputFromBGRA()
  │   │   │   │       ├─ Extract B, G, R, A bytes
  │   │   │   │       ├─ Resize to 640x640
  │   │   │   │       └─ Normalize: r/255.0, g/255.0, b/255.0
  │   │   │   │
  │   │   │   └─ Log: "✓ Input tensor prepared: [1, 640, 640, 3]"
  │   │   │
  │   │   ├─ STEP 2: Run Model Inference
  │   │   │   Call: _interpreter.run(input, output)
  │   │   │   │
  │   │   │   ├─ Input:  [1, 640, 640, 3] normalized float tensor
  │   │   │   │
  │   │   │   └─ Output: [1, 25200, 85] raw predictions
  │   │   │       ├─ 25200 = 80x80 + 40x40 + 20x20 grid cells
  │   │   │       └─ 85 = 4 box coords + 1 confidence + 80 class scores
  │   │   │              (NOTE: Updated for 25 custom classes)
  │   │   │
  │   │   ├─ STEP 3: Parse Output Detections
  │   │   │   Call: _parseOutput(output[0])
  │   │   │   │
  │   │   │   ├─ Log: "📊 Parsing output - Type: {type}, Length: {length}"
  │   │   │   │
  │   │   │   ├─ Loop: for each of 25200 predictions
  │   │   │   │   │
  │   │   │   │   ├─ Extract: confidence = pred[4]
  │   │   │   │   │
  │   │   │   │   ├─ Check: if confidence >= 0.5 (confidenceThreshold)
  │   │   │   │   │   │
  │   │   │   │   │   ├─ Extract: x, y, w, h = pred[0:4]
  │   │   │   │   │   │
  │   │   │   │   │   ├─ Find: max class score in pred[5:30]
  │   │   │   │   │   │   └─ classId = argmax(pred[5:30])
  │   │   │   │   │   │
  │   │   │   │   │   ├─ Get: label = currencyClasses[classId]
  │   │   │   │   │   │   Possible classes:
  │   │   │   │   │   │   - 100_back, 100_front
  │   │   │   │   │   │   - 200_back, 200_front
  │   │   │   │   │   │   - 500_back, 500_front
  │   │   │   │   │   │   - 50_back, 50_front
  │   │   │   │   │   │   - Gandhi_potrait
  │   │   │   │   │   │   - ashoka_piller
  │   │   │   │   │   │   - bleed_lines
  │   │   │   │   │   │   - color_chg_num
  │   │   │   │   │   │   - ... (25 total)
  │   │   │   │   │   │
  │   │   │   │   │   └─ Create: CurrencyDetection {confidence, label, x, y, w, h}
  │   │   │   │
  │   │   │   ├─ STEP 4: Remove Duplicates with NMS
  │   │   │   │   Call: _applyNMS(detections)
  │   │   │   │   │
  │   │   │   │   ├─ Sort: by confidence (highest first)
  │   │   │   │   │
  │   │   │   │   ├─ Loop: for each detection
  │   │   │   │   │   ├─ Keep: detection with highest confidence
  │   │   │   │   │   ├─ Loop: compare with remaining detections
  │   │   │   │   │   │   ├─ Calculate: IoU (Intersection over Union)
  │   │   │   │   │   │   └─ Suppress: if IoU > 0.5 (iouThreshold)
  │   │   │   │   │   │
  │   │   │   │   └─ Return: filtered detections list
  │   │   │   │
  │   │   │   └─ Return: List<CurrencyDetection>
  │   │   │
  │   │   └─ Return: final detections
  │   │
  │   ├─ Update: _detections = detections
  │   │
  │   ├─ Check: if (detections.isNotEmpty)
  │   │   ├─ Log: "🎯 Detected {count} objects"
  │   │   └─ For each detection:
  │   │       └─ Log: "   - {label}: {confidence*100}%"
  │   │
  │   └─ Call: notifyListeners()
  │       └─ Trigger UI rebuild
  │
  └─ UI Update
      ├─ Consumer<DetectionProvider> rebuilds
      ├─ Get: detectionProvider.detections
      └─ Call: DetectionPainter.paint()
          └─ Draw bounding boxes on camera preview
```

### 3. Key Logging Points for Debugging

To verify the model is being invoked correctly, watch for these logs in the terminal:

**On App Start:**
```
📹 Initializing currency detector model...
✓ Currency detector model loaded successfully
✓ Currency detector ready!
📸 Starting camera frame stream...
▶ Live detection started
```

**On Each Frame:**
```
🖼️  Camera frame: 1080x2400, Format: ImageFormatGroup.yuv420
✓ Input tensor prepared: [1, 640, 640, 3]
📊 Parsing output - Type: List<dynamic>, Length: 25200
🎯 Detected 3 objects
   - 500_back: 92.5%
   - 100_front: 87.3%
   - security_thread: 78.1%
```

**If Model Fails:**
```
❌ Error during inference: {error message}
❌ Error processing frame: {error message}
```

### 4. Model Configuration

File: `lib/services/yolo_detector.dart`

```dart
static const int inputSize = 640;           // Input tensor size
static const double confidenceThreshold = 0.5;  // Min confidence
static const double iouThreshold = 0.5;     // NMS threshold

static const List<String> currencyClasses = [
  '100_back', '100_front',      // ₹100 notes
  '200_back', '200_front',      // ₹200 notes
  '500_back', '500_front',      // ₹500 notes
  '50_back', '50_front',        // ₹50 notes
  'Gandhi_potrait',             // Security features
  'ashoka_piller',
  'bleed_lines',
  'color_chg_num',
  // ... 15 more features
];
```

### 5. Troubleshooting

| Issue | Cause | Solution |
|-------|-------|----------|
| No logs at all | App not running | Ensure device is connected, `flutter run` succeeds |
| "Failed to load model" | Asset path wrong | Check `pubspec.yaml` has `assets/models/best_float32.tflite` |
| Model loaded but no detections | Confidence too high | Lower `confidenceThreshold` from 0.5 to 0.3 |
| Detections with wrong labels | Class name mismatch | Update `currencyClasses` to match trained model |
| Crash during inference | Input format mismatch | Check `_prepareInput()` handles camera format correctly |
| Black screen | Camera permission | Check Android manifest has camera permission |

### 6. Performance Notes

- **Initialization:** ~1-2 seconds (model loading)
- **Per-frame processing:** ~50-100ms (varies by device)
- **Camera FPS:** ~30 FPS on most devices
- **Detection latency:** Frames are processed asynchronously
- **Memory:** Model uses ~20-50MB depending on precision

### 7. Next Steps

1. **Run the app:** `flutter run -v`
2. **Watch the terminal** for initialization logs
3. **Point camera at currency notes** to trigger detections
4. **Check detected labels and confidence** match your trained model
5. **If needed, adjust thresholds** in `yolo_detector.dart`
