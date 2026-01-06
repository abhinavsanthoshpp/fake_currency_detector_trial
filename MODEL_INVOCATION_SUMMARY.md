# Model Invocation Summary

## Quick Answer: How is the model invoked?

The `best_float32.tflite` model is invoked through this sequence:

### 1. **Load Model** (Once at startup)
- File: `lib/screens/detection_screen.dart` → `_initializeCamera()`
- Calls: `DetectionProvider.initialize()` → `CurrencyDetector.initialize()`
- Action: `Interpreter.fromAsset('assets/models/best_float32.tflite')`
- Result: Model loaded into memory, ready for inference

### 2. **Start Frame Stream** (Once at startup)
- File: `lib/screens/detection_screen.dart` → `_initializeCamera()`
- Calls: `_cameraController.startImageStream()`
- Action: Camera begins capturing frames at ~30 FPS
- Result: Each frame sent to the detection callback

### 3. **Process Each Frame** (30 times per second)
- File: `lib/providers/detection_provider.dart` → `processFrame()`
- Receives: `CameraImage` from camera stream
- Calls: `CurrencyDetector.detect(cameraImage)`
- Steps:
  1. **Prepare Input**: Convert camera frame (YUV/BGRA) to normalized RGB tensor [1, 640, 640, 3]
  2. **Run Inference**: `_interpreter.run(input, output)`
     - Input: [1, 640, 640, 3] float tensor
     - Output: [1, 25200, 85] predictions
  3. **Parse Output**: Extract bounding boxes, confidence scores, class IDs
  4. **Apply NMS**: Remove duplicate overlapping detections
  5. **Return Detections**: List of `CurrencyDetection` objects

### 4. **Update UI** (After each frame)
- File: `lib/painters/detection_painter.dart`
- Receives: List of detections from provider
- Action: Draws bounding boxes on camera preview
- Displays: Label and confidence percentage for each detection

## Where in the Code?

| Component | File | Method | Purpose |
|-----------|------|--------|---------|
| **Initialization** | `lib/screens/detection_screen.dart` | `_initializeCamera()` | Load model, start camera stream |
| **Provider** | `lib/providers/detection_provider.dart` | `processFrame()` | Manage detection state, call detector |
| **Detector** | `lib/services/yolo_detector.dart` | `detect()` | Run model inference |
| **Input** | `lib/services/yolo_detector.dart` | `_prepareInput()` | Convert camera frame to tensor |
| **Inference** | `lib/services/yolo_detector.dart` | `detect()` line: `_interpreter.run(input, output)` | **MODEL EXECUTION** |
| **Output** | `lib/services/yolo_detector.dart` | `_parseOutput()` | Extract detections from raw output |
| **UI** | `lib/painters/detection_painter.dart` | `paint()` | Draw boxes on screen |

## Debug Logs

To verify the model is working, run the app and watch for these logs:

**Startup:**
```
📹 Initializing currency detector model...
✓ Currency detector model loaded successfully
✓ Currency detector ready!
📸 Starting camera frame stream...
▶ Live detection started
```

**During detection:**
```
🖼️  Camera frame: 1080x2400, Format: ImageFormatGroup.yuv420
✓ Input tensor prepared: [1, 640, 640, 3]
📊 Parsing output - Type: List<dynamic>, Length: 25200
🎯 Detected 3 objects
   - 500_back: 92.5%
   - 100_front: 87.3%
   - security_thread: 78.1%
```

**If there's an error:**
```
❌ Error during inference: {error details}
❌ Error processing frame: {error details}
```

## What the Model Does

1. **Takes Input**: 640x640 normalized RGB image
2. **Predicts**: 25,200 potential objects (from YOLOv8 grid)
3. **For Each**: Provides:
   - Bounding box: center (x, y), width, height
   - Confidence: 0.0-1.0 (how sure it is about detecting something)
   - Class scores: probabilities for each of 25 currency classes
4. **Returns**: Objects with confidence > 0.5, with duplicate boxes removed

## Model Classes (25 total)

```
Currency notes: 100_back, 100_front, 200_back, 200_front, 500_back, 500_front, 50_back, 50_front
Security features: Gandhi_potrait, ashoka_piller, bleed_lines, color_chg_num, denomination_back, 
guarentee_clause, language_panel, lined_number, micro_text, monumental_portrait, 
note_50_see_throug, res_bank, security_thread, see_through_reg, serial_number, 
swatch_bharath, white_number
```

## Common Issues & Fixes

| Problem | Likely Cause | Fix |
|---------|-------------|-----|
| No logs from model | Camera frames not reaching detector | Check `startImageStream()` is called |
| Model loaded but no detections | Threshold too high or bad input | Lower `confidenceThreshold` to 0.3 |
| App crashes on detection | Input format mismatch | Check camera format handling in `_prepareInput()` |
| Wrong label names | Class list doesn't match model | Update `currencyClasses` in `yolo_detector.dart` |
| Black screen | Camera permission missing | Grant camera permission on device |
