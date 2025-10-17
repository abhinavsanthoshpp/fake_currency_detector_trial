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

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  int _tabIndex = 0; // bottom nav index (0..2)
  bool _showResult = false; // overlay result view flag
  String _lastImagePath = ''; // captured image path

  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    // Animation controller for fade transition of result overlay
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: _tabIndex == 0 && !_showResult ? _buildAppBar() : null,
      body: Stack(
        children: [
          _buildBody(),
          if (_showResult) _buildResultOverlay(),
        ],
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildBody() {
    // Normal tab content when result not showing
    switch (_tabIndex) {
      case 0:
        final recentScansList = DatabaseService.getAllScanResults();
        return HomeContent(
          onScanPressed: () {
            if (!mounted) return;
            setState(() {
              _tabIndex = 1;
            });
          },
          recentScans: recentScansList,
        );
      case 1:
        return ScannerScreen(
          camera: widget.camera,
          onBack: () {
            if (!mounted) return;
            setState(() {
              _tabIndex = 0;
              _showResult = false;
            });
          },
          onCaptured: (path) {
            if (!mounted) return;
            setState(() {
              _lastImagePath = path;
              _showResult = true;
              _fadeController.forward(from: 0);
            });
          },
        );
      case 2:
        return const HistoryScreen();
      default:
        final recentScansList = DatabaseService.getAllScanResults();
        return HomeContent(
          onScanPressed: () {
            if (!mounted) return;
            setState(() {
              _tabIndex = 1;
            });
          },
          recentScans: recentScansList,
        );
    }
  }

  Widget _buildResultOverlay() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ResultsScreen(
        imagePath: _lastImagePath,
        onBack: () {
          if (!mounted) return;
          setState(() {
            _showResult = false;
            _tabIndex = 1;
          });
        },
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: Text(AppLocalizations.of(context)!.homeTitle),
      centerTitle: false,
      actions: [
        IconButton(
          icon: const Icon(Icons.settings),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SettingsScreen()),
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
          if (!mounted) return;
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
