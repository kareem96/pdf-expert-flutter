import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:path_provider/path_provider.dart';
import '../../domain/entities/pdf_document_entity.dart';
import '../../domain/entities/pdf_field_entity.dart';

class SyncfusionPdfService {
  Future<PdfDocumentEntity> parsePdf(String path) async {
    final Uint8List bytes = await File(path).readAsBytes();
    final List<PdfFieldEntity> fields = [];
    final List<double> pageOffsets = [];
    double pageWidth = 595.0; // Default A4
    double pageHeight = 842.0;

    try {
      final PdfDocument document = PdfDocument(inputBytes: bytes);
      double currentOffset = 0;
      const double pageSpacing = 0.0;

      final List<double> pageWidths = [];
      final List<double> pageHeights = [];
      
      if (document.pages.count > 0) {
        for (int i = 0; i < document.pages.count; i++) {
          final page = document.pages[i];
          final int rotation = _mapPdfRotation(page.rotation);
          final bool isLandscape = rotation == 90 || rotation == 270;
          
          final double pw = isLandscape ? page.size.height : page.size.width;
          final double ph = isLandscape ? page.size.width : page.size.height;

          if (i == 0) {
            pageWidth = pw;
            pageHeight = ph;
          }

          pageWidths.add(pw);
          pageHeights.add(ph);
          pageOffsets.add(currentOffset);
          currentOffset += ph + pageSpacing;
        }
      }

      final PdfForm form = document.form;
      for (int i = 0; i < form.fields.count; i++) {
        final field = form.fields[i];
        fields.add(PdfFieldEntity(
          id: 'field_${DateTime.now().microsecondsSinceEpoch}_$i',
          name: field.name ?? 'field',
          type: _mapFieldType(field),
          value: _getFieldValue(field),
          x: field.bounds.left,
          y: field.bounds.top,
          width: field.bounds.width,
          height: field.bounds.height,
          pageIndex: _getFieldIndex(document, field),
          originalIndex: i,
        ));
      }

      String viewPath = path;
      if (fields.length > 50) {
        document.form.flattenAllFields();
        final tempDir = await getTemporaryDirectory();
        final String fileName = path.split('/').last;
        final String cacheName = 'view_${DateTime.now().millisecondsSinceEpoch}_$fileName';
        final File cacheFile = File('${tempDir.path}/$cacheName');
        await cacheFile.writeAsBytes(document.saveSync());
        viewPath = cacheFile.path;
      }
      
      document.dispose();
      
      return PdfDocumentEntity(
        filePath: viewPath,
        originalPath: path,
        fileName: path.split('/').last,
        fields: fields,
        pageWidth: pageWidth,
        pageHeight: pageHeight,
        pageWidths: pageWidths,
        pageHeights: pageHeights,
        pageOffsets: pageOffsets,
      );
    } catch (_) {}
    
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
    final Uint8List originalBytes = await File(documentEntity.originalPath).readAsBytes();
    final PdfDocument document = PdfDocument(inputBytes: originalBytes);
    
    final PdfForm form = document.form;
    final existingFields = documentEntity.fields.where((f) => !f.isNewField).toList();
    for (final fieldEntity in existingFields) {
      PdfField? field;
      if (fieldEntity.originalIndex != null && fieldEntity.originalIndex! < form.fields.count) {
        field = form.fields[fieldEntity.originalIndex!];
        if (field.name != fieldEntity.name) field = null;
      }

      if (field == null) {
        for (int i = 0; i < form.fields.count; i++) {
          if (form.fields[i].name == fieldEntity.name) {
            field = form.fields[i];
            break;
          }
        }
      }
      
      if (field != null) {
        try {
          field.bounds = Rect.fromLTWH(fieldEntity.x, fieldEntity.y, fieldEntity.width, fieldEntity.height);
        } catch (_) {}
        _setFieldValue(field, fieldEntity.value);
      }
    }
    
    document.form.flattenAllFields();
    
    try {
      for (int i = document.form.fields.count - 1; i >= 0; i--) {
        document.form.fields.removeAt(i);
      }
    } catch (e) {
      // Log the error if necessary
      // print('Error removing form fields: $e');
    }
    
    final newFields = documentEntity.fields.where((f) => f.isNewField).toList();
    for (final fieldEntity in newFields) {
      final int pageIdx = fieldEntity.pageIndex;
      if (pageIdx < document.pages.count) {
        final PdfPage page = document.pages[pageIdx];
        
        final PdfGraphics graphics = page.graphics;
        graphics.save();
        
        final int rotation = _mapPdfRotation(page.rotation);
        if (rotation == 90) {
          graphics.translateTransform(0, page.size.height);
          graphics.rotateTransform(-90);
        } else if (rotation == 180) {
          graphics.translateTransform(page.size.width, page.size.height);
          graphics.rotateTransform(-180);
        } else if (rotation == 270) {
          graphics.translateTransform(page.size.width, 0);
          graphics.rotateTransform(-270);
        }

        try {
          if (fieldEntity.type == PdfFieldType.image || fieldEntity.type == PdfFieldType.signature) {
            final String? path = fieldEntity.value;
            if (path != null && path.isNotEmpty) {
              final File imgFile = File(path);
              if (await imgFile.exists()) {
                final Uint8List imgBytes = await imgFile.readAsBytes();
                final PdfBitmap image = PdfBitmap(imgBytes);
                graphics.drawImage(
                  image,
                  Rect.fromLTWH(fieldEntity.x, fieldEntity.y, fieldEntity.width, fieldEntity.height),
                );
              }
            }
          } else if (fieldEntity.type == PdfFieldType.text) {
            final List<PdfFontStyle> fontStyles = [];
            if (fieldEntity.isBold) fontStyles.add(PdfFontStyle.bold);
            if (fieldEntity.isItalic) fontStyles.add(PdfFontStyle.italic);
            if (fontStyles.isEmpty) fontStyles.add(PdfFontStyle.regular);

            final Color flutterColor = Color(int.parse(fieldEntity.textColor));
            final PdfColor pdfColor = PdfColor(
              (flutterColor.r * 255.0).round().clamp(0, 255),
              (flutterColor.g * 255.0).round().clamp(0, 255),
              (flutterColor.b * 255.0).round().clamp(0, 255),
            );

            graphics.drawString(
              fieldEntity.value ?? '',
              PdfStandardFont(
                _mapPdfFontFamily(fieldEntity.fontFamily), 
                fieldEntity.fontSize,
                multiStyle: fontStyles,
              ),
              brush: PdfSolidBrush(pdfColor),
              bounds: Rect.fromLTWH(fieldEntity.x, fieldEntity.y, 10000, 10000),
              format: PdfStringFormat(wordWrap: PdfWordWrapType.none),
            );
          } else if (fieldEntity.type == PdfFieldType.eraser) {
            final Color flutterColor = Color(int.parse(fieldEntity.backgroundColor ?? '0xFFFFFFFF'));
            final PdfColor pdfColor = PdfColor(
              (flutterColor.r * 255.0).round().clamp(0, 255),
              (flutterColor.g * 255.0).round().clamp(0, 255),
              (flutterColor.b * 255.0).round().clamp(0, 255),
            );

            graphics.drawRectangle(
              brush: PdfSolidBrush(pdfColor),
              bounds: Rect.fromLTWH(fieldEntity.x, fieldEntity.y, fieldEntity.width, fieldEntity.height),
            );
          } else if (fieldEntity.type == PdfFieldType.marker) {
            final String type = fieldEntity.value ?? 'check';
            final Color flutterColor = Color(int.parse(fieldEntity.textColor));
            final PdfColor pdfColor = PdfColor(
              (flutterColor.r * 255.0).round().clamp(0, 255),
              (flutterColor.g * 255.0).round().clamp(0, 255),
              (flutterColor.b * 255.0).round().clamp(0, 255),
            );
            
            final PdfBrush brush = PdfSolidBrush(pdfColor);
            final Rect rect = Rect.fromLTWH(fieldEntity.x, fieldEntity.y, fieldEntity.width, fieldEntity.height);

            if (type == 'square') {
              graphics.drawRectangle(brush: brush, bounds: rect);
            } else if (type == 'circle') {
              graphics.drawEllipse(rect, brush: brush); 
            } else if (type == 'check') {
              final PdfPen pen = PdfPen(pdfColor, width: rect.width * 0.15);
              graphics.drawLine(pen, Offset(rect.left + rect.width * 0.2, rect.top + rect.height * 0.5), Offset(rect.left + rect.width * 0.45, rect.top + rect.height * 0.8));
              graphics.drawLine(pen, Offset(rect.left + rect.width * 0.45, rect.top + rect.height * 0.8), Offset(rect.left + rect.width * 0.85, rect.top + rect.height * 0.25));
            } else if (type == 'close') {
              final PdfPen pen = PdfPen(pdfColor, width: rect.width * 0.15);
              graphics.drawLine(pen, Offset(rect.left + rect.width * 0.25, rect.top + rect.height * 0.25), Offset(rect.left + rect.width * 0.75, rect.top + rect.height * 0.75));
              graphics.drawLine(pen, Offset(rect.left + rect.width * 0.75, rect.top + rect.height * 0.25), Offset(rect.left + rect.width * 0.25, rect.top + rect.height * 0.75));
            }
          }
        } catch (_) {
        } finally {
          graphics.restore();
        }
      }
    }
    
    final List<int> savedBytes = await document.save();
    document.dispose();
    
    final File savedFile = File(targetPath);
    await savedFile.writeAsBytes(savedBytes);
    return savedFile;
  }

