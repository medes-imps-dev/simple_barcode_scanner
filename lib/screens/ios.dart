import 'dart:async';

import 'package:flutter/material.dart';
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
  final Function(String) onScanned;

  @override
  State<IosBarcodeScanner> createState() => _IosBarcodeScannerState();
}

class _IosBarcodeScannerState extends State<IosBarcodeScanner> {
  final MobileScannerController controller = MobileScannerController();

  @override
  void initState() {
    super.initState();

    // Start listening to the barcode events.
    controller.barcodes.listen(_handleBarcode);

    // Finally, start the scanner itself.
    unawaited(controller.start());
  }

  void _handleBarcode(BarcodeCapture event) {
    final barcode = event.barcodes.firstOrNull?.rawValue;
    if (barcode == null) return;
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
    final double heightCamera = widget.widthCamera;
    final double widthCamera = widget.heightCamera;

    final scanWindow = Rect.fromCenter(
      center: Offset(widthCamera / 2, heightCamera / 2),
      // Size of the clear area where we can scan
      width: widthCamera * 0.8,
      height: heightCamera * 0.8,
    );

    return Scaffold(
      body: SizedBox(
        height: heightCamera,
        width: widthCamera,
        child: Stack(
          fit: StackFit.expand,
          children: [
            RotatedBox(
              quarterTurns: 3,
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
            ),
            //_buildBarcodeOverlay(),
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
    // TODO: use `Offset.zero & size` instead of Rect.largest
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
