import 'package:flutter/material.dart';
import 'dart:io';
import '../utils/constants.dart';
import '../database/database_service.dart';
import '../database/scan_result.dart';

class ResultsScreen extends StatefulWidget {
  final String? imagePath;
  final VoidCallback? onBack; // ADD THIS

  const ResultsScreen({Key? key, this.imagePath, this.onBack})
      : super(key: key);

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  ScanResult? latestScan;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLatestScan();
  }

  Future<void> _loadLatestScan() async {
    try {
      final scans = DatabaseService.getAllScanResults();
      if (scans.isNotEmpty) {
        setState(() {
          latestScan = scans.first; // Most recent scan
          isLoading = false;
        });
      } else {
        // Fallback demo data
        setState(() {
          latestScan = ScanResult(
            currencyType: 'INR ₹500',
            resultStatus: 'Authentic',
            confidenceLevel: 0.986,
            dateTime: DateTime.now(),
            imagePath: widget.imagePath,
          );
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final scan = latestScan!;
    final isAuthentic = scan.resultStatus == 'Authentic';

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: const Text('Scan Results'),
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
            // Image preview (if available)
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

            // Result banner
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
                    scan.resultStatus,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isAuthentic
                          ? AppColors.successGreen
                          : AppColors.errorRed,
                    ),
                  ),
                  Text(
                    scan.currencyType,
                    style: const TextStyle(
                        fontSize: 18, color: AppColors.textGray),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Confidence level
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.trending_up, color: AppColors.primaryBlue),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Confidence Level',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                        Text(
                          '${(scan.confidenceLevel * 100).toStringAsFixed(1)}%',
                          style: const TextStyle(
                              fontSize: 14, color: AppColors.textGray),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Scan details
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildDetailRow('Scanned', scan.formattedDate),
                  const Divider(),
                  _buildDetailRow('Currency', scan.currencyType),
                  const Divider(),
                  _buildDetailRow('Status', scan.resultStatus),
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
                child: const Text(
                  'Scan Another Currency',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
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
