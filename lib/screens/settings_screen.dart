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
    // Same implementation as before
  }

  void _showHelpDialog(BuildContext context, AppLocalizations localizations) {
    // Same implementation as before
  }

  void _showAboutDialog(BuildContext context, AppLocalizations localizations) {
    // Same implementation as before
  }
}
