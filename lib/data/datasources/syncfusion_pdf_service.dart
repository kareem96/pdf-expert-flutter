import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:path_provider/path_provider.dart';
import '../../domain/entities/pdf_document_entity.dart';
import '../../domain/entities/pdf_field_entity.dart';

class SyncfusionPdfService {
  Future<PdfDocumentEntity> parsePdf(String path) async {
    print('PdfService: Attempting to parse PDF at: $path');
    final Uint8List bytes = await File(path).readAsBytes();
    
    // We only create PdfDocument to extract form fields and page metadata.
    // If it fails (e.g., encrypted or corrupted), we fallback gracefully
    // to default dimensions so at least the viewer can try to render it.
    final List<PdfFieldEntity> fields = [];
    final List<double> pageOffsets = [];
    double pageWidth = 595.0; // Default A4
    double pageHeight = 842.0;

    try {
      final PdfDocument document = PdfDocument(inputBytes: bytes);
      print('PdfService: Document loaded. Page count: ${document.pages.count}');
      
      double currentOffset = 0;
      const double pageSpacing = 0.0; // matching UI SfPdfViewer spacing

      // Extract real page dimensions safely
      final List<double> pageWidths = [];
      final List<double> pageHeights = [];
      if (document.pages.count > 0) {
        final firstPage = document.pages[0];
        print('PdfService: First page size: ${firstPage.size.width} x ${firstPage.size.height}');
        pageWidth = firstPage.size.width;
        pageHeight = firstPage.size.height;
        
        for (int i = 0; i < document.pages.count; i++) {
            pageWidths.add(document.pages[i].size.width);
            pageHeights.add(document.pages[i].size.height);
            pageOffsets.add(currentOffset);
            currentOffset += document.pages[i].size.height + pageSpacing;
        }
      }

      // Parse AcroForms
      final PdfForm form = document.form;
      if (form != null) {
        print('PdfService: Form found. Field count: ${form.fields.count}');
        if (form.fields != null) {
          for (int i = 0; i < form.fields.count; i++) {
            final PdfField field = form.fields[i];
            final PdfFieldType type = _mapFieldType(field);
            
            fields.add(PdfFieldEntity(
              id: 'field_${DateTime.now().microsecondsSinceEpoch}_$i',
              name: field.name ?? 'field',
              type: type,
              value: _getFieldValue(field),
              x: field.bounds.left,
              y: field.bounds.top,
              width: field.bounds.width,
              height: field.bounds.height,
              pageIndex: _getFieldIndex(document, field),
              originalIndex: i, // SIMPAN INDEX ASLI
            ));
          }
        }
      }

      // THE CRITICAL FIX: If fields are too many, flatten the document for viewing!
      // This prevents the viewer from crashing while trying to render hundreds of interactive objects.
      String viewPath = path;
      if (fields.length > 50) {
        print('PdfService: High field count (${fields.length}). Flattening document for stable viewing...');
        document.form.flattenAllFields();
        final tempDir = await getTemporaryDirectory();
        final String fileName = path.split('/').last;
        final String cacheName = 'view_${DateTime.now().millisecondsSinceEpoch}_$fileName';
        final File cacheFile = File('${tempDir.path}/$cacheName');
        await cacheFile.writeAsBytes(document.saveSync());
        viewPath = cacheFile.path;
        print('PdfService: Flattened view saved to: $viewPath');
      }
      
      document.dispose();
      
      return PdfDocumentEntity(
        filePath: viewPath, // We return the viewable path (flattened if necessary)
        originalPath: path, // Always keep original for draft identification
        fileName: path.split('/').last,
        fields: fields,
        pageWidth: pageWidth,
        pageHeight: pageHeight,
        pageWidths: pageWidths,
        pageHeights: pageHeights,
        pageOffsets: pageOffsets,
      );
    } catch (e, stack) {
      print('PdfService ERROR: Failed to parse PDF: $e\n$stack');
    }
    
    // Final fallback (reaches here if try block fails or completes without earlier return)
    return PdfDocumentEntity(
      filePath: path,
      originalPath: path,
      fileName: path.split('/').last,
      fields: fields,
      pageWidth: pageWidth,
      pageHeight: pageHeight,
      pageOffsets: pageOffsets,
    );
  }

  PdfFieldType _mapFieldType(PdfField field) {
    if (field is PdfTextBoxField) return PdfFieldType.text;
    if (field is PdfCheckBoxField) return PdfFieldType.checkBox;
    if (field is PdfSignatureField) return PdfFieldType.signature;
    return PdfFieldType.unknown;
  }

