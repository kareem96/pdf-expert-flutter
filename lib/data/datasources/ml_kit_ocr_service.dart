import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';

class MlKitOcrService {
  TextRecognizer? _textRecognizer;

  TextRecognizer _getRecognizer() {
    _textRecognizer ??= TextRecognizer(script: TextRecognitionScript.latin);
    return _textRecognizer!;
  }

  /// Rasterizes a specific PDF page to an image, then runs OCR to find the word bounds
  /// at the given [tapX, tapY] coordinates in PDF points.
  Future<Rect?> extractWordBoundsFromImage(
    String pdfPath, 
    int pageIndex, 
    double tapX, 
    double tapY, {
    double pdfPageWidth = 595.0,
    double pdfPageHeight = 842.0,
    double pad = 10.0,
  }) async {
    try {
      if (kDebugMode) {
        print('MlKitOcrService: Starting OCR on page $pageIndex for tap ($tapX, $tapY)');
      }
      
      final File pdfFile = File(pdfPath);
      if (!await pdfFile.exists()) return null;

      // 1. Convert the specific PDF page to an Image (Rasterize)
      // Memory optimization: Use Uint8List only within this scope
      Uint8List? pdfBytes = await pdfFile.readAsBytes();
      
      const double scaleDpi = 144.0;
      final double exportScale = scaleDpi / 72.0;

      final pageImageBytesList = await Printing.raster(
        pdfBytes!, 
        pages: [pageIndex], 
        dpi: scaleDpi,
      ).toList();

      // Clear bytes immediately to free memory before OCR processing
      pdfBytes = null; 

      if (pageImageBytesList.isEmpty) return null;

      final rasterImage = pageImageBytesList.first;
      
      // 2. Save the rasterized image temporarily for ML Kit to read
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/ocr_temp_${DateTime.now().millisecondsSinceEpoch}.png');
      
      final Uint8List pngBytes = await rasterImage.toPng();
      await tempFile.writeAsBytes(pngBytes);

      // 3. Process with ML Kit
      final InputImage inputImage = InputImage.fromFilePath(tempFile.path);
      final RecognizedText recognizedText = await _getRecognizer().processImage(inputImage);
      
      // Clean up the temp image immediately
      if (await tempFile.exists()) {
        await tempFile.delete().catchError((_) => tempFile);
      }

      // 4. Calculate hit detection
      // Note: The coordinates we receive from PDF Viewer (tapX, tapY) are in PDF Points (72 DPI).
      // The coordinates returned by ML Kit are in Image Pixels (144 DPI in this case).
      // We must scale the tap coordinates to Image Pixels to match ML Kit's coordinate space.
      final double scaledTapX = tapX * exportScale;
      final double scaledTapY = tapY * exportScale;
      final double scaledPad = pad * exportScale;
      
      final Rect touchHitbox = Rect.fromLTWH(
        scaledTapX - scaledPad, 
        scaledTapY - scaledPad, 
        scaledPad * 2, 
        scaledPad * 2,
      );

      Rect? closestWordRect;
      double minDistance = double.infinity;

      if (kDebugMode) {
        print('MlKitOcrService: Extracted ${recognizedText.blocks.length} blocks of text');
      }

      for (TextBlock block in recognizedText.blocks) {
        for (TextLine line in block.lines) {
          for (TextElement word in line.elements) {
            // ML Kit provides word.boundingBox in Image Pixel coordinates
            final Rect wordBounds = word.boundingBox;

            if (wordBounds.overlaps(touchHitbox)) {
              final Offset wordCenter = Offset(
                wordBounds.left + (wordBounds.width / 2),
                wordBounds.top + (wordBounds.height / 2),
              );
              final Offset tapPoint = Offset(scaledTapX, scaledTapY);
              final double distance = (wordCenter - tapPoint).distance;

              if (distance < minDistance) {
                minDistance = distance;
                closestWordRect = wordBounds;
              }
            }
          }
        }
      }

      // 5. If we found a match, convert it BACK to PDF Points (72 DPI)
      if (closestWordRect != null) {
        final Rect finalPdfRect = Rect.fromLTRB(
          closestWordRect.left / exportScale,
          closestWordRect.top / exportScale,
          closestWordRect.right / exportScale,
          closestWordRect.bottom / exportScale,
        );
        
        if (kDebugMode) {
          print('MlKitOcrService: Success! Found word at $finalPdfRect');
        }
        
        // Inflate slightly to make the eraser box look better
        return finalPdfRect.inflate(1.0);
      }

      return null;
    } catch (e, st) {
      if (kDebugMode) {
        print('MlKitOcrService ERROR: $e\n$st');
      }
      return null;
    }
  }

  void dispose() {
    _textRecognizer?.close();
  }
}
