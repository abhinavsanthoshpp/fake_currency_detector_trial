import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:ui' as ui;
import '../utils/constants.dart';
import '../database/database_service.dart';
import '../database/scan_result.dart';
import '../l10n/app_localizations.dart';
import 'results_screen.dart'; // Import for BBoxPainter

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
        title: Text(AppLocalizations.of(context)!.scanHistory),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Clear All History'),
                  content: const Text('Are you sure you want to delete all scan history?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Clear All', style: TextStyle(color: AppColors.errorRed)),
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
                  Text('No scan history yet', style: TextStyle(fontSize: 18, color: AppColors.textGray)),
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

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => HistoryDetailScreen(result: result),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), spreadRadius: 1, blurRadius: 4)],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isAuthentic ? AppColors.successGreenLight : AppColors.errorRedLight,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isAuthentic ? Icons.verified : Icons.warning,
                color: isAuthentic ? AppColors.successGreen : AppColors.errorRed,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    result.resultStatus,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isAuthentic ? AppColors.successGreen : AppColors.errorRed,
                    ),
                  ),
                  Text(result.formattedDate, style: const TextStyle(fontSize: 14, color: AppColors.textGray)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

class HistoryDetailScreen extends StatelessWidget {
  final ScanResult result;

  const HistoryDetailScreen({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final isAuthentic = result.resultStatus == 'Authentic';

    return Scaffold(
      appBar: AppBar(title: const Text('Stored Scan Evidence')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- VISUAL EVIDENCE (CLARIFICATION) ---
            const Text("Visual Evidence (AI Detection)", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                if (result.imagePath != null)
                  Expanded(child: _buildImageWithBoxes("Front Side", result.imagePath!, result.yoloResults ?? [])),
                if (result.backImagePath != null) ...[
                  const SizedBox(width: 8),
                  Expanded(child: _buildImageWithBoxes("Back Side", result.backImagePath!, result.yoloResults ?? [])),
                ],
              ],
            ),
            const SizedBox(height: 24),
            
            // --- VERDICT CARD ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isAuthentic ? AppColors.successGreenLight : AppColors.errorRedLight,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Icon(isAuthentic ? Icons.verified : Icons.warning, size: 64, color: isAuthentic ? AppColors.successGreen : AppColors.errorRed),
                  const SizedBox(height: 12),
                  Text(result.resultStatus, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: isAuthentic ? AppColors.successGreen : AppColors.errorRed)),
                  Text(result.currencyType, style: const TextStyle(fontSize: 18, color: AppColors.textGray)),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // --- OPTICAL METRICS (IF ANY) ---
            if (result.threadMetrics != null && result.threadMetrics!['metrics'] != null) ...[
              const Text("Optical Shift Evidence", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _buildOpticalMetrics(result.threadMetrics!['metrics']),
              const SizedBox(height: 24),
            ],

            // --- INFO LIST ---
            _buildInfoRow(Icons.calendar_today, "Scanned On", result.formattedDate),
            const Divider(),
            _buildInfoRow(Icons.analytics, "Total Score", "${(result.confidenceLevel * 100).toStringAsFixed(1)}%"),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildImageWithBoxes(String label, String path, List<Map<String, dynamic>> results) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Container(
          height: 150,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[300]!)),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              fit: StackFit.expand,
              children: [
                File(path).existsSync() 
                  ? Image.file(File(path), fit: BoxFit.contain)
                  : const Center(child: Icon(Icons.image_not_supported)),
                if (File(path).existsSync())
                  FutureBuilder<ui.Image>(
                    future: _loadImage(path),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const SizedBox();
                      return CustomPaint(painter: BBoxPainter(results, snapshot.data!));
                    },
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<ui.Image> _loadImage(String path) async {
    final bytes = await File(path).readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  Widget _buildOpticalMetrics(Map<String, dynamic> m) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[200]!)),
      child: Column(
        children: [
          _buildMetricRow("Saturation Shift", "${m['saturation_shift']}%"),
          _buildMetricRow("Value Shift", "${m['value_shift']}%"),
          _buildMetricRow("Hue Range", "${m['hue_range']}°"),
        ],
      ),
    );
  }

  Widget _buildMetricRow(String l, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(l, style: const TextStyle(color: Colors.grey)), Text(v, style: const TextStyle(fontWeight: FontWeight.bold))],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primaryBlue),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(fontSize: 16, color: AppColors.textGray)),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
