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
  const BarcodeScanner({
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
    if (Platform.isWindows) {
      ///Get Window barcode Scanner UI
      return WindowBarcodeScanner(
        lineColor: lineColor,
        cancelButtonText: cancelButtonText,
        isShowFlashIcon: isShowFlashIcon,
        scanType: scanType,
        onScanned: onScanned,
        appBarTitle: appBarTitle,
        centerTitle: centerTitle,
      );
    } else if (Platform.isIOS) {
      return IosBarcodeScanner(lineColor: lineColor, cancelButtonText: cancelButtonText, isShowFlashIcon: isShowFlashIcon, scanType: scanType, onScanned: onScanned);
    } else {
      return const Text('Scan is not supported on iOS');
    }
  }
}
