import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';

class SecurityService {
  // Golden Hashes (Generated on 2026-03-10)
  // best_float32.tflite
  static const String _yoloHash = "8803590E36EB141E83F2735ED6CF3F4D2DEEC7287C5E20CB66EE7AD4E1052112";
  // verifier.tflite
  static const String _verifierHash = "D8387770332D96847D5C8336BB7174FA654DB780B8D0B2494891C98955BBA31F";

  static Future<bool> verifyModelIntegrity() async {
    try {
      print("🔐 Security: Verifying model integrity...");
      
      // 1. Verify YOLO Model
      bool yoloOk = await _verifyFileHash('assets/models/best_float32.tflite', _yoloHash);
      if (!yoloOk) {
        print("❌ Security Alert: YOLO model hash mismatch!");
        return false;
      }

      // 2. Verify Verifier Model
      bool verifierOk = await _verifyFileHash('assets/models/verifier.tflite', _verifierHash);
      if (!verifierOk) {
        print("❌ Security Alert: Verifier model hash mismatch!");
        return false;
      }

      print("✅ Security: All models verified. Integrity intact.");
      return true;
    } catch (e) {
      print("❌ Security Error: Could not verify models: $e");
      return false; // Fail secure
    }
  }

  static Future<bool> _verifyFileHash(String assetPath, String expectedHash) async {
    final ByteData data = await rootBundle.load(assetPath);
    final List<int> bytes = data.buffer.asUint8List();
    
    // Calculate SHA-256
    final digest = sha256.convert(bytes);
    final String actualHash = digest.toString().toUpperCase();
    
    return actualHash == expectedHash;
  }
}
