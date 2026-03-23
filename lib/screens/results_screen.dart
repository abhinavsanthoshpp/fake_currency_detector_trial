import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import '../l10n/app_localizations.dart';
import '../utils/constants.dart';
import '../database/database_service.dart';
import '../database/scan_result.dart';

class ResultsScreen extends StatefulWidget {
  final String? imagePath; // Front image
  final String? backImagePath; 
  final List<Map<String, dynamic>> yoloResults; // All combined results
  final List<Map<String, dynamic>>? frontResults;
  final List<Map<String, dynamic>>? backResults;
  final VoidCallback? onBack;
  final bool isIntermediateResult;
  final Map<String, dynamic>? threadVerificationResult;

  const ResultsScreen({
    Key? key,
    this.imagePath,
    this.backImagePath,
    required this.yoloResults,
    this.frontResults,
    this.backResults,
    this.onBack,
    this.isIntermediateResult = false,
    this.threadVerificationResult,
  }) : super(key: key);

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  Map<String, double> securityFeatures = {};
  double overallScore = 0.0;
  String currencyType = "Unknown Currency";
  String resultStatus = "Undetermined";

  @override
  void initState() {
    super.initState();
    _processResults();
  }

  void _processResults() {
    if (widget.yoloResults.isEmpty) return;

    Map<String, double> features = {};
    for (var result in widget.yoloResults) {
      String tag = result['tag'];
      bool isGenuine = result['isGenuine'] ?? false;
      features[tag] = isGenuine ? 1.0 : 0.0;
    }

    double imageFeaturesScore = 0;
    if (features.isNotEmpty) {
      double sum = 0;
      features.forEach((key, value) => sum += value);
      imageFeaturesScore = sum / features.length;
    }

    double finalScore = 0;
    if (widget.threadVerificationResult != null) {
      double threadScore = widget.threadVerificationResult!['score'] ?? 0.0;
      // HIGH PRIORITY WEIGHTING: 40% Image Features + 60% Video Thread Verification
      finalScore = (imageFeaturesScore * 0.4) + (threadScore * 0.6);
      features['security_thread_dynamic'] = threadScore;
    } else {
      finalScore = imageFeaturesScore;
    }

    setState(() {
      securityFeatures = features;
      overallScore = finalScore;
      final uniqueTags = widget.yoloResults.map((r) => r['tag'].split('_').first).toSet();
      currencyType = uniqueTags.join(', ');
      
      if (widget.isIntermediateResult) {
        resultStatus = "Step 1 Complete (Waiting for Thread)";
      } else {
        resultStatus = overallScore > 0.7 ? "Authentic" : "Suspicious";
      }
    });

    if (!widget.isIntermediateResult) {
      DatabaseService.addScanResult(
        ScanResult(
          currencyType: currencyType,
          resultStatus: resultStatus,
          confidenceLevel: overallScore,
          dateTime: DateTime.now(),
          imagePath: widget.imagePath,
          backImagePath: widget.backImagePath,
          yoloResults: widget.yoloResults,
          threadMetrics: widget.threadVerificationResult,
        ),
      ).then((_) {
        print("💾 Saved scan result to offline database ✅");
      }).catchError((e) {
        print("❌ Error saving to database: $e");
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final isAuthentic = overallScore > 0.7;

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: Text(localizations.scanResults),
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text("Visual Evidence", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                if (widget.imagePath != null)
                  Expanded(child: _buildResultImageWithBoxes("Front Side", widget.imagePath!, widget.frontResults ?? [])),
                if (widget.backImagePath != null) ...[
                  const SizedBox(width: 8),
                  Expanded(child: _buildResultImageWithBoxes("Back Side", widget.backImagePath!, widget.backResults ?? [])),
                ],
              ],
            ),
            
            const SizedBox(height: 24),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isAuthentic ? AppColors.successGreenLight : AppColors.errorRedLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Icon(isAuthentic ? Icons.verified : Icons.warning, size: 48, color: isAuthentic ? AppColors.successGreen : AppColors.errorRed),
                  const SizedBox(height: 8),
                  Text(resultStatus, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isAuthentic ? AppColors.successGreen : AppColors.errorRed)),
                  Text(currencyType, style: const TextStyle(fontSize: 18, color: AppColors.textGray)),
                ],
              ),
            ),

            const SizedBox(height: 24),
            _buildScoreCard(),
            const SizedBox(height: 24),
            _buildFeaturesCard(),
            const SizedBox(height: 24),

            if (widget.threadVerificationResult != null && widget.threadVerificationResult!['metrics'] != null)
              _buildOpticalEvidenceCard(widget.threadVerificationResult!['metrics']),

            const SizedBox(height: 24),
            _buildActionButton(localizations),
          ],
        ),
      ),
    );
  }

  Widget _buildOpticalEvidenceCard(Map<String, dynamic> metrics) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), spreadRadius: 1, blurRadius: 4)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [Icon(Icons.remove_red_eye, color: AppColors.primaryBlue), SizedBox(width: 12), Text('Optical Evidence (Thread)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))],
          ),
          const SizedBox(height: 16),
          _buildMetricRow("Saturation Shift", "${metrics['saturation_shift']}%"),
          const Divider(),
          _buildMetricRow("Value/Bright Shift", "${metrics['value_shift']}%"),
          const Divider(),
          _buildMetricRow("Chromatic (Hue) Range", "${metrics['hue_range']}°"),
        ],
      ),
    );
  }

  Widget _buildMetricRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(label, style: const TextStyle(fontSize: 14, color: AppColors.textGray)), Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primaryBlue))],
      ),
    );
  }

  Widget _buildResultImageWithBoxes(String label, String path, List<Map<String, dynamic>> results) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Container(
          height: 150,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey[300]!)),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.file(File(path), fit: BoxFit.contain),
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

  Widget _buildScoreCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), spreadRadius: 1, blurRadius: 4)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [Icon(Icons.analytics, color: AppColors.primaryBlue), SizedBox(width: 12), Text('Analysis Score', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: Text('${(overallScore * 100).toStringAsFixed(1)}%', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: overallScore > 0.7 ? AppColors.successGreen : AppColors.errorRed))),
              CircularProgressIndicator(value: overallScore, strokeWidth: 8, backgroundColor: Colors.grey[300], valueColor: AlwaysStoppedAnimation<Color>(overallScore > 0.7 ? AppColors.successGreen : AppColors.errorRed)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), spreadRadius: 1, blurRadius: 4)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [Icon(Icons.security, color: AppColors.primaryBlue), SizedBox(width: 12), Text('Detected Features', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))],
          ),
          const SizedBox(height: 20),
          ...securityFeatures.entries.map((e) => _buildFeatureItem(e.key, e.value)).toList(),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(String name, double score) {
    final isGood = score > 0.7;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(isGood ? Icons.check_circle : Icons.cancel, color: isGood ? Colors.green : Colors.red, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(name, style: const TextStyle(fontSize: 14))),
          Text('${(score * 100).toInt()}%', style: TextStyle(fontWeight: FontWeight.bold, color: isGood ? Colors.green : AppColors.textGray)),
        ],
      ),
    );
  }

  Widget _buildActionButton(AppLocalizations localizations) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          if (widget.isIntermediateResult) {
            Navigator.of(context).pop(true);
          } else {
            Navigator.of(context).popUntil((route) => route.isFirst);
          }
        },
        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue, padding: const EdgeInsets.all(16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        child: Text(widget.isIntermediateResult ? 'Proceed to Thread Verification' : localizations.scanAnotherCurrency, style: const TextStyle(fontSize: 16, color: Colors.white)),
      ),
    );
  }
}

class BBoxPainter extends CustomPainter {
  final List<Map<String, dynamic>> results;
  final ui.Image image;

  BBoxPainter(this.results, this.image);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.stroke..strokeWidth = 2.0;
    final double scaleX = size.width / image.width;
    final double scaleY = size.height / image.height;

    for (var res in results) {
      final box = res['box'];
      final isGenuine = res['isGenuine'] ?? false;
      paint.color = isGenuine ? Colors.green : Colors.red;
      canvas.drawRect(Rect.fromLTRB(box[0] * scaleX, box[1] * scaleY, box[2] * scaleX, box[3] * scaleY), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
