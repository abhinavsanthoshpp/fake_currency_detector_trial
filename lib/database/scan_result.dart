import 'package:hive/hive.dart';

part 'scan_result.g.dart';

@HiveType(typeId: 0)
class ScanResult extends HiveObject {
  @HiveField(0)
  String currencyType;

  @HiveField(1)
  String resultStatus;

  @HiveField(2)
  double confidenceLevel;

  @HiveField(3)
  DateTime dateTime;

  @HiveField(4)
  String? imagePath;

  @HiveField(5)
  String? backImagePath;

  @HiveField(6)
  List<Map<String, dynamic>>? yoloResults; // Store all features

  @HiveField(7)
  Map<String, dynamic>? threadMetrics; // Store optical metrics

  ScanResult({
    required this.currencyType,
    required this.resultStatus,
    required this.confidenceLevel,
    required this.dateTime,
    this.imagePath,
    this.backImagePath,
    this.yoloResults,
    this.threadMetrics,
  });

  String get formattedDate {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return 'Today, ${_formatTime(dateTime)}';
    } else if (difference.inDays == 1) {
      return 'Yesterday, ${_formatTime(dateTime)}';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}, ${_formatTime(dateTime)}';
    }
  }

  String _formatTime(DateTime time) {
    final hour = time.hour == 0 ? 12 : (time.hour > 12 ? time.hour - 12 : time.hour);
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}
