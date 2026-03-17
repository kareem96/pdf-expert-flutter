import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

final pdfThumbnailProvider = FutureProvider.family<Uint8List?, String>((ref, path) async {
  try {
    final file = File(path);
    if (!await file.exists()) return null;
    
    final bytes = await file.readAsBytes();
    // Use low DPI 30 for list view thumbnails to save memory and CPU
    await for (final page in Printing.raster(bytes, pages: [0], dpi: 30)) {
      return await page.toPng();
    }
  } catch (e) {
    print('Error generating thumbnail for $path: $e');
  }
  return null;
});
