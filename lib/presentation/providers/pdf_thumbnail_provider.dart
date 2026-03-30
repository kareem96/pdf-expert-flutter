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
    final bytes = await file.readAsBytes();
    
    // Use low DPI 30 for list view thumbnails to save memory and CPU
    Uint8List? pngBytes;
    await for (final page in Printing.raster(bytes, pages: [0], dpi: 30)) {
      pngBytes = await page.toPng();
      break; 
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
