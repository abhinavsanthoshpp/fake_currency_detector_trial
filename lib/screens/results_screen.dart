import 'dart:io';
import 'package:flutter/material.dart';
import '../utils/constants.dart';
import 'scanner_screen.dart';

class ResultsScreen extends StatelessWidget {
  final String imagePath;
  final VoidCallback? onBack;

  // make imagePath optional with default empty string so callers can use ResultsScreen()
  const ResultsScreen({super.key, this.imagePath = '', this.onBack});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.scanResults),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (onBack != null) {
              onBack!();
              return;
            }
            // fallback to previous behavior
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const ScannerScreen()),
            );
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✅ Display captured image
            if (imagePath.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                height: 250,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    File(imagePath),
                    fit: BoxFit.cover,
                  ),
                ),
              ),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.successGreenLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified,
                      color: AppColors.successGreen, size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          AppStrings.authenticBanknote,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.successGreen,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'INR 100 • Series 2017 • Detected in 2.8s',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildResultMetric('Confidence', '98.6%'),
                _buildResultMetric('Checks Passed', '12/13'),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              AppStrings.securityFeaturesVerified,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildSecurityFeature('Watermark',
                'Benjamin Franklin portrait clearly visible', true),
            _buildSecurityFeature(
                'Security Thread', 'UV-reactive strip detected', true),
            _buildSecurityFeature(
                'Color-Shifting Ink', 'Numeral 100 changes color', true),
            _buildSecurityFeature(
                'Microprinting', 'Clear and legible under magnification', true),
            _buildSecurityFeature(
                '3D Security Ribbon', 'Bells change to 100s when tilted', true),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildResultMetric(String title, String value) {
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildSecurityFeature(String title, String description, bool passed) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            passed ? Icons.check_circle : Icons.error,
            color: passed ? AppColors.successGreen : AppColors.errorRed,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Text(
            passed ? AppStrings.pass : AppStrings.review,
            style: TextStyle(
              color: passed ? AppColors.successGreen : AppColors.errorRed,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
