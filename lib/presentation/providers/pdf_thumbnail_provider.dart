import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
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
    
    final bytes = await file.readAsBytes();
    // Use low DPI 30 for list view thumbnails to save memory and CPU
    await for (final page in Printing.raster(bytes, pages: [0], dpi: 30)) {
      return await page.toPng();
    }
  } catch (e) {
    // logger: Error generating thumbnail for $path: $e
  }
  return null;
});
