import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';
import 'package:simple_barcode_scanner/constant.dart';
import 'package:simple_barcode_scanner/enum.dart';
import 'package:webview_flutter/webview_flutter.dart';

class IosBarcodeScanner extends StatelessWidget {
  final String lineColor;
  final String cancelButtonText;
  final bool isShowFlashIcon;
  final ScanType scanType;
  final Function(String) onScanned;
  final String? appBarTitle;
  final bool? centerTitle;

  const IosBarcodeScanner({
    Key? key,
    required this.lineColor,
    required this.cancelButtonText,
    required this.isShowFlashIcon,
    required this.scanType,
    required this.onScanned,
    this.appBarTitle,
    this.centerTitle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    WebViewController controller = WebViewController();
    bool isPermissionGranted = false;

    _checkCameraPermission().then((granted) {
      debugPrint("Permission is $granted");
      isPermissionGranted = granted;
    });

    return Scaffold(
      body: FutureBuilder<bool>(
          future: initPlatformState(
            controller: controller,
          ),
          builder: (context, snapshot) {
            if (snapshot.hasData && snapshot.data != null) {
              return WebViewWidget(
                controller: controller,
              );
            } else if (snapshot.hasError) {
              return Center(
                child: Text(
                  snapshot.error.toString(),
                  style: const TextStyle(color: Colors.red),
                ),
              );
            }
            return const Center(
              child: CircularProgressIndicator(),
            );
          }),
    );
  }

  /// Checks if camera permission has already been granted
  Future<bool> _checkCameraPermission() async {
    return await Permission.camera.status.isGranted;
  }

  Uri getAssetFileUrl({required String asset}) {
    final assetsDirectory = p.join(p.dirname(Platform.resolvedExecutable),
        'data', 'flutter_assets', asset);
    return Uri.file(assetsDirectory);
  }

  Future<bool> initPlatformState(
      {required WebViewController controller}) async {
    String? barcodeNumber;

    try {
      await controller.loadRequest(getAssetFileUrl(asset: 'packages/simple_barcode_scanner/assets/barcode.html'));

      // OLD CODE (With library webview_windows)
      /* /// Listen to web to receive barcode
      controller.webMessage.listen((event) {
        if (event['methodName'] == "successCallback") {
          if (event['data'] is String &&
              event['data'].isNotEmpty &&
              barcodeNumber == null) {
            barcodeNumber = event['data'];
            onScanned(barcodeNumber!);
          }
        }
      }); */
    } catch (e) {
      rethrow;
    }
    return true;
  }
}
