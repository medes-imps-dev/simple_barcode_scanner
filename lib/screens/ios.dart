import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

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

class _IosBarcodeScannerState extends State<IosBarcodeScanner> {
  final MobileScannerController controller = MobileScannerController();

  @override
  void initState() {
    super.initState();

    controller.start();
    controller.start();

    controller.barcodes.listen(_handleBarcode);
  }

  void _handleBarcode(BarcodeCapture event) {
    final barcode = event.barcodes.firstOrNull?.rawValue;
    if (barcode == null) {
      print('barcode is null');
      return;
    }
    print('Barcode detected: $barcode');
    widget.onScanned(barcode);
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
  Widget build(BuildContext context) {
    const double widthFullScreen = 400;
    const double heightFullScreen = 600;

    final scanWindow = Rect.fromCenter(
      center: const Offset(heightFullScreen / 2, widthFullScreen / 2),
      // Size of the clear area where we can scan
      width: heightFullScreen * 0.8,
      height: widthFullScreen * 0.8,
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
          //_buildBarcodeOverlay(),
          _buildScanWindow(scanWindow),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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

  @override
  Future<void> dispose() async {
    super.dispose();
    await controller.dispose();
  }
}

class ScannerOverlay extends CustomPainter {
  ScannerOverlay(this.scanWindow);

  final Rect scanWindow;

  @override
  void paint(Canvas canvas, Size size) {
    // we need to pass the size to the custom paint widget
    final backgroundPath = Path()..addRect(Rect.largest);
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
