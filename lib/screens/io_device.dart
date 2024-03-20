import 'dart:io';

import 'package:flutter/material.dart';
import 'package:simple_barcode_scanner/enum.dart';
import 'package:simple_barcode_scanner/screens/ios.dart';
import 'package:simple_barcode_scanner/screens/window.dart';

/// Barcode scanner for mobile and desktop devices
class BarcodeScanner extends StatelessWidget {
  final String lineColor;
  final String cancelButtonText;
  final bool isShowFlashIcon;
  final ScanType scanType;
  final Function(String) onScanned;
  final String? appBarTitle;
  final bool? centerTitle;
  final double widthCamera;
  final double heightCamera;
  const BarcodeScanner({
    Key? key,
    required this.lineColor,
    required this.cancelButtonText,
    required this.isShowFlashIcon,
    required this.scanType,
    required this.onScanned,
    required this.heightCamera,
    required this.widthCamera,
    this.appBarTitle,
    this.centerTitle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (Platform.isWindows) {
      ///Get Window barcode Scanner UI
      return SizedBox(
        height: 370, // Necessary for the scanner to work on windowsX
        width: 600, // Necessary for the scanner to work on windows
        child: WindowBarcodeScanner(
          // TODO : Handle width and height
          lineColor: lineColor,
          cancelButtonText: cancelButtonText,
          isShowFlashIcon: isShowFlashIcon,
          scanType: scanType,
          onScanned: onScanned,
          appBarTitle: appBarTitle,
          centerTitle: centerTitle,
        ),
      );
    } else if (Platform.isIOS) {
      return IosBarcodeScanner(
        widthCamera: widthCamera,
        heightCamera: heightCamera,
        //onScanned: onScanned,
      );
    } else {
      return const Text('Scan is not supported on this platform.');
    }
  }
}
