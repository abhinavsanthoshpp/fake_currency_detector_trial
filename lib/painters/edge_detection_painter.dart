import 'package:flutter/material.dart';
import '../utils/constants.dart';

class EdgeDetectionPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2 - 100;
    final frameWidth = size.width * 0.7;
    final frameHeight = frameWidth * 0.6;

    // Draw scanner frame
    final framePaint = Paint()
      ..color = const Color(0x40636363)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final frameRect = Rect.fromCenter(
      center: Offset(centerX, centerY),
      width: frameWidth,
      height: frameHeight,
    );

    canvas.drawRect(frameRect, framePaint);

    // Draw corners
    final cornerPaint = Paint()
      ..color = AppColors.primaryBlue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final cornerLength = 20.0;

    // Top left corner
    canvas.drawLine(
      Offset(frameRect.left, frameRect.top),
      Offset(frameRect.left + cornerLength, frameRect.top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(frameRect.left, frameRect.top),
      Offset(frameRect.left, frameRect.top + cornerLength),
      cornerPaint,
    );

    // Top right corner
    canvas.drawLine(
      Offset(frameRect.right, frameRect.top),
      Offset(frameRect.right - cornerLength, frameRect.top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(frameRect.right, frameRect.top),
      Offset(frameRect.right, frameRect.top + cornerLength),
      cornerPaint,
    );

    // Bottom left corner
    canvas.drawLine(
      Offset(frameRect.left, frameRect.bottom),
      Offset(frameRect.left + cornerLength, frameRect.bottom),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(frameRect.left, frameRect.bottom),
      Offset(frameRect.left, frameRect.bottom - cornerLength),
      cornerPaint,
    );

    // Bottom right corner
    canvas.drawLine(
      Offset(frameRect.right, frameRect.bottom),
      Offset(frameRect.right - cornerLength, frameRect.bottom),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(frameRect.right, frameRect.bottom),
      Offset(frameRect.right, frameRect.bottom - cornerLength),
      cornerPaint,
    );

    // Draw scanning line
    final linePaint = Paint()
      ..color = const Color(0x500063F7)
      ..style = PaintingStyle.fill;

    final lineHeight = 2.0;
    final lineAnimation = DateTime.now().millisecond / 1000;
    final lineY = frameRect.top + (frameRect.height * lineAnimation);

    canvas.drawRect(
      Rect.fromLTWH(
        frameRect.left,
        lineY,
        frameRect.width,
        lineHeight,
      ),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
