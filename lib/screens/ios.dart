import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

const marginScanWindow = 200.0;

class IosBarcodeScanner extends StatefulWidget {
  const IosBarcodeScanner({
    super.key,
    required this.widthCamera,
    required this.heightCamera,
    required this.onScanned,
  });

  final double widthCamera;
  final double heightCamera;
  final void Function(String) onScanned;

  @override
  State<IosBarcodeScanner> createState() => _IosBarcodeScannerState();
}

class _IosBarcodeScannerState extends State<IosBarcodeScanner>
    with WidgetsBindingObserver {
  final MobileScannerController controller = MobileScannerController();

  late final StreamSubscription<Object?>? _subscription;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    initializeController();
  }

  void initializeController() {
    _subscription = controller.barcodes.listen(_handleBarcode);
    controller.start();
    controller.start();
  }

  void _handleBarcode(BarcodeCapture event) {
    final barcode = event.barcodes.firstOrNull?.rawValue;
    if (barcode == null) {
      debugPrint('SIMPLE SCANNER : barcode is null');
      return;
    }
    debugPrint('SIMPLE SCANNER : Barcode detected: $barcode');
    widget.onScanned(barcode);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        return;
      case AppLifecycleState.resumed:
        // Restart the scanner when the app is resumed.
        debugPrint('SIMPLE SCANNER : App is resumed');
      //initializeController();

      case AppLifecycleState.inactive:
        debugPrint('SIMPLE SCANNER : App is inactive');
        // Stop the scanner when the app is paused.
        _subscription?.cancel();
        _subscription = null;
        controller.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    const double widthFullScreen = 400;
    const double heightFullScreen = 600;

    final scanWindow = Rect.fromCenter(
      center: const Offset(heightFullScreen / 2, widthFullScreen / 2),
      // Size of the clear area where we can scan
      width: heightFullScreen - marginScanWindow,
      height: widthFullScreen - marginScanWindow,
    );

    return SizedBox(
      height: widthFullScreen,
      width: heightFullScreen,
      child: Stack(
        fit: StackFit.expand,
        children: [
          OrientationBuilder(builder: (context, orientation) {
            final int quarterTurns;
            DeviceOrientation.landscapeLeft;
            if (orientation == Orientation.landscape) {
              quarterTurns = 3;
            } else {
              quarterTurns = 0;
            }
            return RotatedBox(
              quarterTurns: quarterTurns,
              child: MobileScanner(
                scanWindow: scanWindow,
                controller: controller,
                errorBuilder: (context, error, child) {
                  return Text(
                    error.toString(),
                    style: const TextStyle(color: Colors.red),
                  );
                },
              ),
            );
          }),
          _buildScanWindow(scanWindow),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              alignment: Alignment.center,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              height: 50,
              color: Colors.black.withOpacity(0.4),
              child: StreamBuilder<BarcodeCapture>(
                  stream: controller.barcodes,
                  builder: (context, snapshot) {
                    switch (snapshot.connectionState) {
                      case ConnectionState.none:
                      case ConnectionState.waiting:
                        return const Text('No barcode detected');
                      case ConnectionState.active:
                      case ConnectionState.done:
                        return Text(
                            snapshot.data?.barcodes.firstOrNull?.rawValue ??
                                '');
                    }
                  }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanWindow(Rect scanWindowRect) {
    return ValueListenableBuilder(
      valueListenable: controller,
      builder: (context, value, child) {
        // Not ready.
        if (!value.isInitialized ||
            !value.isRunning ||
            value.error != null ||
            value.size.isEmpty) {
          return const SizedBox();
        }

        return CustomPaint(
          painter: ScannerOverlay(scanWindowRect),
        );
      },
    );
  }

  @override
  Future<void> dispose() async {
    await controller.dispose();
    debugPrint('SIMPLE SCANNER : IOS Barcode controller is disposed');
    super.dispose();
  }
}

class ScannerOverlay extends CustomPainter {
  ScannerOverlay(this.scanWindow);

  final Rect scanWindow;

  @override
  void paint(Canvas canvas, Size size) {
    // we need to pass the size to the custom paint widget
    final backgroundPath = Path()
      ..addRect(scanWindow.inflate(marginScanWindow / 2));
    final cutoutPath = Path()..addRect(scanWindow);

    final backgroundPaint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..style = PaintingStyle.fill
      ..blendMode = BlendMode.dstOut;

    final backgroundWithCutout = Path.combine(
      PathOperation.difference,
      backgroundPath,
      cutoutPath,
    );

    canvas.drawPath(backgroundWithCutout, backgroundPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
