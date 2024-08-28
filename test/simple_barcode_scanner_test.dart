import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_barcode_scanner/simple_barcode_scanner.dart';

void main() {
  test('adds one to input values', () {
    SimpleBarcodeScannerPage(
        widthCamera: 500,
        heightCamera: 500,
        onScanned: (barcode) {
          debugPrint('SIMPLE SCANNER (test) : Scanned barcode : $barcode');
        });
  });
}
