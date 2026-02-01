import 'package:flutter/material.dart';

class DetectionPainter extends CustomPainter {
  final List<Map<String, dynamic>> detections;
  final Size imageSize;
  final Size canvasSize;

  DetectionPainter({
    required this.detections,
    required this.imageSize,
    required this.canvasSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = Colors.red;

    for (final detection in detections) {
      final boundingBox = detection['box'];
      final x = boundingBox[0];
      final y = boundingBox[1];
      final w = boundingBox[2];
      final h = boundingBox[3];

      final rect = Rect.fromLTWH(x, y, w, h);
      canvas.drawRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
