# VeriScan Pro - Code Structure Documentation

## 📁 Project Structure

The code has been refactored from a monolithic `main.dart` file into a well-organized, modular structure for better maintainability and analysis.

```
lib/
├── main.dart                           # App entry point and root widget
├── screens/                            # Screen-level widgets
│   ├── home_screen.dart               # Main navigation with bottom tabs
│   ├── scanner_screen.dart            # Camera scanner with detection
│   ├── results_screen.dart            # Scan results and verification details
│   └── history_screen.dart            # Scan history list
├── widgets/                            # Reusable widget components
│   └── home_content.dart              # Home screen content
├── painters/                           # Custom painters
│   └── edge_detection_painter.dart    # Scanner overlay with frame
└── utils/                              # Utilities and constants
    └── constants.dart                 # Colors and strings
```

---

## 📄 File Descriptions

### **main.dart** (51 lines)
**Purpose:** App initialization and root configuration
**Contents:**
- `main()` function - Camera initialization
- `VeriScanProApp` widget - MaterialApp setup with theme

---

### **screens/home_screen.dart** (143 lines)
**Purpose:** Main navigation container with bottom tabs
**Key Components:**
- `HomeScreen` - StatefulWidget managing navigation state
- Bottom navigation bar (Home, Scan, History)
- Floating action button for quick scan
- Conditional AppBar display

**Navigation:**
- Index 0: HomeContent widget
- Index 1: ScannerScreen
- Index 2: HistoryScreen

---

### **screens/scanner_screen.dart** (368 lines)
**Purpose:** Camera-based banknote scanning interface
**Key Features:**
- Camera permission handling
- Real-time camera preview
- Edge detection overlay
- Simulated detection progress
- Bottom sheet with scanning instructions/results
- Flash toggle button

**State Variables:**
- `_controller` - Camera controller
- `_isDetected` - Detection status
- `_hasPermission` - Permission status
- `_confidenceLevel` - Analysis progress (0.0 - 1.0)
- `_detectedCurrency` - Detected currency string

---

### **screens/results_screen.dart** (168 lines)
**Purpose:** Detailed verification results display
**Sections:**
- Authentication verdict banner
- Confidence metrics (98.6%)
- Checks passed count (12/13)
- Security features checklist:
  - Watermark
  - Security Thread
  - Color-Shifting Ink
  - Microprinting
  - 3D Security Ribbon
- Save to History button

---

### **screens/history_screen.dart** (105 lines)
**Purpose:** Display list of past scans
**Features:**
- ListView with scan history items
- Status badges (Authentic/Suspicious)
- Currency type and timestamp
- Color-coded indicators

**Sample Data:**
- USD $100 - Today, 10:22 AM - Authentic
- EUR €50 - Yesterday, 6:40 PM - Suspicious
- INR ₹500 - Yesterday, 2:15 PM - Authentic
- GBP £20 - Oct 12, 11:30 AM - Authentic

---

### **widgets/home_content.dart** (271 lines)
**Purpose:** Home screen dashboard content
**Sections:**
1. **Welcome Section:**
   - Welcome message
   - App description
   - Lighting tip banner

2. **Quick Actions:**
   - Live Banknote Scan button

3. **Recent Scans:**
   - Last 2 scan previews
   - Tap to view details
   - "View all" navigation

---

### **painters/edge_detection_painter.dart** (107 lines)
**Purpose:** Custom painter for scanner overlay
**Visual Elements:**
- Semi-transparent scanning frame (70% screen width)
- Blue corner markers (4 corners)
- Animated scanning line
- Aspect ratio: 0.6 (width:height)

**Animation:**
- Uses `DateTime.now().millisecond` for line position
- `shouldRepaint: true` for continuous animation

---

### **utils/constants.dart** (46 lines)
**Purpose:** Centralized app constants
**Classes:**

#### `AppColors`
- `primaryBlue` - #0063F7
- `backgroundColor` - #F8FAFC
- `textDark` - #1D232C
- `textGray` - #8391A1
- `successGreen` - #21BF73
- `successGreenLight` - #E1F7E9
- `errorRed` - #FF5A5A
- `errorRedLight` - #FFECEB
- `lightBlueBackground` - #F0F5FF

#### `AppStrings`
All user-facing text strings including:
- App titles
- Screen titles
- Instructions
- Button labels
- Status messages

---

## 🔄 Data Flow

```
main.dart
  └─> HomeScreen (navigation hub)
      ├─> HomeContent (index 0)
      │   └─> Navigator.push -> ResultsScreen
      ├─> ScannerScreen (index 1)
      │   └─> Navigator.push -> ResultsScreen
      └─> HistoryScreen (index 2)
```

---

## 🎨 Shared Resources

### Colors
All colors are defined in `AppColors` class and used consistently across all screens.

### Strings
All text is defined in `AppStrings` class for easy localization in the future.

### Theme
Material theme is configured in `VeriScanProApp` with:
- Primary color: Blue (#0063F7)
- Font family: Roboto
- White AppBar with no elevation
- Light background (#F8FAFC)

---

## 📦 Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  camera: ^0.10.5                  # Camera access
  permission_handler: ^11.0.1      # Permission requests
```

---

## 🚀 Running the App

```bash
# Clean build artifacts
flutter clean

# Get dependencies
flutter pub get

# Run on connected device
flutter run
```

---

## 🐛 Known Issues

1. **Simulated Detection:** The scanner currently simulates detection with timers - no actual ML model integrated
2. **Hardcoded Data:** Results and history use static sample data
3. **No Persistence:** No database - scans are not actually saved
4. **Flash Button:** Flash toggle has empty `onPressed` handler
5. **Animation Performance:** EdgeDetectionPainter uses `DateTime.now()` instead of `AnimationController`

---

## ✅ Benefits of Refactoring

1. **Modularity:** Each screen in its own file
2. **Maintainability:** Easy to locate and modify specific features
3. **Reusability:** Constants can be reused across all screens
4. **Testability:** Individual components can be unit tested
5. **Collaboration:** Multiple developers can work on different files
6. **Code Analysis:** Easier to analyze and understand each component
7. **Scalability:** Easy to add new screens and features
8. **Clean Architecture:** Separation of concerns (screens, widgets, utils)

---

## 📝 Next Steps for Development

1. **State Management:** Implement Provider/Riverpod for app state
2. **Data Models:** Create model classes (ScanResult, Currency, etc.)
3. **Services Layer:** Separate business logic from UI
4. **Database:** Add SQLite/Hive for persistence
5. **ML Integration:** Integrate TensorFlow Lite for real detection
6. **Testing:** Add unit and widget tests
7. **Documentation:** Add dartdoc comments to all public APIs

---

## 📊 Lines of Code Summary

| File | Lines | Purpose |
|------|-------|---------|
| main.dart | 51 | App initialization |
| home_screen.dart | 143 | Navigation hub |
| scanner_screen.dart | 368 | Camera scanning |
| results_screen.dart | 168 | Verification details |
| history_screen.dart | 105 | Scan history |
| home_content.dart | 271 | Home dashboard |
| edge_detection_painter.dart | 107 | Scanner overlay |
| constants.dart | 46 | App constants |
| **Total** | **1,259** | **Organized code** |

Original monolithic file: ~1,200 lines
Refactored total: ~1,259 lines (includes better spacing and organization)

---

*Last Updated: October 16, 2025*
