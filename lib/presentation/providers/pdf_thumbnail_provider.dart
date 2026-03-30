import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import '../../data/services/draft_service.dart';

final pdfThumbnailProvider = FutureProvider.family<Uint8List?, String>((ref, path) async {
  try {
    String finalPath = path;
    final draftPath = await DraftService().getDraftPdfPath(path);
    if (draftPath != null && await File(draftPath).exists()) {
      finalPath = draftPath;
    }

    final file = File(finalPath);
    if (!await file.exists()) return null;

    // 1. Caching Logic: Check if we have a cached version
    final stat = await file.stat();
    final cacheDir = await getTemporaryDirectory();
    final thumbDir = Directory('${cacheDir.path}/thumbnails');
    if (!await thumbDir.exists()) {
      await thumbDir.create(recursive: true);
    }

    final String cacheKey = '${finalPath.hashCode}_${stat.modified.millisecondsSinceEpoch}';
    final File cacheFile = File('${thumbDir.path}/$cacheKey.png');

    if (await cacheFile.exists()) {
      return await cacheFile.readAsBytes();
    }
    
    // 2. Generation Logic: Only if not in cache
    Uint8List? pdfBytes = await file.readAsBytes();
    
    // Use very low DPI 20 for list view thumbnails to save memory and CPU
    // This is enough for a small preview (approx 150-200px height)
    Uint8List? pngBytes;
    try {
      await for (final page in Printing.raster(pdfBytes, pages: [0], dpi: 20)) {
        pngBytes = await page.toPng();
        break; 
      }
    } finally {
      // Clear bytes immediately to free heavy memory
      pdfBytes = null;
    }

    if (pngBytes != null) {
      // Save to cache asynchronously 
      cacheFile.writeAsBytes(pngBytes).catchError((_) => cacheFile);
    }
    
    return pngBytes;
  } catch (e) {
    // logger: Error generating thumbnail for $path: $e
  }
  return null;
});