  int _mapPdfRotation(PdfPageRotateAngle angle) {
    switch (angle) {
      case PdfPageRotateAngle.rotateAngle90: return 90;
      case PdfPageRotateAngle.rotateAngle180: return 180;
      case PdfPageRotateAngle.rotateAngle270: return 270;
      case PdfPageRotateAngle.rotateAngle0: return 0;
    }
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
      case 'Merriweather':   return PdfFontFamily.timesRoman;
      case 'Courier Prime':  return PdfFontFamily.courier;
      case 'Roboto':         return PdfFontFamily.helvetica;
      case 'Playfair Display': return PdfFontFamily.timesRoman;
      case 'Dancing Script': return PdfFontFamily.timesRoman;
      default:               return PdfFontFamily.helvetica;
    }
  }

  int _getFieldIndex(PdfDocument doc, PdfField field) {
    try {
      final dynamic dynamicField = field;
      final page = dynamicField.page;
      if (page != null) return doc.pages.indexOf(page);
    } catch (_) {}
    return 0;
  }

  Future<Rect?> extractWordBoundsAt(String filePath, int pageIndex, double x, double y, {double pad = 6.0}) async {
    try {
      final Uint8List bytes = await File(filePath).readAsBytes();
      final PdfDocument document = PdfDocument(inputBytes: bytes);
      final PdfTextExtractor extractor = PdfTextExtractor(document);
      final List<TextLine> lines = extractor.extractTextLines(startPageIndex: pageIndex, endPageIndex: pageIndex);
      final Rect touchHitbox = Rect.fromLTWH(x - pad, y - pad, pad * 2, pad * 2);
      final Offset tapPoint = Offset(x, y);

      TextWord? closestWord;
      double minDistance = double.infinity;

      for (TextLine line in lines) {
        for (TextWord word in line.wordCollection) {
          if (word.bounds.overlaps(touchHitbox)) {
            final Offset wordCenter = Offset(word.bounds.left + (word.bounds.width / 2), word.bounds.top + (word.bounds.height / 2));
            final double distance = (wordCenter - tapPoint).distance;
            if (distance < minDistance) {
              minDistance = distance;
              closestWord = word;
            }
          }
        }
      }
      document.dispose();
      return closestWord?.bounds.inflate(0.5);
    } catch (_) {
      return null;
    }
  }
}