  String? _getFieldValue(PdfField field) {
    if (field is PdfTextBoxField) return field.text;
    if (field is PdfCheckBoxField) return field.isChecked ? 'true' : 'false';
    return null;
  }

  Future<File> saveModifiedPdf({
    required PdfDocumentEntity documentEntity,
    required String targetPath,
  }) async {
    print('PdfService: Starting save process for ${documentEntity.fileName}');
    print('PdfService: Target path: $targetPath');
    
    final Uint8List originalBytes = await File(documentEntity.originalPath).readAsBytes();
    final PdfDocument document = PdfDocument(inputBytes: originalBytes);
    
    // TAHAP 1: Isi Form Field bawaan (jika ada)
    final PdfForm form = document.form;
    if (form != null) {
      final existingFields = documentEntity.fields.where((f) => !f.isNewField).toList();
      print('PdfService: Filling ${existingFields.length} existing form fields');
      for (final fieldEntity in existingFields) {
        PdfField? field;
        
        // PRIORITAS 1: Cari berdasarkan Index Asli (Paling Aman karena PASTI UNIK)
        if (fieldEntity.originalIndex != null && fieldEntity.originalIndex! < form.fields.count) {
          field = form.fields[fieldEntity.originalIndex!];
          // Verifikasi nama (opsional, untuk keamanan ekstra)
          if (field.name != fieldEntity.name) {
            print('PdfService: Index mismatch for ${fieldEntity.name}, falling back to name search');
            field = null;
          }
        }

        // FALLBACK: Cari berdasarkan Nama (Jika index tidak tersedia atau meleset)
        if (field == null) {
          for (int i = 0; i < form.fields.count; i++) {
            if (form.fields[i].name == fieldEntity.name) {
              field = form.fields[i];
              break;
            }
          }
        }
        
        if (field != null) {
          print('PdfService: Filling field "${field.name}" at [${fieldEntity.x}, ${fieldEntity.y}]');
          try {
            field.bounds = Rect.fromLTWH(fieldEntity.x, fieldEntity.y, fieldEntity.width, fieldEntity.height);
          } catch (e) {
            print('PdfService WARNING: Could not update bounds for "${field.name}". Syncfusion error: $e');
          }
          _setFieldValue(field, fieldEntity.value);
        } else {
          print('PdfService WARNING: Could not find field "${fieldEntity.name}" to fill');
        }
      }
      // Kita Flatten di akhir agar field permanen
      document.form.flattenAllFields();
      
      try {
        // Syncfusion API by default refuses to flatten cryptographic/Signature fields, 
        // leaving them as interactive Widget annotations that brutally render on top of 
        // all page graphics (hiding our manually drawn new images/signatures on export).
        // Therefore, we must explicitly scrub & purge any unflattened fields left behind.
        for (int i = document.form.fields.count - 1; i >= 0; i--) {
          document.form.fields.removeAt(i);
        }
      } catch (e) {
        print('PdfService WARNING: Failed to purge remaining unflattened fields: $e');
      }
    }
    
    // TAHAP 2: Gambar Overlay (New Fields: Text, Image, Signature)
    final newFields = documentEntity.fields.where((f) => f.isNewField).toList();
    print('PdfService: Drawing ${newFields.length} new overlay fields');
    
    for (final fieldEntity in newFields) {
      final int pageIdx = fieldEntity.pageIndex;
      if (pageIdx < document.pages.count) {
        final PdfPage page = document.pages[pageIdx];
        print('PdfService: Drawing ${fieldEntity.type} "${fieldEntity.name}" on page $pageIdx at [${fieldEntity.x}, ${fieldEntity.y}]');
        
        try {
          if (fieldEntity.type == PdfFieldType.image || fieldEntity.type == PdfFieldType.signature) {
            final String? path = fieldEntity.value;
            if (path == null || path.isEmpty) {
              print('PdfService WARNING: Null/empty path for ${fieldEntity.type}');
              continue;
            }
            
            final File imgFile = File(path);
            if (await imgFile.exists()) {
              final Uint8List imgBytes = await imgFile.readAsBytes();
              print('PdfService: Image loaded (${imgBytes.length} bytes)');
              final PdfBitmap image = PdfBitmap(imgBytes);
              
              page.graphics.drawImage(
                image,
                Rect.fromLTWH(
                  fieldEntity.x, 
                  fieldEntity.y, 
                  fieldEntity.width,
                  fieldEntity.height,
                ),
              );
              print('PdfService: Successfully drew image/signature');
            } else {
              print('PdfService ERROR: File NOT found at $path');
            }
          } else if (fieldEntity.type == PdfFieldType.text) {
             // STYLE FONT
            List<PdfFontStyle> fontStyles = [];
            if (fieldEntity.isBold) fontStyles.add(PdfFontStyle.bold);
            if (fieldEntity.isItalic) fontStyles.add(PdfFontStyle.italic);
            if (fontStyles.isEmpty) fontStyles.add(PdfFontStyle.regular);

            int colorInt = int.parse(fieldEntity.textColor);
            Color flutterColor = Color(colorInt);
            PdfColor pdfColor = PdfColor(
              (flutterColor.r * 255.0).round().clamp(0, 255),
              (flutterColor.g * 255.0).round().clamp(0, 255),
              (flutterColor.b * 255.0).round().clamp(0, 255),
            );

            page.graphics.drawString(
              fieldEntity.value ?? '',
              PdfStandardFont(
                _mapPdfFontFamily(fieldEntity.fontFamily), 
                fieldEntity.fontSize,
                multiStyle: fontStyles,
              ),
              brush: PdfSolidBrush(pdfColor),
              bounds: Rect.fromLTWH(
                fieldEntity.x, 
                fieldEntity.y, 
                10000, // Ukuran tak berhingga agar text TIDAK wrap
                10000,
              ),
              format: PdfStringFormat(
                wordWrap: PdfWordWrapType.none, // Paksa agar teks memanjang ke samping (tidak turun ke bawah)
              ),
            );
            print('PdfService: Successfully drew text (no-wrap) at [${fieldEntity.x}, ${fieldEntity.y}]');
          } else if (fieldEntity.type == PdfFieldType.eraser) {
            final String bgColorHex = fieldEntity.backgroundColor ?? '0xFFFFFFFF';
            final Color flutterColor = Color(int.parse(bgColorHex));
            final PdfColor pdfColor = PdfColor(
              (flutterColor.r * 255.0).round().clamp(0, 255),
              (flutterColor.g * 255.0).round().clamp(0, 255),
              (flutterColor.b * 255.0).round().clamp(0, 255),
            );

            page.graphics.drawRectangle(
              brush: PdfSolidBrush(pdfColor),
              bounds: Rect.fromLTWH(
                fieldEntity.x, 
                fieldEntity.y, 
                fieldEntity.width, 
                fieldEntity.height,
              ),
            );
            print('PdfService: Successfully drew Eraser box at [${fieldEntity.x}, ${fieldEntity.y}]');
          } else if (fieldEntity.type == PdfFieldType.marker) {
            final String type = fieldEntity.value ?? 'check';
            
            // Extract color
            final Color flutterColor = Color(int.parse(fieldEntity.textColor));
            final PdfColor pdfColor = PdfColor(
              (flutterColor.r * 255.0).round().clamp(0, 255),
              (flutterColor.g * 255.0).round().clamp(0, 255),
              (flutterColor.b * 255.0).round().clamp(0, 255),
            );
            
            final PdfBrush brush = PdfSolidBrush(pdfColor);
            final Rect rect = Rect.fromLTWH(
              fieldEntity.x, 
              fieldEntity.y, 
              fieldEntity.width, 
              fieldEntity.height,
            );

            if (type == 'square') {
              page.graphics.drawRectangle(brush: brush, bounds: rect);
            } else if (type == 'circle') {
              page.graphics.drawEllipse(rect, brush: brush); 
            } else if (type == 'check') {
              final PdfPen pen = PdfPen(pdfColor, width: rect.width * 0.15);
              page.graphics.drawLine(
                pen, 
                Offset(rect.left + rect.width * 0.2, rect.top + rect.height * 0.5), 
                Offset(rect.left + rect.width * 0.45, rect.top + rect.height * 0.8)
              );
              page.graphics.drawLine(
                pen, 
                Offset(rect.left + rect.width * 0.45, rect.top + rect.height * 0.8), 
                Offset(rect.left + rect.width * 0.85, rect.top + rect.height * 0.25)
              );
            } else if (type == 'close') {
              final PdfPen pen = PdfPen(pdfColor, width: rect.width * 0.15);
              page.graphics.drawLine(
                pen, 
                Offset(rect.left + rect.width * 0.25, rect.top + rect.height * 0.25), 
                Offset(rect.left + rect.width * 0.75, rect.top + rect.height * 0.75)
              );
              page.graphics.drawLine(
                pen, 
                Offset(rect.left + rect.width * 0.75, rect.top + rect.height * 0.25), 
                Offset(rect.left + rect.width * 0.25, rect.top + rect.height * 0.75)
              );
            }
            print('PdfService: Successfully drew marker ($type) at [${fieldEntity.x}, ${fieldEntity.y}]');
          }
        } catch (e, st) {
          print('PdfService ERROR drawing field ${fieldEntity.name}: $e\n$st');
        }
      } else {
        print('PdfService ERROR: Invalid page index $pageIdx (Total pages: ${document.pages.count})');
      }
    }
    
    final List<int> savedBytes = await document.save();
    document.dispose();
    
    final File savedFile = File(targetPath);
    await savedFile.writeAsBytes(savedBytes);
    print('PdfService: Save process completed at ${savedFile.path}');
    return savedFile;
  }

