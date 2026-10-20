import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:simple_barcode_scanner/constant.dart';
import 'package:simple_barcode_scanner/enum.dart';
import 'package:webview_windows/webview_windows.dart';

class WindowBarcodeScanner extends StatefulWidget {
  final String lineColor;
  final String cancelButtonText;
  final bool isShowFlashIcon;
  final ScanType scanType;
  final Function(String) onScanned;
  final String? appBarTitle;
  final bool? centerTitle;

  /// Stops the scan and releases the webcam, which Windows lets only one
  /// client hold: a camera screen opened on top could not get it otherwise.
  final bool paused;

  const WindowBarcodeScanner({
    Key? key,
    required this.lineColor,
    required this.cancelButtonText,
    required this.isShowFlashIcon,
    required this.scanType,
    required this.onScanned,
    this.appBarTitle,
    this.centerTitle,
    this.paused = false,
  }) : super(key: key);

  @override
  State<WindowBarcodeScanner> createState() => _WindowBarcodeScannerState();
}

class _WindowBarcodeScannerState extends State<WindowBarcodeScanner> {
  final controller = WebviewController();

  /// Created once: built in [build], every rebuild would initialize the
  /// webview again and restart the camera.
  late final Future<bool> _ready = initPlatformState(controller: controller);

  /// Pause and resume, one after the other: a resume sent while the pause is
  /// still navigating must not be overtaken by it.
  Future<void> _transition = Future.value();

  @override
  void didUpdateWidget(covariant WindowBarcodeScanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.paused == oldWidget.paused) {
      return;
    }
    final paused = widget.paused;
    debugPrint('SIMPLE SCANNER : ${paused ? 'pause' : 'resume'}');
    // The page is left rather than its scanner stopped: unloading it is what
    // surely releases the webcam, and a fresh load starts the scan from a
    // clean state instead of restarting one that already ran.
    _transition = _transition
        .then((_) => _ready)
        .then((_) => controller.loadUrl(
              paused ? 'about:blank' : _scannerUrl,
            ))
        .catchError((Object e) => debugPrint('SIMPLE SCANNER : $e'));
  }

  String get _scannerUrl =>
      getAssetFileUrl(asset: PackageConstant.barcodeFilePath);

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
            future: _ready,
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data != null) {
                return Webview(
                  controller,
                  permissionRequested: (url, permissionKind, isUserInitiated) =>
                      _onPermissionRequested(
                    url: url,
                    kind: permissionKind,
                    isUserInitiated: isUserInitiated,
                    context: context,
                    isPermissionGranted: true,
                  ),
                );
              } else if (snapshot.hasError) {
                return Center(
                  child: Text(snapshot.error.toString()),
                );
              }
              return const Center(
                child: CircularProgressIndicator(),
              );
            },
          );
  }

  Future<WebviewPermissionDecision> _onPermissionRequested(
      {required String url,
      required WebviewPermissionKind kind,
      required bool isUserInitiated,
      required BuildContext context,
      required bool isPermissionGranted}) async {
    final WebviewPermissionDecision? decision;
    if (!isPermissionGranted) {
      decision = await showDialog<WebviewPermissionDecision>(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: const Text('Permission requested'),
          content:
              Text('\'${kind.name}\' permission is require to scan qr/barcode'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.pop(context, WebviewPermissionDecision.deny);
                isPermissionGranted = false;
              },
              child: const Text('Deny'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context, WebviewPermissionDecision.allow);
                isPermissionGranted = true;
              },
              child: const Text('Allow'),
            ),
          ],
        ),
      );
    } else {
      decision = WebviewPermissionDecision.allow;
    }

    return decision ?? WebviewPermissionDecision.none;
  }

  String getAssetFileUrl({required String asset}) {
    final assetsDirectory = p.join(p.dirname(Platform.resolvedExecutable),
        'data', 'flutter_assets', asset);
    return Uri.file(assetsDirectory).toString();
  }

  Future<bool> initPlatformState(
      {required WebviewController controller}) async {
    String? barcodeNumber;

    try {
      await controller.initialize();
      await controller.loadUrl(_scannerUrl);

      /// Listen to web to receive barcode
      controller.webMessage.listen((event) {
        if (event['methodName'] == "log") {
          debugPrint('SIMPLE SCANNER : ${event['data']}');
        } else if (event['methodName'] == "successCallback") {
          if (event['data'] is String && event['data'].isNotEmpty) {
            barcodeNumber = event['data'];
            widget.onScanned(barcodeNumber!);
          }
        }
      });
    } catch (e) {
      rethrow;
    }
    return true;
  }
}
