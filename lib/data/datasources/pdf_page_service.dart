import 'dart:io';
import 'dart:ui';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:printing/printing.dart';
import '../../domain/entities/page_action.dart';

class PdfPageService {
  /// Generates thumbnails for all pages using high-speed rasterization with disk caching
  Future<List<Uint8List>> generateThumbnails(String path, {double dpi = 72.0}) async {
    final File file = File(path);
    if (!await file.exists()) return [];

    final stat = await file.stat();
    final cacheDir = await getTemporaryDirectory();
    final thumbDir = Directory('${cacheDir.path}/thumbnails/pages/${path.hashCode}');
    if (!await thumbDir.exists()) {
      await thumbDir.create(recursive: true);
    }

    final int pageCount = await _getPageCount(file);
    final List<Uint8List> thumbnails = [];

    // Optimization: Read file into memory only once
    Uint8List? bytes = await file.readAsBytes();
    
    for (int i = 0; i < pageCount; i++) {
      final cacheKey = '${i}_${dpi}_${stat.modified.millisecondsSinceEpoch}.png';
      final cacheFile = File('${thumbDir.path}/$cacheKey');

      if (await cacheFile.exists()) {
        thumbnails.add(await cacheFile.readAsBytes());
        continue;
      }

      // If not in cache, generate only for that specific page to save memory
      await for (final page in Printing.raster(bytes, pages: [i], dpi: dpi)) {
        final Uint8List pngBytes = await page.toPng();
        thumbnails.add(pngBytes);
        // Save to cache asynchronously 
        cacheFile.writeAsBytes(pngBytes).catchError((_) => cacheFile);
        break;
      }
    }

    // Explicitly clear bytes
    bytes = null;
    
    return thumbnails;
  }

  Future<int> _getPageCount(File file) async {
    try {
      final Uint8List bytes = await file.readAsBytes();
      final PdfDocument doc = PdfDocument(inputBytes: bytes);
      final int count = doc.pages.count;
      doc.dispose();
      return count;
    } catch (_) {
      return 0;
    }
  }

  /// Reorders, rotates, or deletes pages and saves to a new file
  Future<File> processPageChanges({
    required String sourcePath,
    required List<PageAction> actions,
    required String targetPath,
  }) async {
    final Uint8List bytes = await File(sourcePath).readAsBytes();
    final PdfDocument sourceDocument = PdfDocument(inputBytes: bytes);
    final PdfDocument targetDocument = PdfDocument();

    try {
      // 1. Initialize page sequence and rotations
      List<int> pageIndices = List.generate(sourceDocument.pages.count, (i) => i);
      // 2. Process actions to determine final sequence
      for (final action in actions) {
        switch (action.type) {
          case PageActionType.reorder:
            final int from = action.pageIndex;
            final int to = action.value as int;
            if (from < pageIndices.length && to < pageIndices.length) {
              final int originalIdx = pageIndices.removeAt(from);
              pageIndices.insert(to, originalIdx);
            }
            break;
            
          case PageActionType.delete:
            final int index = action.pageIndex; 
            if (index < pageIndices.length && pageIndices.length > 1) {
              pageIndices.removeAt(index);
            }
            break;
        }
      }

      // 3. Build target document by importing pages in the new order
      for (int i = 0; i < pageIndices.length; i++) {
        final int originalIdx = pageIndices[i];
        final PdfPage sourcePage = sourceDocument.pages[originalIdx];

        final Size originalSize = sourcePage.size;
        final PdfTemplate template = sourcePage.createTemplate();

        final PdfSection section = targetDocument.sections!.add();
        section.pageSettings.margins.all = 0;
        section.pageSettings.size = originalSize;

        final PdfPage destinationPage = section.pages.add();
        destinationPage.graphics.drawPdfTemplate(template, Offset.zero, originalSize);
      }

      final List<int> bytes = await targetDocument.save();
      targetDocument.dispose();
      sourceDocument.dispose();

      final File file = File(targetPath);
      await file.writeAsBytes(bytes);
      return file;
    } catch (e, _) {
      targetDocument.dispose();
      sourceDocument.dispose();
      rethrow;
    }
  }
}
