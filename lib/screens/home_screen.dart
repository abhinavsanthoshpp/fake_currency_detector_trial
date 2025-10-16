import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../utils/constants.dart';
import '../widgets/home_content.dart';
import 'scanner_screen.dart';
import 'history_screen.dart';
import 'results_screen.dart';
import 'settings_screen.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../database/database_service.dart';

class HomeScreen extends StatefulWidget {
  final CameraDescription camera;

  const HomeScreen({super.key, required this.camera});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tabIndex = 0; // bottom nav index (0..2)
  bool _showResult = false; // overlay result view flag
  String _lastImagePath = ''; // captured image path

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: _tabIndex == 0 && !_showResult ? _buildAppBar() : null,
      body: _buildBody(),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildBody() {
    // If a result is available show results view (keeps bottom nav visible)
    if (_showResult) {
      return ResultsScreen(
        imagePath: _lastImagePath,
        onBack: () {
          // return to scanner tab and hide result
          setState(() {
            _showResult = false;
            _tabIndex = 1;
          });
        },
      );
    }

    // otherwise show normal tab content
    switch (_tabIndex) {
      case 0:
        final recentScansList = DatabaseService.getAllScanResults();
        return HomeContent(
          onScanPressed: () {
            setState(() {
              _tabIndex = 1;
            });
          },
          recentScans: recentScansList, // Pass recent scans here
        );
      case 1:
        return ScannerScreen(
          camera: widget.camera,
          onBack: () {
            setState(() {
              _tabIndex = 0;
              _showResult = false;
            });
          },
          onCaptured: (path) {
            setState(() {
              _lastImagePath = path;
              _showResult = true;
            });
          },
        );
      case 2:
        return const HistoryScreen();
      default:
        final recentScansList = DatabaseService.getAllScanResults();
        return HomeContent(
          onScanPressed: () {
            setState(() {
              _tabIndex = 1;
            });
          },
          recentScans: recentScansList, // Pass recent scans here
        );
    }
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: Text(AppLocalizations.of(context)!.homeTitle),
      centerTitle: false,
      actions: [
        IconButton(
          icon: const Icon(
              Icons.settings), // changed from notifications_none to settings
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SettingsScreen(),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _tabIndex,
        onTap: (index) {
          setState(() {
            _tabIndex = index;
            _showResult = false; // hide result if user switches tabs
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: AppColors.primaryBlue,
        unselectedItemColor: AppColors.textGray,
        selectedLabelStyle:
            const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        unselectedLabelStyle:
            const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home_outlined),
            activeIcon: const Icon(Icons.home),
            label: AppLocalizations.of(context)!.home,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.document_scanner_outlined),
            activeIcon: const Icon(Icons.document_scanner),
            label: AppLocalizations.of(context)!.scan,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.history_outlined),
            activeIcon: const Icon(Icons.history),
            label: AppLocalizations.of(context)!.history,
          ),
        ],
      ),
    );
  }
}
