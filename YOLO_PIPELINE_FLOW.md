# YOLO Detection Pipeline - Complete Flow

## 🔄 Complete Pipeline Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    YOLO DETECTION PIPELINE                   │
└─────────────────────────────────────────────────────────────┘

📱 Camera / Image Input
   │
   │ CameraImage (YUV420 or BGRA8888)
   │ Original size: variable (e.g., 1920x1080)
   │
   ▼
┌─────────────────────────────────────────────────────────────┐
│  STEP 1: CAMERA IMAGE CAPTURE                               │
│  - Receives live camera frame                               │
│  - Format: YUV420 or BGRA8888                               │
└─────────────────────────────────────────────────────────────┘
   │
   ▼
┌─────────────────────────────────────────────────────────────┐
│  STEP 2: PREPROCESSING                                      │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━  │
│  A. Resize                                                  │
│     - Input: Original camera size                           │
│     - Output: 640x640 pixels                                │
│     - Method: Bilinear sampling                             │
│                                                              │
│  B. Color Conversion                                        │
│     - YUV420 → RGB or BGRA → RGB                           │
│     - 3 channels (Red, Green, Blue)                         │
│                                                              │
│  C. Normalization                                           │
│     - Range: 0-255 → 0.0-1.0                               │
│     - Formula: pixel_value / 255.0                          │
│                                                              │
│  Final Format: [1, 640, 640, 3]                            │
│  (batch_size, height, width, channels)                      │
└─────────────────────────────────────────────────────────────┘
   │
   ▼
┌─────────────────────────────────────────────────────────────┐
│  STEP 3: YOLO .TFLITE MODEL INFERENCE                       │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━  │
│  Model: best_float32.tflite                                 │
│  Type: YOLOv8 (or similar) for currency detection           │
│                                                              │
│  Input Tensor:                                              │
│    Shape: [1, 640, 640, 3]                                 │
│    Type: Float32                                            │
│    Range: 0.0 - 1.0 (normalized RGB)                       │
│                                                              │
│  Processing:                                                │
│    - Feature extraction through CNN layers                  │
│    - Multi-scale detection (80x80, 40x40, 20x20 grids)     │
│    - Anchor-based box predictions                           │
│                                                              │
│  Output Tensor:                                             │
│    Shape: [1, 29, 8400]                                    │
│    - 8400 predictions from all grid cells                   │
│    - 29 values per prediction                               │
└─────────────────────────────────────────────────────────────┘
   │
   ▼
┌─────────────────────────────────────────────────────────────┐
│  STEP 4: RAW OUTPUTS EXTRACTION                             │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━  │
│  Output Format: [29, 8400]                                  │
│                                                              │
│  For each of 8400 predictions:                              │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  Channel 0: X coordinate (center)                    │  │
│  │  Channel 1: Y coordinate (center)                    │  │
│  │  Channel 2: Width of bounding box                    │  │
│  │  Channel 3: Height of bounding box                   │  │
│  │  Channel 4: Objectness confidence (0.0 - 1.0)       │  │
│  │  Channels 5-28: Class scores for 24 classes         │  │
│  │     - 100_front, 100_back, 200_front, etc.          │  │
│  │     - security_thread, Gandhi_portrait, etc.         │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                              │
│  Parsing Process:                                           │
│    1. Extract bounding box coordinates (x, y, w, h)         │
│    2. Extract confidence score                              │
│    3. Find highest class score → determine class ID         │
│    4. Filter by confidence threshold (>= 0.1)               │
│    5. Create CurrencyDetection objects                      │
└─────────────────────────────────────────────────────────────┘
   │
   ▼
┌─────────────────────────────────────────────────────────────┐
│  STEP 5: POST-PROCESSING (NMS)                              │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━  │
│  Non-Maximum Suppression (NMS)                              │
│                                                              │
│  Purpose: Remove duplicate/overlapping detections           │
│                                                              │
│  Algorithm:                                                  │
│  1. Sort all detections by confidence (highest first)       │
│                                                              │
│  2. For each detection:                                     │
│     - Keep it as a final detection                          │
│     - Compare with remaining detections                     │
│     - Calculate IoU (Intersection over Union)               │
│     - If IoU > 0.5: suppress the lower confidence box       │
│                                                              │
│  IoU Formula:                                               │
│     IoU = Intersection Area / Union Area                    │
│                                                              │
│  Threshold: 0.5                                             │
│  - IoU >= 0.5: Boxes overlap significantly → suppress       │
│  - IoU < 0.5: Different objects → keep both                 │
│                                                              │
│  Result: Filtered list of unique detections                 │
└─────────────────────────────────────────────────────────────┘
   │
   ▼
