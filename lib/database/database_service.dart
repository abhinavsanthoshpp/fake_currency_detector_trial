import 'package:hive_flutter/hive_flutter.dart';
import 'scan_result.dart';

class DatabaseService {
  static const String _boxName = 'scan_history';
  static Box<ScanResult>? _box;

  static Future<void> init() async {
    try {
      await Hive.initFlutter();
      Hive.registerAdapter(ScanResultAdapter());
      _box = await Hive.openBox<ScanResult>(_boxName);
    } catch (e) {
      print('Database initialization error: $e');
      // Fallback: create a simple box without type safety
      _box = await Hive.openBox<ScanResult>(_boxName);
    }
  }

  static Box<ScanResult>? get box => _box;

  static Future<void> addScanResult(ScanResult result) async {
    if (_box != null) {
      await _box!.add(result);
    }
  }

  static List<ScanResult> getAllScanResults() {
    if (_box == null) {
      return []; // Return empty list instead of fake data
    }
    return _box!.values.toList().reversed.toList();
  }

  static Future<void> clearAllResults() async {
    if (_box != null) {
      await _box!.clear();
    }
  }

  // Helper method to get scan count
  static int getScanCount() {
    if (_box == null) return 0;
    return _box!.length;
  }

  // Helper method to get recent scans (limit)
  static List<ScanResult> getRecentScans(int limit) {
    if (_box == null) return [];
    final allScans = _box!.values.toList().reversed.toList();
    return allScans.take(limit).toList();
  }
}
