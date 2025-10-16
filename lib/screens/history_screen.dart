import 'package:flutter/material.dart';
import '../utils/constants.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.scanHistory),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHistoryItem(
            currency: 'INR \100',
            date: 'Today, 10:22 AM',
            status: AppStrings.authentic,
            isAuthentic: true,
          ),
          const SizedBox(height: 12),
          _buildHistoryItem(
            currency: 'INR ₹200',
            date: 'Yesterday, 6:40 PM',
            status: AppStrings.suspicious,
            isAuthentic: false,
          ),
          const SizedBox(height: 12),
          _buildHistoryItem(
            currency: 'INR ₹500',
            date: 'Yesterday, 2:15 PM',
            status: AppStrings.authentic,
            isAuthentic: true,
          ),
          const SizedBox(height: 12),
          _buildHistoryItem(
            currency: 'INR ₹2000',
            date: 'Oct 12, 11:30 AM',
            status: AppStrings.authentic,
            isAuthentic: true,
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem({
    required String currency,
    required String date,
    required String status,
    required bool isAuthentic,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isAuthentic
                  ? AppColors.successGreenLight
                  : AppColors.errorRedLight,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isAuthentic ? Icons.check_circle : Icons.warning_amber,
              color: isAuthentic ? AppColors.successGreen : AppColors.errorRed,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  currency,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Text(
                  date,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isAuthentic
                  ? AppColors.successGreenLight
                  : AppColors.errorRedLight,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              status,
              style: TextStyle(
                color:
                    isAuthentic ? AppColors.successGreen : AppColors.errorRed,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
