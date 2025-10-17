import 'package:flutter/material.dart';

class WelcomePage extends StatelessWidget {
  final VoidCallback onContinue;

  const WelcomePage({Key? key, required this.onContinue}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const deepScanBlue = Color(0xFF001A78);

    return Scaffold(
      backgroundColor: deepScanBlue,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/logo.jpg',
                    height: 400,
                    fit: BoxFit.contain,
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: ElevatedButton(
                onPressed: () {
                  debugPrint('Continue pressed, navigating to HomeScreen');
                  onContinue();
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  backgroundColor: Colors.white,
                  foregroundColor: deepScanBlue,
                ),
                child: const Text(
                  'Continue',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
