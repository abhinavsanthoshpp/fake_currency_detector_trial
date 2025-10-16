import 'package:flutter/material.dart';
import 'dart:io';
import '../utils/constants.dart';
import '../database/database_service.dart';
import '../database/scan_result.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.scanHistory),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Clear All History'),
                  content: const Text(
                      'Are you sure you want to delete all scan history?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Clear All',
                          style: TextStyle(color: AppColors.errorRed)),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                await DatabaseService.clearAllResults();
                setState(() {});
              }
            },
          ),
        ],
      ),
      body: FutureBuilder<List<ScanResult>>(
        future: Future.value(DatabaseService.getAllScanResults()),
        builder: (context, snapshot) {
          final results = snapshot.data ?? [];

          if (results.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 64, color: AppColors.textGray),
                  SizedBox(height: 16),
                  Text(
                    'No scan history yet',
                    style: TextStyle(fontSize: 18, color: AppColors.textGray),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Start scanning currency to see history',
                    style: TextStyle(color: AppColors.textGray),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: results.length,
            itemBuilder: (context, index) {
              final result = results[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildHistoryItem(result),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildHistoryItem(ScanResult result) {
    final isAuthentic = result.resultStatus == 'Authentic';

    return Container(
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
      child: Row(
        children: [
          // Image or icon
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey[200],
            ),
            child:
                result.imagePath != null && File(result.imagePath!).existsSync()
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(result.imagePath!),
                          fit: BoxFit.cover,
                        ),
                      )
                    : Icon(
                        Icons.monetization_on,
                        size: 30,
                        color: isAuthentic
                            ? AppColors.successGreen
                            : AppColors.errorRed,
                      ),
          ),

          const SizedBox(width: 16),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result.currencyType,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  result.formattedDate,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textGray,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Confidence: ${(result.confidenceLevel * 100).toStringAsFixed(1)}%',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textGray,
                  ),
                ),
              ],
            ),
          ),

          // Status badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isAuthentic
                  ? AppColors.successGreenLight
                  : AppColors.errorRedLight,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              result.resultStatus,
              style: TextStyle(
                color:
                    isAuthentic ? AppColors.successGreen : AppColors.errorRed,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
