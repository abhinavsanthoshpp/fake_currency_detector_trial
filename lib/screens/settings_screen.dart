import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../utils/constants.dart';
import '../providers/locale_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final List<Map<String, String>> languages = [
    {'code': 'en', 'name': 'English', 'flag': '🇺🇸'},
    {'code': 'hi', 'name': 'हिन्दी (Hindi)', 'flag': '🇮🇳'},
    {'code': 'te', 'name': 'తెలుగు (Telugu)', 'flag': '🇮🇳'},
    {'code': 'ml', 'name': 'മലയാളം (Malayalam)', 'flag': '🇮🇳'},
  ];

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.settings),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: AppColors.backgroundColor,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Language Selection Section
          _buildSectionHeader(localizations.language),
          _buildLanguageDropdown(localizations),

          const SizedBox(height: 24),

          // App Info Section
          _buildSectionHeader('App Information'),
          _buildSettingsItem(
            icon: Icons.support_agent,
            title: localizations.support,
            subtitle: 'Get help and assistance',
            onTap: () => _showSupportDialog(context, localizations),
          ),
          _buildSettingsItem(
            icon: Icons.help_outline,
            title: localizations.help,
            subtitle: 'Learn how to use the app',
            onTap: () => _showHelpDialog(context, localizations),
          ),
          _buildSettingsItem(
            icon: Icons.info_outline,
            title: localizations.about,
            subtitle: 'App version and information',
            onTap: () => _showAboutDialog(context, localizations),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textDark,
        ),
      ),
    );
  }

  Widget _buildLanguageDropdown(AppLocalizations localizations) {
    return Consumer<LocaleProvider>(
      builder: (context, localeProvider, _) {
        final currentLanguage = languages.firstWhere(
          (lang) => lang['code'] == localeProvider.locale.languageCode,
          orElse: () => languages.first,
        );

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
              const Icon(Icons.language, color: AppColors.primaryBlue),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      localizations.language,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: currentLanguage['code'],
                        isExpanded: true,
                        items: languages.map((language) {
                          return DropdownMenuItem<String>(
                            value: language['code'],
                            child: Row(
                              children: [
                                Text(language['flag']!),
                                const SizedBox(width: 8),
                                Text(
                                  language['name']!,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: AppColors.textGray,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            localeProvider.setLocale(Locale(newValue));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Language changed'),
                                backgroundColor: AppColors.primaryBlue,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: ListTile(
        leading: Icon(icon, color: AppColors.primaryBlue),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppColors.textDark,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textGray,
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: AppColors.textGray,
        ),
        onTap: onTap,
      ),
    );
  }

  // Keep your existing dialog methods but add localizations parameter
  void _showSupportDialog(
      BuildContext context, AppLocalizations localizations) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.support_agent, color: AppColors.primaryBlue),
            const SizedBox(width: 8),
            Text(localizations.support),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Need help with DeepScan?',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 12),
            Text('📧 Email: abhinavsanthoshpp@gmail.com'),
            SizedBox(height: 8),
            Text('📞 Phone: +91 7907646525'),
            SizedBox(height: 8),
            Text('🕒 Support Hours: 9 AM - 6 PM (IST)'),
            SizedBox(height: 12),
            Text(
              'Our team usually responds within 24 hours using email or phone support.',
              style: TextStyle(color: AppColors.textGray, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog(BuildContext context, AppLocalizations localizations) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.help_outline, color: AppColors.primaryBlue),
            const SizedBox(width: 8),
            Text(localizations.help),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'How to use DeepScan:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 12),
            Text('1. Tap "Scan" to open the camera.'),
            SizedBox(height: 6),
            Text('2. Align the currency note inside the frame.'),
            SizedBox(height: 6),
            Text('3. Based on instruction capture the input'),
            SizedBox(height: 6),
            Text('4. Review results and save scans.'),
            SizedBox(height: 12),
            Text(
              'Tips for better results:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8),
            Text('• Ensure good lighting conditions.'),
            SizedBox(height: 4),
            Text('• Keep the currency note flat and steady.'),
            SizedBox(height: 4),
            Text('• Avoid glare and reflections when scanning.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context, AppLocalizations localizations) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.info_outline, color: AppColors.primaryBlue),
            const SizedBox(width: 8),
            Text(localizations.about),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'DeepScan',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryBlue,
              ),
            ),
            SizedBox(height: 8),
            Text('Version: 1.0.0'),
            SizedBox(height: 8),
            Text('Build: 2025.10.17'),
            SizedBox(height: 16),
            Text(
              'DeepScan is a secure and advanced currency authenticity scanning app powered by AI.',
              style: TextStyle(color: AppColors.textGray),
            ),
            SizedBox(height: 16),
            Text(
              'Developed by:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 4),
            Text('• Abhinav Santhosh'),
            Text('• Abhiram K'),
            SizedBox(height: 16),
            Text(
              '© 2025 DeepScan. All rights reserved.',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textGray,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