  void _setFieldValue(PdfField field, String? value) {
    if (field is PdfTextBoxField) {
      field.text = value ?? '';
    } else if (field is PdfCheckBoxField) {
      field.isChecked = value == 'true';
    }
  }

  PdfFontFamily _mapPdfFontFamily(String fontFamily) {
    switch (fontFamily) {
      // Merriweather = serif → closest is TimesRoman
      case 'Merriweather':   return PdfFontFamily.timesRoman;
      // Courier Prime / monospace → Courier
      case 'Courier Prime':  return PdfFontFamily.courier;
      // Roboto ≈ Helvetica (both sans-serif)
      case 'Roboto':         return PdfFontFamily.helvetica;
      // Playfair Display = display serif → TimesRoman is closest
      case 'Playfair Display': return PdfFontFamily.timesRoman;
      // Dancing Script = script → ZapfDingbats not ideal but no real script in PDF standard
      case 'Dancing Script': return PdfFontFamily.timesRoman;
      case 'Helvetica':
      default:               return PdfFontFamily.helvetica;
    }
  }

  // Helper to find which page a form field belongs to
  int _getFieldIndex(PdfDocument doc, PdfField field) {
    try {
      // PdfField in Syncfusion usually has a 'page' property
      final dynamic dynamicField = field;
      final page = dynamicField.page;
      if (page != null) {
        return doc.pages.indexOf(page);
      }
    } catch (e) {
      print('PdfService: Could not determine page index for field ${field.name}');
    }
    return 0;
  }

