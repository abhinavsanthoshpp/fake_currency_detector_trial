import 'package:flutter/material.dart';
import 'dart:io';
import '../l10n/app_localizations.dart';
import '../utils/constants.dart';
// Remove database imports, as we get data directly now
// import '../database/database_service.dart';
// import '../database/scan_result.dart';

class ResultsScreen extends StatefulWidget {
  final String? imagePath;
  final VoidCallback? onBack;
  final List<Map<String, dynamic>> yoloResults; // Add this

  const ResultsScreen({
    Key? key,
    this.imagePath,
    this.onBack,
    required this.yoloResults, // Add this
  }) : super(key: key);

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  // Detailed security features with individual scores
  Map<String, double> securityFeatures = {};
  double overallScore = 0.0;
  String currencyType = "Unknown Currency";
  String resultStatus = "Undetermined";

  @override
  void initState() {
    super.initState();
    _processYoloResults();
  }

  void _processYoloResults() {
    if (widget.yoloResults.isEmpty) {
      return;
    }

    Map<String, double> features = {};
    for (var result in widget.yoloResults) {
      String tag = result['tag'];
      bool isGenuine = result['isGenuine'] ?? false;
      features[tag] = isGenuine ? 1.0 : 0.0;
    }

    double totalScore = 0;
    features.forEach((key, value) {
      totalScore += value;
    });

    setState(() {
      securityFeatures = features;
      if (features.isNotEmpty) {
        overallScore = totalScore / features.length;
      }
      
      // Determine overall currency type and status from YOLO results.
      // This is a simple logic, can be improved.
      final uniqueTags = widget.yoloResults.map((r) => r['tag'].split('_').first).toSet();
      currencyType = uniqueTags.join(', ');
      resultStatus = overallScore > 0.7 ? "Authentic" : "Suspicious";
    });
  }

  // _generateFeatureScore is no longer needed

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    if (widget.yoloResults.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text(localizations.scanResults),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (widget.onBack != null) {
                widget.onBack!();
              } else {
                Navigator.of(context).pop();
              }
            },
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline,
                  size: 64, color: AppColors.textGray),
              const SizedBox(height: 16),
              Text(
                'No features detected.', // Changed message
                style: const TextStyle(fontSize: 18, color: AppColors.textGray),
              ),
            ],
          ),
        ),
      );
    }

    final isAuthentic = overallScore > 0.7;

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: Text(localizations.scanResults),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (widget.onBack != null) {
              widget.onBack!();
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Image preview
            if (widget.imagePath != null) ...[
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey[200],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: File(widget.imagePath!).existsSync()
                      ? Image.file(
                          File(widget.imagePath!),
                          fit: BoxFit.cover,
                        )
                      : const Icon(Icons.image, size: 50, color: Colors.grey),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Overall Result Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isAuthentic
                    ? AppColors.successGreenLight
                    : AppColors.errorRedLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Icon(
                    isAuthentic ? Icons.verified : Icons.warning,
                    size: 48,
                    color: isAuthentic
                        ? AppColors.successGreen
                        : AppColors.errorRed,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    resultStatus,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isAuthentic
                          ? AppColors.successGreen
                          : AppColors.errorRed,
                    ),
                  ),
                  Text(
                    currencyType,
                    style: const TextStyle(
                        fontSize: 18, color: AppColors.textGray),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Overall Analysis Score
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.analytics, color: AppColors.primaryBlue),
                      const SizedBox(width: 12),
                      const Text(
                        'Overall Security Analysis',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Average Score',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${(overallScore * 100).toStringAsFixed(1)}%',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: overallScore > 0.7
                                    ? AppColors.successGreen
                                    : AppColors.errorRed,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 80,
                        height: 80,
                        child: Stack(
                          children: [
                            Center(
                              child: SizedBox(
                                width: 70,
                                height: 70,
                                child: CircularProgressIndicator(
                                  value: overallScore,
                                  strokeWidth: 8,
                                  backgroundColor: Colors.grey[300],
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    overallScore > 0.7
                                        ? AppColors.successGreen
                                        : AppColors.errorRed,
                                  ),
                                ),
                              ),
                            ),
                            Center(
                              child: Text(
                                '${(overallScore * 100).round()}%',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Detailed Security Features Analysis
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.security, color: AppColors.primaryBlue),
                      const SizedBox(width: 12),
                      const Text(
                        'Security Features Verification',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Security features list
                  ...securityFeatures.entries
                      .map((entry) => _buildSecurityFeatureItem(
                            entry.key,
                            entry.value,
                          ))
                      .toList(),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Scan Information
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildDetailRow(localizations.scanned, DateTime.now().toLocal().toString()), // Use current date
                  const Divider(),
                  _buildDetailRow(localizations.currency, currencyType),
                  const Divider(),
                  _buildDetailRow(localizations.status, resultStatus),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Action button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (widget.onBack != null) {
                    widget.onBack!();
                  } else {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  padding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  localizations.scanAnotherCurrency,
                  style: const TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityFeatureItem(String featureName, double score) {
    final isGood = score > 0.7;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: isGood
                  ? AppColors.successGreenLight
                  : AppColors.errorRedLight,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isGood ? Icons.check : Icons.close,
              size: 16,
              color: isGood ? AppColors.successGreen : AppColors.errorRed,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  featureName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: LinearProgressIndicator(
                        value: score,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isGood ? AppColors.successGreen : AppColors.errorRed,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${(score * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isGood
                            ? AppColors.successGreen
                            : AppColors.errorRed,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 16, color: AppColors.textGray),
          ),
        ),
      ],
    );
  }
}