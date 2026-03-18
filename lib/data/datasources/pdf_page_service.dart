import 'dart:io';
import 'dart:ui';
import 'dart:typed_data';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:printing/printing.dart';
import '../../domain/entities/page_action.dart';

class PdfPageService {
  /// Generates thumbnails for all pages using high-speed rasterization
  Future<List<Uint8List>> generateThumbnails(String path, {double dpi = 72.0}) async {
    final File file = File(path);
    final Uint8List bytes = await file.readAsBytes();
    
    final List<Uint8List> thumbnails = [];
    
    // We use Printing.raster to convert PDF pages directly to images
    await for (final page in Printing.raster(bytes, dpi: dpi)) {
      final Uint8List pngBytes = await page.toPng();
      thumbnails.add(pngBytes);
    }
    
    return thumbnails;
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
      Map<int, int> pageRotations = {}; // originalIndex -> rotation angle

      // 2. Process actions to determine final sequence and properties
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
            
          case PageActionType.rotate:
            final int index = action.pageIndex; // This index refers to the CURRENT position in pageIndices
            final int angleDelta = action.value as int;
            if (index < pageIndices.length) {
              final int originalIdx = pageIndices[index];
              final int currentRot = pageRotations[originalIdx] ?? 0;
              pageRotations[originalIdx] = _normalizeDegrees(currentRot + angleDelta);
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

        final int originalRotation = _mapPdfRotation(sourcePage.rotation);
        final int actionRotation = pageRotations[originalIdx] ?? 0;
        final int totalRotation = _normalizeDegrees(originalRotation + actionRotation);

        final PdfTemplate template = sourcePage.createTemplate();
        final Size originalSize = sourcePage.size;

        final PdfSection section = targetDocument.sections!.add();
        section.pageSettings.margins.all = 0;
        section.pageSettings.size = originalSize;
        section.pageSettings.rotate = _mapRotation(totalRotation);

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

  int _mapPdfRotation(PdfPageRotateAngle angle) {
    switch (angle) {
      case PdfPageRotateAngle.rotateAngle90: return 90;
      case PdfPageRotateAngle.rotateAngle180: return 180;
      case PdfPageRotateAngle.rotateAngle270: return 270;
      case PdfPageRotateAngle.rotateAngle0: return 0;
    }
  }

  int _normalizeDegrees(int degrees) {
    final int normalized = degrees % 360;
    return normalized < 0 ? normalized + 360 : normalized;
  }

  PdfPageRotateAngle _mapRotation(int degrees) {
    final int normalized = _normalizeDegrees(degrees);
    if (normalized == 90) return PdfPageRotateAngle.rotateAngle90;
    if (normalized == 180) return PdfPageRotateAngle.rotateAngle180;
    if (normalized == 270) return PdfPageRotateAngle.rotateAngle270;
    return PdfPageRotateAngle.rotateAngle0;
  }
}