  /// Extracts the word bounding box at the tapped coordinates (x, y) 
  Future<Rect?> extractWordBoundsAt(String filePath, int pageIndex, double x, double y, {double pad = 6.0}) async {
    try {
      final Uint8List bytes = await File(filePath).readAsBytes();
      final PdfDocument document = PdfDocument(inputBytes: bytes);
      
      final PdfTextExtractor extractor = PdfTextExtractor(document);
      final List<TextLine> lines = extractor.extractTextLines(startPageIndex: pageIndex, endPageIndex: pageIndex);
      
      // Deteksi toleransi sentuhan (Hitbox pad) dinamik mengikuti rasio zoom.
      final Rect touchHitbox = Rect.fromLTWH(x - pad, y - pad, pad * 2, pad * 2);
      final Offset tapPoint = Offset(x, y);

      TextWord? closestWord;
      double minDistance = double.infinity;

      for (TextLine line in lines) {
        for (TextWord word in line.wordCollection) {
          if (word.bounds.overlaps(touchHitbox)) {
            // Calculate distance to tap point to find the single most relevant word
            final Offset wordCenter = Offset(
              word.bounds.left + (word.bounds.width / 2),
              word.bounds.top + (word.bounds.height / 2),
            );
            final double distance = (wordCenter - tapPoint).distance;

            if (distance < minDistance) {
              minDistance = distance;
              closestWord = word;
            }
          }
        }
      }
      
      document.dispose();

      if (closestWord != null) {
        // Expand kotaknya sedikit saja agar 'tighter' dan tidak menimpa garis field di sekitarnya
        return closestWord.bounds.inflate(0.5);
      }
      
      return null;
    } catch (e) {
      print('PdfService ERROR: extractWordBoundsAt failed: $e');
      return null;
    }
  }
}
