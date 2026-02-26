import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

final pdfThumbnailProvider = FutureProvider.family<Uint8List?, String>((ref, path) async {
  try {
    final file = File(path);
    if (!await file.exists()) return null;
    
    final bytes = await file.readAsBytes();
    // Use dpi 72 for a lightweight thumbnail
    await for (final page in Printing.raster(bytes, pages: [0], dpi: 72)) {
      return await page.toPng();
    }
  } catch (e) {
    print('Error generating thumbnail for $path: $e');
  }
  return null;
});
