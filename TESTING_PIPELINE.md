# Testing the YOLO Detection Pipeline

## 🧪 How to Test the Implementation

### 1. Build and Run

```bash
# Clean build
flutter clean
flutter pub get

# Run on connected device
flutter run
```

### 2. What to Observe

#### A. Console Logs (Terminal Output)

When the scanner screen starts, you should see:

```
📹 Initializing currency detector model...
✓ Currency detector model loaded successfully
📸 Starting camera frame stream...
▶ Live detection started

═══════════════════════════════════════
🎬 YOLO PIPELINE START
═══════════════════════════════════════
📷 STEP 1: Camera Image Received
   └─ Size: 1920x1080
⚙️  STEP 2: Preprocessing...
   └─ Resized to: 640x640
   └─ Normalized: 0.0 to 1.0
🧠 STEP 3: Running YOLO Model...
   └─ Model Output Shape: [1, 29, 8400]
📊 STEP 4: Parsing Raw Outputs...
🔧 STEP 5: Applying NMS (Post-processing)...
   └─ NMS Input: 45 detections
   └─ NMS Output: 12 detections (removed 33)
✅ STEP 6: Final Detections: 12
═══════════════════════════════════════
```

#### B. On-Screen Display

You should see:

1. **Top Right Corner** - Pipeline Status Box:
   ```
   ⚡ YOLO Pipeline
   1️⃣ Camera Input ✓
   2️⃣ Preprocessing ✓
   3️⃣ YOLO Model ✓
   4️⃣ Raw Outputs ✓
   5️⃣ NMS Filter ✓
   6️⃣ Display Boxes ✓
   ```

2. **Live Camera Feed** - With colored bounding boxes around detected currency features

3. **Bottom Panel** - Detection information:
   ```
   📦 Bounding Boxes: 3
   
   Detected Objects:
   ✓ 500_front: 92.3%
   ✓ Gandhi_potrait: 88.7%
   ✓ security_thread: 76.5%
   ```

### 3. Testing Scenarios

#### Scenario 1: No Currency in View
- **Expected**: Bottom panel shows "⏳ Scanning for currency..."
- **Console**: Pipeline runs but no detections above threshold

#### Scenario 2: Currency Note Visible
- **Expected**: 
  - Bounding boxes appear around note features
  - Labels show feature names and confidence
  - Detection count updates in real-time
- **Console**: Shows detection counts and confidence ranges

#### Scenario 3: Multiple Notes
- **Expected**:
  - Multiple bounding boxes for different notes
  - NMS removes overlapping duplicates
  - Top 3 detections shown in panel
- **Console**: Higher detection counts, NMS filters duplicates

### 4. Performance Metrics to Check

| Metric | Expected Value | What to Check |
|--------|----------------|---------------|
| Frame Processing Time | 100-150ms | Console logs show completion time |
| Detection Rate | 5-10 FPS | UI updates smoothly |
| Memory Usage | < 500MB | Monitor device performance |
| CPU Usage | 40-60% | Should not cause overheating |

### 5. Common Issues & Solutions

#### Issue: No detections appearing

**Possible Causes:**
1. Model not loaded properly
2. Confidence threshold too high
3. Poor lighting conditions

**Solutions:**
```dart
// In yolo_detector.dart, temporarily lower threshold
static const double confidenceThreshold = 0.05; // Lower from 0.1
```

#### Issue: Too many false detections

**Possible Causes:**
1. Confidence threshold too low
2. NMS threshold too high

**Solutions:**
```dart
// Increase confidence threshold
static const double confidenceThreshold = 0.3; // Higher from 0.1

// Decrease IoU threshold for stricter NMS
static const double iouThreshold = 0.3; // Lower from 0.5
```

#### Issue: App runs slowly

**Possible Causes:**
1. Processing every frame
2. Device limitations

**Solutions:**
```dart
// In scanner_screen.dart, skip more frames
if (_frameSkipCounter % 3 != 0) {  // Skip 2 out of 3 frames
  return;
}
```

#### Issue: Bounding boxes not aligned

**Possible Causes:**
1. Camera rotation/orientation
2. Coordinate scaling issues

**Check:**
- Camera preview size matches canvas size in DetectionPainter
- Coordinate transformations account for rotation

### 6. Debug Mode

To enable verbose logging, modify [yolo_detector.dart](lib/services/yolo_detector.dart):

```dart
// Add at the top of detect() method
final debugMode = true;

if (debugMode) {
  print('Image format: ${cameraImage.format.group}');
  print('Input tensor prepared');
  print('Running inference...');
  // ... more debug prints
}
```

### 7. Validation Checklist

- [ ] App builds without errors
- [ ] Camera initializes successfully
- [ ] Model loads without crashes
- [ ] Pipeline logs appear in console
- [ ] Bounding boxes visible on screen
- [ ] Detection count updates in real-time
- [ ] Labels show correct currency features
- [ ] NMS removes duplicate detections
- [ ] App runs smoothly (no lag)
- [ ] Memory usage is reasonable

### 8. Expected Output Example

When pointing camera at a ₹500 note:

**Console:**
```
📊 STEP 4: Parsing Raw Outputs...
📈 Confidence range: min=0.0234, max=0.9456
🎯 Found 156 detections above threshold, 156 after NMS
🔧 STEP 5: Applying NMS (Post-processing)...
   └─ NMS Input: 156 detections
   └─ NMS Output: 8 detections (removed 148)
✅ STEP 6: Final Detections: 8
✅ 8 objects detected
```

**Screen:**
- Bounding box around the entire note (500_front)
- Bounding box around Gandhi portrait
- Bounding box around security thread
- Bounding box around Ashoka pillar
- etc.

**Bottom Panel:**
```
📦 Bounding Boxes: 8

Detected Objects:
✓ 500_front: 94.6%
✓ Gandhi_potrait: 88.2%
✓ security_thread: 82.7%
   +5 more...
```

## 🎯 Success Criteria

The implementation is working correctly when:

1. ✅ All 6 pipeline steps execute in sequence
2. ✅ Detections appear within 150ms of frame capture
3. ✅ Bounding boxes accurately surround currency features
4. ✅ Confidence scores are reasonable (>0.5 for good images)
5. ✅ NMS successfully removes duplicates
6. ✅ UI remains responsive and smooth

## 📞 Troubleshooting Commands

```bash
# Check model file exists
ls -la assets/models/best_float32.tflite

# Verify pubspec includes model asset
grep "best_float32.tflite" pubspec.yaml

# Check TFLite Flutter dependency
flutter pub deps | grep tflite

# Clear cache and rebuild
flutter clean
flutter pub get
flutter run --release  # For better performance
```

---

**Ready to Test!** Run the app and point your camera at Indian currency notes (₹50, ₹100, ₹200, ₹500, ₹2000) to see the YOLO pipeline in action! 🚀
