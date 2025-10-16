import 'package:flutter_test/flutter_test.dart';
import 'package:camera/camera.dart';
import 'package:currency_scanner/main.dart';

void main() {
  testWidgets('App starts correctly', (WidgetTester tester) async {
    // Create a mock camera description
    const camera = CameraDescription(
      name: 'test',
      lensDirection: CameraLensDirection.back,
      sensorOrientation: 0,
    );
    
    await tester.pumpWidget(const VeriScanProApp(camera: camera));
    expect(find.text('Fake Currency Detector'), findsOneWidget);
  });
}