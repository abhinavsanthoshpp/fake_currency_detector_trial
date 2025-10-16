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

      // Add some demo data if box is empty
      if (_box != null && _box!.isEmpty) {
        await _addDemoData();
      }
    } catch (e) {
      print('Database initialization error: $e');
      // Fallback: create a simple box without type safety
      _box = await Hive.openBox<ScanResult>(_boxName);
    }
  }

  static Future<void> _addDemoData() async {
    if (_box == null) return;

    try {
      final demoData = [
        ScanResult(
          currencyType: 'INR ₹100',
          resultStatus: 'Authentic',
          confidenceLevel: 0.98,
          dateTime: DateTime.now().subtract(const Duration(hours: 2)),
        ),
        ScanResult(
          currencyType: 'INR ₹200',
          resultStatus: 'Suspicious',
          confidenceLevel: 0.65,
          dateTime: DateTime.now().subtract(const Duration(days: 1, hours: 5)),
        ),
        ScanResult(
          currencyType: 'INR ₹500',
          resultStatus: 'Authentic',
          confidenceLevel: 0.96,
          dateTime: DateTime.now().subtract(const Duration(days: 1, hours: 9)),
        ),
        ScanResult(
          currencyType: 'INR ₹2000',
          resultStatus: 'Authentic',
          confidenceLevel: 0.99,
          dateTime: DateTime.now().subtract(const Duration(days: 4, hours: 1)),
        ),
      ];

      for (final data in demoData) {
        await _box!.add(data);
      }
    } catch (e) {
      print('Error adding demo data: $e');
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
      // Return hardcoded demo data as fallback
      return [
        ScanResult(
          currencyType: 'INR ₹100',
          resultStatus: 'Authentic',
          confidenceLevel: 0.98,
          dateTime: DateTime.now().subtract(const Duration(hours: 2)),
        ),
        ScanResult(
          currencyType: 'INR ₹200',
          resultStatus: 'Suspicious',
          confidenceLevel: 0.65,
          dateTime: DateTime.now().subtract(const Duration(days: 1, hours: 5)),
        ),
      ];
    }
    return _box!.values.toList().reversed.toList();
  }

  static Future<void> clearAllResults() async {
    if (_box != null) {
      await _box!.clear();
    }
  }
}
