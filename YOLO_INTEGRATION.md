# YOLO Model Integration Guide

## Setup Instructions

### 1. **Add Your Model File**
Copy your `best_float32.tflite` model file to:
```
assets/models/best_float32.tflite
```

### 2. **Install Dependencies**
Run the following command:
```bash
flutter pub get
```

### 3. **Key Files Created**

#### Core Files:
- `lib/services/yolo_detector.dart` - Main YOLO inference engine
- `lib/providers/detection_provider.dart` - State management for detections
- `lib/screens/detection_screen.dart` - UI for real-time detection
- `lib/painters/detection_painter.dart` - Drawing bounding boxes
- `pubspec.yaml` - Added tflite_flutter and image packages

### 4. **How to Use the Detection Screen**

#### Option A: From Home Screen
Add a button in your `HomeScreen` to navigate to the detection screen:
```dart
ElevatedButton(
  onPressed: () {
    final cameras = <CameraDescription>[]; // Get from availableCameras()
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DetectionScreen(cameras: cameras),
      ),
    );
  },
  child: const Text('Start Detection'),
)
```

#### Option B: Modify Main Entry Point
Update your welcome page to go to detection screen instead.

### 5. **How It Works**

**Real-Time Detection Pipeline:**
1. Camera captures frame → CameraImage
2. CameraImage → RGB image conversion (handles YUV420/BGRA8888)
3. Image resizing to 640×640 (YOLO input size)
4. Normalization (0-1 range)
5. YOLO inference
6. Output parsing (confidence filtering)
7. Non-Maximum Suppression (NMS)
8. Draw bounding boxes on screen

**Features:**
- ✅ GPU acceleration (with fallback to CPU)
- ✅ Real-time processing
- ✅ Confidence threshold filtering (45%)
- ✅ NMS to remove duplicate detections
- ✅ Color-coded boxes by confidence
- ✅ Tap to toggle detection on/off

### 6. **Configuration**

Edit `lib/services/yolo_detector.dart` to adjust:

```dart
// Model input size (adjust if your model uses different size)
static const int modelInputSize = 640;

// Confidence threshold (0.0 - 1.0)
static const double confidenceThreshold = 0.45;

// NMS IoU threshold (0.0 - 1.0)
static const double iouThreshold = 0.50;

// Class names (update for your model's classes)
static const List<String> classNames = [
  // Your class names here...
];
```

### 7. **Performance Optimization**

For better performance:

**Android:**
- The app uses GPU delegation via `GpuDelegateV2`
- Fallback to NNAPI for quantized models

**Frame Processing:**
- Only processes frames when detection is running (`_isRunning`)
- Lightweight image conversion

### 8. **Troubleshooting**

**Issue: "Model not found"**
- Ensure `assets/models/best_float32.tflite` exists
- Check `pubspec.yaml` includes the asset path

**Issue: Low FPS**
- Reduce inference frequency (skip frames)
- Lower confidence threshold
- Use quantized model

**Issue: Wrong detections**
- Check class names in `classNames` list
- Adjust `confidenceThreshold` value
- Verify model input/output shapes

### 9. **Model Output Format Expected**

The code expects YOLO output format:
```
Shape: [1, 25200, 85]  (or similar)
Format: [x, y, w, h, confidence, class_scores...]
```

If your model outputs differently, modify `_parseOutput()` method in `yolo_detector.dart`.

### 10. **Adding to an Existing Screen**

To integrate detection into an existing screen:

```dart
import 'package:provider/provider.dart';
import '../providers/detection_provider.dart';
import '../painters/detection_painter.dart';

// In your widget:
Consumer<DetectionProvider>(
  builder: (context, detectionProvider, _) {
    return CustomPaint(
      painter: DetectionPainter(
        detections: detectionProvider.detections,
        imageSize: Size(640, 640),
        canvasSize: MediaQuery.of(context).size,
      ),
      child: SizedBox.expand(...),
    );
  },
)
```

### 11. **Next Steps**

1. Copy your `best_float32.tflite` to `assets/models/`
2. Run `flutter pub get`
3. Test the app with `flutter run`
4. Navigate to the detection screen
5. Tap "Start" button to begin detection

Happy detecting! 🎯