┌─────────────────────────────────────────────────────────────┐
│  STEP 6: BOUNDING BOXES ON SCREEN                           │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━  │
│  Final Detections → Visual Display                          │
│                                                              │
│  For each detection:                                        │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  CurrencyDetection {                                 │  │
│  │    confidence: 0.923,                                │  │
│  │    label: "500_front",                               │  │
│  │    x: 0.5,     // normalized (0-1)                   │  │
│  │    y: 0.5,                                           │  │
│  │    width: 0.3,                                       │  │
│  │    height: 0.2                                       │  │
│  │  }                                                    │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                              │
│  Rendering (DetectionPainter):                              │
│  1. Scale normalized coords to screen size                  │
│  2. Draw colored rectangle (green for high confidence)      │
│  3. Draw label with confidence percentage                   │
│  4. Update UI in real-time (60 FPS)                         │
│                                                              │
│  Display Elements:                                          │
│  - Bounding box (colored rectangle)                         │
│  - Label text (e.g., "500_front 92.3%")                    │
│  - Detection count panel                                    │
│  - Pipeline status indicator                                │
└─────────────────────────────────────────────────────────────┘

```

## 📊 Data Flow Summary

| Step | Input | Output | Processing Time |
|------|-------|--------|-----------------|
| 1. Camera | Live feed | CameraImage | ~16ms (60fps) |
| 2. Preprocessing | Raw image | [1,640,640,3] tensor | ~20-30ms |
| 3. Model Inference | Normalized tensor | [1,29,8400] raw output | ~50-100ms |
| 4. Output Parsing | Raw tensor | List of detections | ~5-10ms |
| 5. NMS | All detections | Filtered detections | ~5ms |
| 6. Display | Detections | Screen rendering | ~16ms (60fps) |

**Total Pipeline: ~100-150ms per frame**

## 🎯 Detection Classes (24 Classes)

The model is trained to detect 24 different currency features:

1. `100_back` - ₹100 note back side
2. `100_front` - ₹100 note front side
3. `200_back` - ₹200 note back side
4. `200_front` - ₹200 note front side
5. `500_back` - ₹500 note back side
6. `500_front` - ₹500 note front side
7. `50_back` - ₹50 note back side
8. `50_front` - ₹50 note front side
9. `Gandhi_potrait` - Gandhi portrait feature
10. `ashoka_piller` - Ashoka pillar symbol
11. `bleed_lines` - Security bleed lines
12. `color_chg_num` - Color-changing number
13. `denomination_back` - Back denomination
14. `guarentee_clause` - Guarantee clause text
15. `language_panel` - Language panel
16. `lined_number` - Lined number feature
17. `micro_text` - Micro-printed text
18. `monumental_portrait` - Monument portrait
19. `note_50_see_throug` - ₹50 see-through feature
20. `res_bank` - Reserve Bank text
21. `security_thread` - Security thread
22. `see_through_reg` - See-through registration
23. `serial_number` - Serial number
24. `swatch_bharath` - Swachh Bharat logo
25. `white_number` - White number feature

## 🔧 Configuration Parameters

```dart
// Model Settings
static const int inputSize = 640;           // Input image size
static const double confidenceThreshold = 0.1;  // Minimum confidence
static const double iouThreshold = 0.5;     // NMS overlap threshold

// Frame Processing
int _frameSkipCounter = 0;                  // Skip every other frame
bool _isProcessingFrame = false;            // Prevent concurrent processing
```

## 📱 Implementation Files

1. **YOLODetector** (`lib/services/yolo_detector.dart`)
   - Model loading and initialization
   - Preprocessing (resize, normalize)
   - Model inference
   - Output parsing
   - NMS post-processing

2. **DetectionProvider** (`lib/providers/detection_provider.dart`)
   - State management
   - Frame processing coordination
   - Detection results storage

3. **DetectionPainter** (`lib/painters/detection_painter.dart`)
   - Bounding box rendering
   - Label text display
   - Coordinate scaling

4. **ScannerScreen** (`lib/screens/scanner_screen.dart`)
   - Camera stream handling
   - Real-time detection display
   - Pipeline status visualization

## 🚀 Performance Optimizations

1. **Frame Skipping**: Process every 2nd frame to reduce CPU load
2. **Concurrent Prevention**: Only one frame processed at a time
3. **Efficient Memory**: Reuse tensor buffers where possible
4. **Optimized Model**: Float32 TFLite for balance of speed/accuracy

## 📈 Expected Results

- **Detection Speed**: 10-15 FPS on mobile devices
- **Accuracy**: High confidence (>0.5) for clear currency images
- **False Positives**: Minimized by NMS and confidence threshold
- **Real-time**: Smooth live detection experience

## 🎨 Visual Indicators

### Scanner Screen UI
- **Top Right**: Pipeline status with 6 steps shown
- **Bottom Panel**: Detection count and top 3 detections
- **Overlay**: Colored bounding boxes on detected objects
- **Labels**: Object name + confidence percentage

### Color Coding
- **Green (High)**: Confidence > 0.7
- **Yellow (Medium)**: Confidence 0.4-0.7
- **Red (Low)**: Confidence < 0.4

---

**Last Updated**: January 4, 2026  
**Model Version**: YOLOv8 Float32 TFLite  
**Target Platform**: Flutter (Android/iOS)
